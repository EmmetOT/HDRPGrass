using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Grass.Compute
{
    /// <summary>
    /// Renders grass on the surface of the given mesh, transformed into world space, according to settings defined in a grass
    /// profile and a grass material.
    /// </summary>
    [ExecuteInEditMode]
    //[RequireComponent(typeof(MeshFilter))]
    public class ProceduralGrassRenderer : MonoBehaviour
    {
        #region Constants

        private const float GENERATED_MESH_VERTEX_LIMIT = 65535;
        private const float INTERLOCKED_FLOAT_ACCURACY = 1000f;
        private const float RESULT_ROUNDING = 1000f;

        private const int MAX_GRASS_BLADES = 10000;
        private const int MAX_GRASS_BLADES_PER_SQUARE_METER = 100;

        private const string DEFAULT_BOTTOM_COLOUR_HEX = "#102912";
        private const string DEFAULT_TOP_COLOUR_HEX = "#3A9544";

        private static class Properties
        {
            public static readonly int VERTEX_BUFFER = Shader.PropertyToID("_SourcePointData");
            public static readonly int TRIANGLE_BUFFER = Shader.PropertyToID("_SourceTriangles");
            public static readonly int TRIANGLE_AREAS_BUFFER = Shader.PropertyToID("_TriangleAreas");
            public static readonly int GRASS_SPACES_BUFFER = Shader.PropertyToID("_GrassSpaces");
            public static readonly int GRASS_SPACES_APPEND_BUFFER = Shader.PropertyToID("_GrassSpaces_Append");
            public static readonly int VERTEX_COLOURS_BUFFER = Shader.PropertyToID("_VertexColours");
            public static readonly int VERTEX_COLOURS_APPEND_BUFFER = Shader.PropertyToID("_VertexColours_Append");
            public static readonly int OUT_MESH_BUFFER = Shader.PropertyToID("_OutMesh");
            public static readonly int INDIRECT_ARGS_BUFFER = Shader.PropertyToID("_IndirectArgs");
            public static readonly int NUM_OUTPUT_POINTS_BUFFER = Shader.PropertyToID("_NumOutputPoints");

            public static readonly int GRASS_BLADES_PER_SQUARE_METER = Shader.PropertyToID("_GrassBladesPerSquareMeter");
            public static readonly int NUM_SOURCE_TRIANGLES = Shader.PropertyToID("_NumSourceTriangles");
            public static readonly int TOTAL_AREA = Shader.PropertyToID("_TotalAreaInt");
            public static readonly int GRASS_BLADE_SEGMENTS = Shader.PropertyToID("_GrassBladeSegments");
            public static readonly int CHOOSE_GRASS_POINTS_INDIRECT_ARGS_BUFFER = Shader.PropertyToID("_ChooseGrassPointsIndirectArgsBuffer");

            public static readonly int LOCAL_TO_WORLD = Shader.PropertyToID("_ObjectToWorld");
            public static readonly int WORLD_TO_LOCAL = Shader.PropertyToID("_WorldToObject");
            public static readonly int WORLD_SPACE_CAMERA_POS = Shader.PropertyToID("_WorldSpaceCameraPos");//Shader.PropertyToID("_GrassWorldSpaceCameraPos");

            public static readonly int GRASS_TOP_COLOUR = Shader.PropertyToID("_GrassTopColour");
            public static readonly int GRASS_BOTTOM_COLOUR = Shader.PropertyToID("_GrassBottomColour");

            public static readonly int GRASS_BLADE_PROPERTIES = Shader.PropertyToID("_GrassBladeProperties");
        }

        #endregion

        private struct Kernels
        {
            public const string MESH_AREA_CALCULATOR = "CalculateTotalArea";
            public const string ACCUMULATE_AREAS = "AccumulateAreas";
            public const string CHOOSE_GRASS_POINTS = "ChooseGrassPoints";
            public const string GENERATE_GRASS_BLADES = "GenerateGrassBlades";

            public int MeshAreaCalculator { get; private set; }
            public int AccumulateAreas { get; private set; }
            public int ChooseGrassPoints { get; private set; }
            public int GenerateGrassBlades { get; private set; }

            public Kernels(ComputeShader shader)
            {
                MeshAreaCalculator = shader.FindKernel(MESH_AREA_CALCULATOR);
                AccumulateAreas = shader.FindKernel(ACCUMULATE_AREAS);
                ChooseGrassPoints = shader.FindKernel(CHOOSE_GRASS_POINTS);
                GenerateGrassBlades = shader.FindKernel(GENERATE_GRASS_BLADES);
            }
        }

        private Kernels m_kernels;

        private int m_meshAreaCalculatorDispatchSize = -1;

        private int GrassTriangleCount => GrassBladeBufferSize * (m_grassBladeSegments * 2 - 1);

        [SerializeField]
        private MeshFilter m_meshFilter;

        [SerializeField]
        [HideInInspector]
        private Mesh m_mesh;

        [SerializeField]
        private ComputeShader m_grassStatic = null;

        private ComputeShader m_grassStaticInstance;

        [SerializeField]
        private Material m_grassMaterial = null;

        [SerializeField]
        [HideInInspector]
        private Material m_grassMaterialMeshes = null;

        [SerializeField]
        [Min(0)]
        private float m_grassBladesPerSquareMeter = 10f;

        [SerializeField]
        [Min(0)]
        private int m_grassBladeCount = 100;

        private int GrassBladeBufferSize => m_grassDistributionType == GrassDistributionType.CONSTANT ? m_grassBladeCount : MAX_GRASS_BLADES;

        [SerializeField]
        [Range(1, 10)]
        private int m_grassBladeSegments = 1;

        [SerializeField]
        [ColorUsage(showAlpha: false)]
        private Color m_bottomColour;

        [SerializeField]
        [ColorUsage(showAlpha: false)]
        private Color m_topColour;

        [SerializeField]
        private bool m_castShadows = false;

        [SerializeField]
        private GrassBladeProperties m_properties;

        private ComputeBuffer m_meshDataBuffer;
        private ComputeBuffer m_meshTrianglesBuffer;
        private ComputeBuffer m_meshTriangleAreasBuffer;
        private ComputeBuffer m_meshTotalAreaBuffer;
        private ComputeBuffer m_numOutputPointsBuffer;
        private ComputeBuffer m_grassBladeSpacesBuffer;
        private ComputeBuffer m_vertexColoursBuffer;
        private ComputeBuffer m_grassBladePropertiesBuffer;
        private ComputeBuffer m_grassBladeTrianglesBuffer;
        private ComputeBuffer m_indirectArgsBuffer;
        private ComputeBuffer m_chooseGrassPointsIndirectArgsBuffer;

        private MaterialPropertyBlock m_materialPropertyBlock;

        private bool m_staticPipelineInitialized = false;
        private bool m_dynamicPipelineInitialized = false;

        // these arrays are used to empty out the buffers, instead of allocating new ones every time
        private readonly uint[] m_resetChooseGrassPointsIndirectArgs = new uint[] { 0, 1, 1 };
        private readonly uint[] m_resetIndirectArgs = new uint[] { 0, 1, 0, 0 };
        private readonly int[] m_resetMeshTotalArea = new int[] { 0 };

        private readonly int[] m_resetNumPoints = new int[] { 0 };
        private readonly float[] m_resetVertexColours = new float[] { 0 };
        private readonly GrassBladeSpaceData[] m_resetGrassBladeSpaces = new GrassBladeSpaceData[0];
        private readonly GrassBladeVertex[] m_resetGrassBladePoints = new GrassBladeVertex[0];
        private readonly GrassBladeTriangle[] m_resetGrassBladeTriangles = new GrassBladeTriangle[0];

        [SerializeField]
        [HideInInspector]
        private Bounds m_bounds;
        private Matrix4x4 m_localToWorldMatrix;
        private Matrix4x4 m_worldToLocalMatrix;

        // this array is just used to temporarily store game cameras
        private static readonly Camera[] m_gameCameras = new Camera[20];

        private enum GrassDistributionType { CONSTANT, PER_SQUARE_METER };

        [SerializeField]
        private GrassDistributionType m_grassDistributionType = GrassDistributionType.CONSTANT;

        #region Unity Callbacks

        private void OnValidate()
        {
            m_grassBladeCount = Mathf.Clamp(m_grassBladeCount, 0, MAX_GRASS_BLADES);
            m_grassBladesPerSquareMeter = Mathf.Clamp(m_grassBladesPerSquareMeter, 0, MAX_GRASS_BLADES_PER_SQUARE_METER);

            GetBounds();

            m_resetNumPoints[0] = m_grassDistributionType == GrassDistributionType.CONSTANT ? m_grassBladeCount : -1;

            m_materialPropertyBlock = new MaterialPropertyBlock();
            m_materialPropertyBlock.SetColor(Properties.GRASS_BOTTOM_COLOUR, m_bottomColour);
            m_materialPropertyBlock.SetColor(Properties.GRASS_TOP_COLOUR, m_topColour);
            m_materialPropertyBlock.SetMatrix(Properties.LOCAL_TO_WORLD, m_localToWorldMatrix);
            //m_materialPropertyBlock.SetMatrix(Properties.WORLD_TO_LOCAL, m_worldToLocalMatrix);

            m_dynamicPipelineInitialized = false;
            m_staticPipelineInitialized = false;

            bool invalid = !enabled;
            invalid |= (m_grassDistributionType == GrassDistributionType.CONSTANT && m_grassBladeCount <= 0);
            invalid |= (m_grassBladesPerSquareMeter <= 0f && m_grassDistributionType == GrassDistributionType.PER_SQUARE_METER);

            if (!invalid)
            {
                InitializeStaticPipeline();
                RunStaticPipeline();
            }
        }

        private void Reset()
        {
            m_meshFilter = GetComponent<MeshFilter>();
            m_mesh = m_meshFilter.sharedMesh;
            m_properties = GrassBladeProperties.GetDefault();

            if (ColorUtility.TryParseHtmlString(DEFAULT_BOTTOM_COLOUR_HEX, out Color bottom))
                m_bottomColour = bottom;

            if (ColorUtility.TryParseHtmlString(DEFAULT_TOP_COLOUR_HEX, out Color top))
                m_topColour = top;

            OnDisable();
            OnEnable();
        }

        private void OnDisable()
        {
            ReleaseBuffers();

            if (m_grassStaticInstance != null)
            {
                DestroyImmediate(m_grassStaticInstance);
                m_grassStaticInstance = null;
            }
        }

        private void OnDestroy()
        {
            ReleaseBuffers();
        }

        private void OnEnable()
        {
            transform.hasChanged = true;

            m_meshFilter = GetComponent<MeshFilter>();
            m_mesh = m_meshFilter.sharedMesh;

            InitializeStaticPipeline();
            RunStaticPipeline();
        }

        private void Awake()
        {
            m_meshFilter = GetComponent<MeshFilter>();
            m_mesh = m_meshFilter.sharedMesh;

            GetBounds();

            m_localToWorldMatrix = transform.localToWorldMatrix;
            m_worldToLocalMatrix = transform.worldToLocalMatrix;
            transform.hasChanged = false;
        }

        private void LateUpdate()
        {
            if (!enabled)
                return;

            if (transform.hasChanged)
            {
                m_localToWorldMatrix = transform.localToWorldMatrix;
                m_worldToLocalMatrix = transform.worldToLocalMatrix;

                m_materialPropertyBlock.SetMatrix(Properties.LOCAL_TO_WORLD, m_localToWorldMatrix);
                //m_materialPropertyBlock.SetMatrix(Properties.WORLD_TO_LOCAL, m_worldToLocalMatrix);

                transform.hasChanged = false;
            }

            if (!m_staticPipelineInitialized)
                return;

            RunDynamicPipeline();
        }

        #endregion

        /// <summary>
        /// Releases all buffers associated with the static, non run-time parts of the grass pipeline.//
        /// </summary>
        private void ReleaseBuffers()
        {
            m_staticPipelineInitialized = false;
            m_dynamicPipelineInitialized = false;

            void RemoveBuffer(ComputeBuffer buffer)
            {
                if (buffer == null)
                    return;

                buffer.Release();
                buffer = null;
            }

            RemoveBuffer(m_meshDataBuffer);
            RemoveBuffer(m_meshTrianglesBuffer);
            RemoveBuffer(m_meshTriangleAreasBuffer);
            RemoveBuffer(m_meshTotalAreaBuffer);
            RemoveBuffer(m_numOutputPointsBuffer);
            RemoveBuffer(m_grassBladePropertiesBuffer);
            RemoveBuffer(m_grassBladeSpacesBuffer);
            RemoveBuffer(m_vertexColoursBuffer);
            RemoveBuffer(m_grassBladeTrianglesBuffer);
            // RemoveBuffer(m_indirectArgsBuffer);  // releasing this here can crash the editor lol
            RemoveBuffer(m_chooseGrassPointsIndirectArgsBuffer);
        }

        /// <summary>
        /// This function prepares the in/out data for all buffers associated with the static, non runtime parts of the grass pipeline.
        /// 
        /// Can optionally not send the information to be rendered.
        /// </summary>
        private void InitializeStaticPipeline(bool sendToDynamic = true)
        {
            ReleaseBuffers();

            if (GrassBladeBufferSize <= 0)
                return;

            if (m_mesh == null)
            {
                Debug.LogError("Shared mesh is null!", this);
                return;
            }

            // todo: cache this stuff
            int[] triangles = m_mesh.GetTriangles(0);
            SourceMeshVertexData[] data = PackData(m_mesh.vertices, m_mesh.normals, m_mesh.tangents, m_mesh.colors, m_mesh.uv);

            int numTriangles = triangles.Length / 3;

            if (m_grassStaticInstance == null)
                m_grassStaticInstance = Instantiate(m_grassStatic);

            // create a new kernel struct, which automatically gets the kernel indices we need
            m_kernels = new Kernels(m_grassStaticInstance);

            // initialize compute buffers
            m_meshDataBuffer = new ComputeBuffer(data.Length, SourceMeshVertexData.Stride);
            m_meshTrianglesBuffer = new ComputeBuffer(triangles.Length, sizeof(int));
            m_meshTriangleAreasBuffer = new ComputeBuffer(numTriangles, sizeof(float));
            m_meshTotalAreaBuffer = new ComputeBuffer(1, sizeof(int));
            m_grassBladeSpacesBuffer = new ComputeBuffer(GrassBladeBufferSize, GrassBladeSpaceData.Stride, ComputeBufferType.Append);
            m_vertexColoursBuffer = new ComputeBuffer(GrassBladeBufferSize, sizeof(float), ComputeBufferType.Append);   // i say colour, but it's just the r channel
            m_grassBladePropertiesBuffer = new ComputeBuffer(1, GrassBladeProperties.Stride);
            m_numOutputPointsBuffer = new ComputeBuffer(1, sizeof(int));
            m_grassBladeTrianglesBuffer = new ComputeBuffer(GrassTriangleCount, GrassBladeTriangle.Stride, ComputeBufferType.Append);
            m_indirectArgsBuffer = new ComputeBuffer(4, sizeof(uint), ComputeBufferType.IndirectArguments);
            m_chooseGrassPointsIndirectArgsBuffer = new ComputeBuffer(3, sizeof(uint), ComputeBufferType.IndirectArguments);

            // resetting append buffers
            m_grassBladeSpacesBuffer.SetCounterValue(0);
            m_grassBladeTrianglesBuffer.SetCounterValue(0);
            m_vertexColoursBuffer.SetCounterValue(0);

            // filling buffers
            m_meshDataBuffer.SetData(data);
            m_meshTrianglesBuffer.SetData(triangles);
            m_meshTriangleAreasBuffer.SetData(new float[numTriangles]);
            m_meshTotalAreaBuffer.SetData(m_resetMeshTotalArea);
            m_grassBladeSpacesBuffer.SetData(m_resetGrassBladeSpaces);
            m_vertexColoursBuffer.SetData(m_resetVertexColours);
            m_grassBladePropertiesBuffer.SetData(new GrassBladeProperties[] { m_properties });
            m_numOutputPointsBuffer.SetData(m_resetNumPoints);
            m_grassBladeTrianglesBuffer.SetData(m_resetGrassBladeTriangles);
            m_indirectArgsBuffer.SetData(m_resetIndirectArgs);
            m_chooseGrassPointsIndirectArgsBuffer.SetData(m_resetChooseGrassPointsIndirectArgs);

            // setting buffers
            m_grassStaticInstance.SetBuffer(m_kernels.MeshAreaCalculator, Properties.VERTEX_BUFFER, m_meshDataBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.MeshAreaCalculator, Properties.TRIANGLE_BUFFER, m_meshTrianglesBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.MeshAreaCalculator, Properties.TRIANGLE_AREAS_BUFFER, m_meshTriangleAreasBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.MeshAreaCalculator, Properties.TOTAL_AREA, m_meshTotalAreaBuffer);

            m_grassStaticInstance.SetBuffer(m_kernels.AccumulateAreas, Properties.TOTAL_AREA, m_meshTotalAreaBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.AccumulateAreas, Properties.TRIANGLE_AREAS_BUFFER, m_meshTriangleAreasBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.AccumulateAreas, Properties.NUM_OUTPUT_POINTS_BUFFER, m_numOutputPointsBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.AccumulateAreas, Properties.CHOOSE_GRASS_POINTS_INDIRECT_ARGS_BUFFER, m_chooseGrassPointsIndirectArgsBuffer);

            m_grassStaticInstance.SetBuffer(m_kernels.ChooseGrassPoints, Properties.TOTAL_AREA, m_meshTotalAreaBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.ChooseGrassPoints, Properties.VERTEX_BUFFER, m_meshDataBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.ChooseGrassPoints, Properties.TRIANGLE_BUFFER, m_meshTrianglesBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.ChooseGrassPoints, Properties.TRIANGLE_AREAS_BUFFER, m_meshTriangleAreasBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.ChooseGrassPoints, Properties.GRASS_SPACES_APPEND_BUFFER, m_grassBladeSpacesBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.ChooseGrassPoints, Properties.VERTEX_COLOURS_APPEND_BUFFER, m_vertexColoursBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.ChooseGrassPoints, Properties.NUM_OUTPUT_POINTS_BUFFER, m_numOutputPointsBuffer);

            m_grassStaticInstance.SetBuffer(m_kernels.GenerateGrassBlades, Properties.GRASS_SPACES_BUFFER, m_grassBladeSpacesBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.GenerateGrassBlades, Properties.VERTEX_COLOURS_BUFFER, m_vertexColoursBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.GenerateGrassBlades, Properties.GRASS_BLADE_PROPERTIES, m_grassBladePropertiesBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.GenerateGrassBlades, Properties.OUT_MESH_BUFFER, m_grassBladeTrianglesBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.GenerateGrassBlades, Properties.INDIRECT_ARGS_BUFFER, m_indirectArgsBuffer);
            m_grassStaticInstance.SetBuffer(m_kernels.GenerateGrassBlades, Properties.NUM_OUTPUT_POINTS_BUFFER, m_numOutputPointsBuffer);

            // setting other data
            m_grassStaticInstance.SetMatrix(Properties.LOCAL_TO_WORLD, m_localToWorldMatrix);
            m_grassStaticInstance.SetMatrix(Properties.WORLD_TO_LOCAL, m_worldToLocalMatrix);
            m_grassStaticInstance.SetFloat(Properties.GRASS_BLADES_PER_SQUARE_METER, m_grassBladesPerSquareMeter);
            m_grassStaticInstance.SetInt(Properties.NUM_SOURCE_TRIANGLES, numTriangles);
            m_grassStaticInstance.SetInt(Properties.GRASS_BLADE_SEGMENTS, m_grassBladeSegments);

            // determining the dispatch sizes for the first kernel. second step is constant size, 3 and 4 are dispatched indirectly
            m_grassStaticInstance.GetKernelThreadGroupSizes(m_kernels.MeshAreaCalculator, out uint threadGroupSizeX, out _, out _);
            m_meshAreaCalculatorDispatchSize = Mathf.CeilToInt((float)numTriangles / threadGroupSizeX);

            if (sendToDynamic)
                InitializeDynamicPipeline();

            m_staticPipelineInitialized = true;
        }

        /// <summary>
        /// Set the buffers which connect the static and dynamic pipelines. (i.e., send the vertex info to the material)
        /// </summary>
        private void InitializeDynamicPipeline()
        {
            m_materialPropertyBlock.SetBuffer(Properties.OUT_MESH_BUFFER, m_grassBladeTrianglesBuffer);

            m_dynamicPipelineInitialized = true;
        }

        /// <summary>
        /// Run the static pipeline. This only needs to be run when aspects of the grass vertices need to change, such as the grass distribution or segment count.
        /// </summary>
        private void RunStaticPipeline()
        {
            DispatchAreaCalculator();
            DispatchAccumulateAreas();
            DispatchChooseGrassPoints();
            DispatchGenerateGrassBlades();
        }

        /// <summary>
        /// Run the dynamic pipeline. This draws the grass, and so needs to be called every frame.
        /// </summary>
        private void RunDynamicPipeline()
        {
            if (!enabled)
                return;

            if (!m_dynamicPipelineInitialized)
                InitializeDynamicPipeline();

            Graphics.DrawProceduralIndirect(m_grassMaterial, m_bounds, MeshTopology.Triangles, m_indirectArgsBuffer, 0,
                null, m_materialPropertyBlock, m_castShadows ? ShadowCastingMode.On : ShadowCastingMode.Off, true, gameObject.layer);
        }

        /// <summary>
        /// Runs the first step of the static pipeline, which calculates the total surface area of the input mesh, as well as storing the area of each triangle
        /// in a structured buffer.
        /// </summary>
        private void DispatchAreaCalculator()
        {
            if (!m_staticPipelineInitialized)
                InitializeStaticPipeline();

            m_grassStaticInstance.Dispatch(m_kernels.MeshAreaCalculator, m_meshAreaCalculatorDispatchSize, 1, 1);
        }

        /// <summary>
        /// Runs the second step of the static pipeline, which adds all the triangle areas with all the preceding areas and normalizes them.
        /// </summary>
        private void DispatchAccumulateAreas()
        {
            if (!m_staticPipelineInitialized)
                InitializeStaticPipeline();

            m_grassStaticInstance.Dispatch(m_kernels.AccumulateAreas, 1, 1, 1);
        }

        /// <summary>
        /// Runs the third step of the static pipeline, which finds a set number of points (object space) at which the grass will spawn.
        /// </summary>
        private void DispatchChooseGrassPoints()
        {
            if (!m_staticPipelineInitialized)
                InitializeStaticPipeline();

            m_grassStaticInstance.DispatchIndirect(m_kernels.ChooseGrassPoints, m_chooseGrassPointsIndirectArgsBuffer);
        }

        /// <summary>
        /// Runs the fourth step of the static pipeline, which generates the meshes of the grass blades.
        /// </summary>
        private void DispatchGenerateGrassBlades()
        {
            if (!m_staticPipelineInitialized)
                InitializeStaticPipeline();

            if (m_grassBladeCount <= 0)
                return;

            m_grassStaticInstance.DispatchIndirect(m_kernels.GenerateGrassBlades, m_chooseGrassPointsIndirectArgsBuffer);
        }

        #region Mesh Generation

#if UNITY_EDITOR
        [ContextMenu("Generate Mesh")]
        private void GenerateMesh()
        {
            if (GrassTriangleCount * 3 > GENERATED_MESH_VERTEX_LIMIT &&
                !EditorUtility.DisplayDialog("Oops!", $"Attempting to generate a mesh with more than {GENERATED_MESH_VERTEX_LIMIT} vertices ({GrassTriangleCount * 3}), which may produce unexpected results. Continue?", "Yup", "Nup"))
            {
                return;
            }

            if (!m_staticPipelineInitialized)
                InitializeStaticPipeline();

            EditorUtility.ClearProgressBar();
            EditorUtility.DisplayProgressBar("Generating mesh...", "Getting Mesh Data from GPU", 0f);

            GrassBladeTriangle[] triangleData = new GrassBladeTriangle[GrassTriangleCount];
            m_grassBladeTrianglesBuffer.GetData(triangleData);

            int[] triangles = new int[triangleData.Length * 3];
            Vector3[] vertices = new Vector3[triangleData.Length * 3];
            Vector3[] normals = new Vector3[triangleData.Length * 3];
            Vector4[] tangents = new Vector4[triangleData.Length * 3];
            Vector2[] grassUVS = new Vector2[triangleData.Length * 3];
            Vector2[] fieldUVS = new Vector2[triangleData.Length * 3];
            Vector2[] grassOriginsXY = new Vector2[triangleData.Length * 3];
            Vector2[] grassOriginsZ = new Vector2[triangleData.Length * 3];

            void Set<T>(T[] array, int index, T a, T b, T c)
            {
                array[index] = a;
                array[index + 1] = b;
                array[index + 2] = c;
            }

            for (int i = 0; i < triangleData.Length; i++)
            {
                EditorUtility.DisplayProgressBar("Generating mesh...", "Restructuring mesh data (" + (vertices.Length) + " vertices)", ((float)i / triangleData.Length) * 0.9f);

                GrassBladeTriangle triangle = triangleData[i];
                GrassBladeSpaceData space = triangle.space;
                GrassBladeVertex a = triangle.point0;
                GrassBladeVertex b = triangle.point1;
                GrassBladeVertex c = triangle.point2;

                Vector2 grassOriginXY = new Vector2(space.positionOS.x, space.positionOS.y);
                Vector2 grassOriginZ = new Vector2(space.positionOS.z, 0f);

                int index0 = i * 3;
                int index1 = index0 + 1;
                int index2 = index0 + 2;

                // ensure correct winding order
                if (index0 % 2 == 1)
                {
                    int temp = index1;
                    index1 = index2;
                    index2 = temp;
                }

                Set(triangles, index0, index0, index1, index2);
                Set(vertices, index0, a.positionOS, b.positionOS, c.positionOS);
                Set(normals, index0, space.normalOS, space.normalOS, space.normalOS);
                Set(tangents, index0, space.tangentOS, space.tangentOS, space.tangentOS);
                Set(grassUVS, index0, a.uv, b.uv, c.uv);
                Set(fieldUVS, index0, space.uv, space.uv, space.uv);
                Set(grassOriginsXY, index0, grassOriginXY, grassOriginXY, grassOriginXY);
                Set(grassOriginsZ, index0, grassOriginZ, grassOriginZ, grassOriginZ);
            }

            EditorUtility.DisplayProgressBar("Generating mesh...", "Creating mesh asset...", 0.9f);

            Mesh mesh = new Mesh
            {
                vertices = vertices,
                normals = normals,
                tangents = tangents,
                triangles = triangles,
                uv = grassUVS,
                uv2 = fieldUVS,
                uv3 = grassOriginsXY,
                uv4 = grassOriginsZ
            };

            mesh.RecalculateBounds();

            string assetPath = AssetDatabase.GenerateUniqueAssetPath("Assets/Grass/Compute/GeneratedMeshes/" + name + "_generatedGrass.asset");

            EditorUtility.DisplayProgressBar("Generating mesh...", "Saving to " + assetPath, 1f);

            AssetDatabase.CreateAsset(mesh, assetPath);
            AssetDatabase.SaveAssets();

            EditorUtility.ClearProgressBar();

            if (EditorUtility.DisplayDialog("why do i have to give this message a title", "Would you like to use the new mesh in the scene now?", "Yup", "Nup"))
            {
                GameObject newGameObject = new GameObject("Generated Mesh");
                newGameObject.transform.SetParent(transform);
                newGameObject.transform.localPosition = Vector3.zero;
                newGameObject.transform.localRotation = Quaternion.identity;
                newGameObject.transform.localScale = Vector3.one;

                MeshFilter meshFilter = newGameObject.AddComponent<MeshFilter>();
                MeshRenderer meshRenderer = newGameObject.AddComponent<MeshRenderer>();

                meshFilter.mesh = mesh;
                meshRenderer.material = m_grassMaterialMeshes;
                meshRenderer.shadowCastingMode = m_castShadows ? ShadowCastingMode.On : ShadowCastingMode.Off;

                enabled = false;
            }
        }
#endif

        #endregion

        #region Helper Functions

        /// <summary>
        /// generate a bounds which is the bounds of the original mesh, plus the maximum extent a blade of grass can be pushed out of that mesh.
        /// </summary>
        private void GetBounds()
        {
            m_bounds = m_mesh.bounds;

            m_bounds.center = transform.position;
            float maxPossibleHeight = m_properties.height + m_properties.heightVariance;
            m_bounds.Expand(maxPossibleHeight * 2f);
        }

        /// <summary>
        /// Pack vertex, normal, and uv data into structs.
        /// </summary>
        private SourceMeshVertexData[] PackData(IList<Vector3> vertices, IList<Vector3> normals, IList<Vector4> tangents, IList<Color> colors, IList<Vector2> uvs)
        {
            Debug.Assert(vertices.Count == normals.Count && normals.Count == tangents.Count && tangents.Count == uvs.Count, "All input data arrays must be the same length!");

            // if no mesh colours, just pass in empty values
            if (colors == null || colors.Count != vertices.Count)
                colors = new Color[vertices.Count];

            SourceMeshVertexData[] data = new SourceMeshVertexData[vertices.Count];

            for (int i = 0; i < vertices.Count; i++)
            {
                data[i] = new SourceMeshVertexData
                {
                    positionOS = vertices[i],
                    normalOS = normals[i],
                    tangentOS = tangents[i],    // casting Vector4 to Vector3 here
                    color = colors[i],    // casting Vector4 to Vector3 here
                    uv = uvs[i]
                };
            }

            return data;
        }

        /// <summary>
        /// Given a float, round it to the nearest 0.001.
        /// </summary>
        private float Round(float val)
        {
            float rounding = (INTERLOCKED_FLOAT_ACCURACY / RESULT_ROUNDING);
            return Mathf.Round(val * rounding) / rounding;
        }

        #endregion

        #region Structs

        [System.Serializable]
        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        private struct GrassBladeProperties
        {
            public const int Stride = sizeof(float) * 8;

            public float width;  // _BladeWidth
            public float widthVariance; // _BladeWidthRandom
            public float height; // _BladeHeight
            public float heightVariance; // _BladeHeightRandom
            public float rotationRangeX; // _BendRotationRandom
            public float rotationRangeY; // _BladeRotationRange
            public float tipOffsetZ; // _BladeForward
            public float curvature; // _BladeCurve

            public static GrassBladeProperties GetDefault()
            {
                return new GrassBladeProperties
                {
                    width = 1f,
                    height = 1f
                };
            }
        }

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        private struct SourceMeshVertexData
        {
            public const int Stride = sizeof(float) * 3 * 3 + +sizeof(float) * 4 + sizeof(float) * 2;

            public Vector3 positionOS;
            public Vector3 normalOS;
            public Vector3 tangentOS;
            public Color color;
            public Vector2 uv;
        };

        [System.Serializable]
        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        private struct GrassBladeVertex
        {
            public const int Stride = sizeof(float) * 3 + sizeof(float) * 2;

            public Vector3 positionOS;
            public Vector2 uv;

            public override string ToString() => $"positionOS: {positionOS}\nuv: {uv}";

        };

        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        struct GrassBladeSpaceData
        {
            public const int Stride = sizeof(float) * 3 * 4 + sizeof(float) * 2;

            public Vector3 positionOS;
            public Vector3 normalOS;
            public Vector3 tangentOS;
            public Vector3 bitangentOS;
            public Vector2 uv;
        };

        [System.Serializable]
        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        private struct GrassBladeTriangle
        {
            public const int Stride = GrassBladeVertex.Stride * 3 + GrassBladeSpaceData.Stride;

            public GrassBladeVertex point0;
            public GrassBladeVertex point1;
            public GrassBladeVertex point2;

            public GrassBladeSpaceData space;

            public Vector3 this[int index]
            {
                get
                {
                    if (index == 0)
                        return point0.positionOS;
                    else if (index == 1)
                        return point1.positionOS;
                    else if (index == 2)
                        return point2.positionOS;

                    throw new System.ArgumentOutOfRangeException();
                }
            }

            public override string ToString() => $"point0: {point0}\n\npoint1: {point1}\n\npoint2: {point2}";
        };

        #endregion

        #region Debug

#if UNITY_EDITOR
        private void OnDrawGizmosSelected()
        {
            Matrix4x4 matrix = Gizmos.matrix;
            Gizmos.matrix = m_localToWorldMatrix;

            Gizmos.color = Color.white;
            Gizmos.DrawWireCube(Vector3.zero, m_bounds.size);

            Gizmos.matrix = matrix;
        }

        private void OnDrawGizmos()
        {
            Matrix4x4 matrix = Gizmos.matrix;
            Gizmos.matrix = m_localToWorldMatrix;

            // drawing a clear box makes the grass selectable in the editor
            Gizmos.color = Color.clear;
            Gizmos.DrawCube(Vector3.zero, m_bounds.size);

            Gizmos.matrix = matrix;
        }
#endif

        #endregion
    }
}
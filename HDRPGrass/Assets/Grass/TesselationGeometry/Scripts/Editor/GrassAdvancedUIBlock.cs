using UnityEditor;
using UnityEngine;
using static Grass.Editor.HDMaterialProperties;

namespace Grass.Editor
{
    class GrassAdvancedUIBlock : MaterialUIBlock
    {
        static class Styles
        {
            public const string optionText = "Advanced";

            public static GUIContent tesselationTypeText = new GUIContent("Tesselation Type", "How triangles on the original geometry are tesselated. Affects the appearance of density.\nUniform = slightly cheaper, all triangles are tesselated equally. Will produce inconsistent results on different meshes.\nProportional = will try to tesselate each triangle in proportion to its world space size, making grass density less dependent on original geometry.");

            public static GUIContent frustumCullingText = new GUIContent("Frustum Culling", "Whether grass outside the camera frustum should be rendered.\nNote: this doesn't really do anything Unity isn't already doing...");
            public static GUIContent frustumCullingScreenSpaceMarginText = new GUIContent("Frustum Culling Screen Space Margin", "The distance, in screen space units, to add to or remove from the frustum culling.");

            public static GUIContent normalTypeText = new GUIContent("Normal Type", "How the grass blades get their normals.\nTrue = The normals are what you would expect if the grass was a real mesh, pointing away from the blades' surfaces.\nFrom Source = the normals are taken from the source geometry. (Recommended)\nOverride = manually specify a normal.");
            public static GUIContent normalOverrideText = new GUIContent("Normal Override", "The normal that will be provided to every grass blade vertex.");

            public static GUIContent lodsEnabled = new GUIContent("Use LODs", "Enable ability to modify grass complexity and distribution by distance from the camera. Leaving this disabled is the equivalent of always drawing at the highest LOD.");
            
            public static GUIContent lodDistancesText = new GUIContent("LOD Distances", "The distances for each LOD.");
            public static GUIContent lod0Text = new GUIContent("0", "Grass closer to the camera than this distance will have the most vertices.");
            public static GUIContent lod1Text = new GUIContent("1", "Grass closer to the camera than this distance will have the middle amount of vertices.");
            public static GUIContent lod2Text = new GUIContent("2", "Grass closer to the camera than this distance will have the middle amount of vertices. Grass further than this will be culled.");

            public static GUIContent lodSegmentsText = new GUIContent("LOD Segments", "The number of vertices per blade of grass according to LOD. A value of 0 is culled.");
            public static GUIContent lod0SegmentsText = new GUIContent("0", "Grass segments at LOD 0.");
            public static GUIContent lod1SegmentsText = new GUIContent("1", "Grass segments at LOD 1.");
            public static GUIContent lod2SegmentsText = new GUIContent("2", "Grass segments at LOD 2.");

            public static GUIContent lodDensitiesText = new GUIContent("LOD Densities", "The density of the grass by LOD. LOD 0 is specified in the grass distribution options.");
            public static GUIContent lod0DensitiesText = new GUIContent("0", "Grass density at LOD 0.");
            public static GUIContent lod1DensitiesText = new GUIContent("1", "Grass density at LOD 1.");
            public static GUIContent lod2DensitiesText = new GUIContent("2", "Grass density at LOD 2.");

            public static GUIContent castShadowsText = new GUIContent("Cast Shadows", "Toggle whether this grass casts shadows. This can also be controlled per Renderer on the Renderer component.");
            public static GUIContent applyDisplacementText = new GUIContent("Apply Displacement", "Toggle whether this material is affected by GrassDisplacementSphere MonoBehaviours.");
        }

        // this constant mirrors one in the geometry shader
        private const int MAX_SEGMENTS = 11;

        private MaterialProperty[] m_lodSqrDistancesProperty = new MaterialProperty[kMaxLayerCount];
        private const string LOD_SQUARE_DISTANCES_PROPERTY = "_GrassLODSqrDistances";

        private MaterialProperty[] m_lodSegmentsProperty = new MaterialProperty[kMaxLayerCount];
        private const string LOD_SEGMENTS_PROPERTY = "_GrassLODSegments";

        private const string NORMAL_TYPE_PROPERTY = "_NormalType";

        private MaterialProperty[] m_normalOverrideProperty = new MaterialProperty[kMaxLayerCount];
        private const string NORMAL_OVERRIDE_PROPERTY = "_AbsoluteNormal";
        
        //private MaterialProperty[] m_frustumCullingScreenSpaceMarginProperty = new MaterialProperty[kMaxLayerCount];
        //private const string FRUSTUM_CULLING_SCREEN_SPACE_MARGIN_PROPERTY = "_FrustumCullingScreenSpaceMargin";

        private const string NORMAL_TYPE_TRUE_PROPERTY = "NORMAL_TYPE_TRUE";
        private const string NORMAL_TYPE_FROM_SOURCE_PROPERTY = "NORMAL_TYPE_FROM_SOURCE";
        private const string NORMAL_TYPE_OVERRIDE_PROPERTY = "NORMAL_TYPE_OVERRIDE";

        private const string APPLY_DISPLACEMENT_PROPERTY = "APPLY_DISPLACEMENT";
        
        private const string FRUSTUM_CULLING_PROPERTY = "FRUSTUM_CULLING";
        private const string CAST_SHADOWS_PROPERTY = "CAST_SHADOWS";
        private const string LODS_ENABLED_PROPERTY = "LODS_ENABLED";

        private Expandable m_ExpandableBit;
        private int m_LayerCount;
        private int m_LayerIndex;

        private enum TesselationType { Uniform, Proportional };
        private enum NormalType { True, FromSource, Override };

        public GrassAdvancedUIBlock(Expandable expandableBit, int layerCount = 1, int layerIndex = 0)
        {
            m_ExpandableBit = expandableBit;
            m_LayerCount = layerCount;
            m_LayerIndex = layerIndex;
        }

        public override void LoadMaterialProperties()
        {
            base.LoadMaterialProperties();

            m_lodSqrDistancesProperty = FindPropertyLayered(LOD_SQUARE_DISTANCES_PROPERTY, m_LayerCount);
            m_lodSegmentsProperty = FindPropertyLayered(LOD_SEGMENTS_PROPERTY, m_LayerCount);
            m_normalOverrideProperty = FindPropertyLayered(NORMAL_OVERRIDE_PROPERTY, m_LayerCount);
            //m_frustumCullingScreenSpaceMarginProperty = FindPropertyLayered(FRUSTUM_CULLING_SCREEN_SPACE_MARGIN_PROPERTY, m_LayerCount);
        }

        public override void OnGUI()
        {
            using (MaterialHeaderScope header = new MaterialHeaderScope(Styles.optionText, (uint)m_ExpandableBit, materialEditor))
            {
                if (header.expanded)
                    DrawGUI();
            }
        }

        // doesnt really work well for multiple materials selected but neither does any enum so whatever
        private TesselationType GetCurrentTesselationType()
        {
            foreach (Material material in materials)
            {
                if (material.IsKeywordEnabled(PROPORTIONAL_TESSELATION_PROPERTY))
                    return TesselationType.Proportional;
                else
                    return TesselationType.Uniform;
            }

            return TesselationType.Uniform;
        }
        
        private void SetCurrentTesselationType(TesselationType type)
        {
            foreach (Material material in materials)
            {
                if (type == TesselationType.Uniform)
                    material.DisableKeyword(PROPORTIONAL_TESSELATION_PROPERTY);
                else
                    material.EnableKeyword(PROPORTIONAL_TESSELATION_PROPERTY);
            }
        }

        // doesnt really work well for multiple materials selected but neither does any enum so whatever
        private NormalType GetCurrentNormalType()
        {
            foreach (Material material in materials)
            {
                if (material.IsKeywordEnabled(NORMAL_TYPE_TRUE_PROPERTY))
                    return NormalType.True;
                if (material.IsKeywordEnabled(NORMAL_TYPE_FROM_SOURCE_PROPERTY))
                    return NormalType.FromSource;
                if (material.IsKeywordEnabled(NORMAL_TYPE_OVERRIDE_PROPERTY))
                    return NormalType.Override;
            }

            return NormalType.FromSource;
        }

        private void SetCurrentNormalType(NormalType normalType)
        {
            foreach (Material material in materials)
            {
                if (normalType == NormalType.True)
                {
                    material.EnableKeyword(NORMAL_TYPE_TRUE_PROPERTY);
                    material.DisableKeyword(NORMAL_TYPE_FROM_SOURCE_PROPERTY);
                    material.DisableKeyword(NORMAL_TYPE_OVERRIDE_PROPERTY);
                }
                else if (normalType == NormalType.FromSource)
                {
                    material.DisableKeyword(NORMAL_TYPE_TRUE_PROPERTY);
                    material.EnableKeyword(NORMAL_TYPE_FROM_SOURCE_PROPERTY);
                    material.DisableKeyword(NORMAL_TYPE_OVERRIDE_PROPERTY);
                }
                else if (normalType == NormalType.Override)
                {
                    material.DisableKeyword(NORMAL_TYPE_TRUE_PROPERTY);
                    material.DisableKeyword(NORMAL_TYPE_FROM_SOURCE_PROPERTY);
                    material.EnableKeyword(NORMAL_TYPE_OVERRIDE_PROPERTY);
                }
            }
        }
        
        private void DrawGUI()
        {
            DrawKeyword(APPLY_DISPLACEMENT_PROPERTY, Styles.applyDisplacementText);

            DrawKeyword(CAST_SHADOWS_PROPERTY, Styles.castShadowsText);

            TesselationType tesselationType = GetCurrentTesselationType();

            EditorGUI.BeginChangeCheck();
            tesselationType = (TesselationType)EditorGUILayout.EnumPopup(Styles.tesselationTypeText, tesselationType);
            if (EditorGUI.EndChangeCheck())
                SetCurrentTesselationType(tesselationType);

            NormalType normalType = GetCurrentNormalType();

            EditorGUI.BeginChangeCheck();
            normalType = (NormalType)EditorGUILayout.EnumPopup(Styles.normalTypeText, normalType);
            if (EditorGUI.EndChangeCheck())
                SetCurrentNormalType(normalType);

            if (normalType == NormalType.Override)
            {
                EditorGUI.BeginChangeCheck();
                Vector3 overrideNormal = EditorGUILayout.Vector3Field(Styles.normalOverrideText, m_normalOverrideProperty[m_LayerIndex].vectorValue);
                if (EditorGUI.EndChangeCheck())
                    m_normalOverrideProperty[m_LayerIndex].vectorValue = overrideNormal;
            }

            DrawKeyword(FRUSTUM_CULLING_PROPERTY, Styles.frustumCullingText);
            //if ()
            //{
            //    materialEditor.ShaderProperty(m_frustumCullingScreenSpaceMarginProperty[m_LayerIndex], Styles.frustumCullingScreenSpaceMarginText);

            //    if (m_frustumCullingScreenSpaceMarginProperty[m_LayerIndex].floatValue < 0f)
            //        EditorGUILayout.HelpBox("A negative frustum culling screen space margin will lead to visible frustum culling.", MessageType.Warning);
            //}

            if (DrawKeyword(LODS_ENABLED_PROPERTY, Styles.lodsEnabled))
            {
                Vector4 lodDistanceSettings = m_lodSqrDistancesProperty[m_LayerIndex].vectorValue;

                float labelWidth = EditorGUIUtility.labelWidth;
                EditorGUIUtility.labelWidth = 30f;

                EditorGUILayout.BeginVertical(EditorStyles.helpBox);

                EditorGUILayout.LabelField(Styles.lodDistancesText, EditorStyles.boldLabel);

                EditorGUILayout.BeginHorizontal();

                EditorGUI.BeginChangeCheck();

                float lod0 = EditorGUILayout.FloatField(Styles.lod0Text, Mathf.Sqrt(lodDistanceSettings.x));
                lod0 *= lod0;
                lod0 = Mathf.Clamp(lod0, 0f, lodDistanceSettings.y);

                float lod1 = EditorGUILayout.FloatField(Styles.lod1Text, Mathf.Sqrt(lodDistanceSettings.y));
                lod1 *= lod1;
                lod1 = Mathf.Clamp(lod1, lod0, lodDistanceSettings.z);

                float lod2 = EditorGUILayout.FloatField(Styles.lod2Text, Mathf.Sqrt(lodDistanceSettings.z));
                lod2 *= lod2;
                lod2 = Mathf.Max(lod2, lod1);

                if (EditorGUI.EndChangeCheck())
                    m_lodSqrDistancesProperty[m_LayerIndex].vectorValue = new Vector3(lod0, lod1, lod2);

                EditorGUILayout.EndHorizontal();

                EditorGUILayout.EndVertical();
                
                Vector4 lodSegmentSettings = m_lodSegmentsProperty[m_LayerIndex].vectorValue;

                EditorGUILayout.BeginVertical(EditorStyles.helpBox);

                EditorGUILayout.LabelField(Styles.lodSegmentsText, EditorStyles.boldLabel);

                EditorGUILayout.BeginHorizontal();

                EditorGUI.BeginChangeCheck();

                int lodSegments0 = EditorGUILayout.IntField(Styles.lod0SegmentsText, (int)lodSegmentSettings.x);
                lodSegments0 = Mathf.Clamp(lodSegments0, 1, MAX_SEGMENTS);

                int lodSegments1 = EditorGUILayout.IntField(Styles.lod1SegmentsText, (int)lodSegmentSettings.y);
                lodSegments1 = Mathf.Clamp(lodSegments1, (int)lodSegmentSettings.z, lodSegments0);

                int lodSegments2 = EditorGUILayout.IntField(Styles.lod2SegmentsText, (int)lodSegmentSettings.z);
                lodSegments2 = Mathf.Clamp(lodSegments2, 0, lodSegments1);

                if (EditorGUI.EndChangeCheck())
                    m_lodSegmentsProperty[m_LayerIndex].vectorValue = new Vector3(lodSegments0, lodSegments1, lodSegments2);

                EditorGUILayout.EndHorizontal();

                EditorGUILayout.EndVertical();

                float scaledLod0Density = GetScaledDensity(0);
                float scaledLod1Density = GetScaledDensity(1);
                float scaledLod2Density = GetScaledDensity(2);

                EditorGUILayout.BeginVertical(EditorStyles.helpBox);

                EditorGUILayout.LabelField(Styles.lodDensitiesText, EditorStyles.boldLabel);

                EditorGUILayout.BeginHorizontal();

                EditorGUI.BeginChangeCheck();

                GUI.enabled = false;
                EditorGUILayout.FloatField(Styles.lod0DensitiesText, scaledLod0Density);
                GUI.enabled = true;

                scaledLod1Density = Mathf.Clamp(EditorGUILayout.FloatField(Styles.lod1DensitiesText, scaledLod1Density), scaledLod2Density, scaledLod0Density);
                scaledLod2Density = Mathf.Clamp(EditorGUILayout.FloatField(Styles.lod2DensitiesText, scaledLod2Density), 0f, scaledLod1Density);

                if (EditorGUI.EndChangeCheck())
                {
                    SetScaledDensity(scaledLod1Density, 1);
                    SetScaledDensity(scaledLod2Density, 2);
                }

                EditorGUILayout.EndHorizontal();

                EditorGUILayout.EndVertical();

                EditorGUIUtility.labelWidth = labelWidth;
            }
        }
    }
}

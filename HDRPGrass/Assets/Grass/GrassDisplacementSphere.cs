using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace Grass
{
    /// <summary>
    /// Attach this component to an object to make it displace the grass around to to a set radius.
    /// </summary>
    [ExecuteInEditMode]
    public class GrassDisplacementSphere : MonoBehaviour
    {
        private const int MAX_GRASS_DISPLACEMENT_SPHERES = 10;

        private const string BUFFER_NAME = "_GrassDisplacementSpheresBuffer";
        private const string BUFFER_COUNT = "_GrassDisplacementSpheresBufferCount";

        [SerializeField]
        [Min(0f)]
        [Tooltip("How far the effect of the displacement extends.")]
        private float m_radius = 1;

        [SerializeField]
        [Min(0f)]
        [Tooltip("How strongly the displacer moves the grass.")]
        private float m_power = 1;
        
        [SerializeField]
        private bool m_showGizmo = false;

        private void OnEnable()
        {
            Register(this);
        }

        private void OnDisable()//
        {
            Deregister(this);
        }

        private void Update()
        {
            if (transform.hasChanged)
            {
                ResendBufferData();
                transform.hasChanged = false;
            }
        }

        private void OnValidate()
        {
            if (enabled)
                ResendBufferData();
        }

#if UNITY_EDITOR
        private void OnDrawGizmosSelected()
        {
            if (!m_showGizmo)
                return;

            Color col = Color.white;
            col.a = 0.666f;

            Gizmos.color = col;
            Gizmos.DrawSphere(transform.position, m_radius);
        }
#endif

        public GrassDisplacement GenerateDataStruct()
        {
            return new GrassDisplacement(transform.position, m_radius, m_power);
        }

        #region Static

        private static int m_bufferNameID = -1;
        private static int BufferNameID
        {
            get
            {
                if (m_bufferNameID == -1)
                    m_bufferNameID = Shader.PropertyToID(BUFFER_NAME);

                return m_bufferNameID;
            }
        }

        private static int m_bufferCountID = -1;
        private static int BufferCountID
        {
            get
            {
                if (m_bufferCountID == -1)
                    m_bufferCountID = Shader.PropertyToID(BUFFER_COUNT);

                return m_bufferCountID;
            }
        }

        private static int m_lastFrameUpdated = -1;

        private static ComputeBuffer m_buffer;

        private static HashSet<GrassDisplacementSphere> m_allGrassDisplacementSpheres = new HashSet<GrassDisplacementSphere>();//

        private static void Register(GrassDisplacementSphere sphere)
        {
            if (!sphere)
                return;

            if (m_allGrassDisplacementSpheres == null)
                m_allGrassDisplacementSpheres = new HashSet<GrassDisplacementSphere>();

            if (!m_allGrassDisplacementSpheres.Contains(sphere) && m_allGrassDisplacementSpheres.Count >= MAX_GRASS_DISPLACEMENT_SPHERES)
            {
                Debug.LogError("Max Grass Displacement Spheres (" + MAX_GRASS_DISPLACEMENT_SPHERES + ") exceeded! Object '" + sphere.name + "' will be ignored!", sphere);
                return;
            }

            if (m_allGrassDisplacementSpheres.Add(sphere))
                ResendBufferData();
        }

        private static void Deregister(GrassDisplacementSphere sphere)
        {
            if (!sphere)
                return;

            if (m_allGrassDisplacementSpheres != null)
            {
                m_allGrassDisplacementSpheres.Remove(sphere);

                if (m_allGrassDisplacementSpheres.Count == 0)
                {
                    m_buffer?.Release();
                    m_buffer = null;
                }
                else
                {
                    ResendBufferData();
                }
            }
        }

        private static void ResendBufferData()
        {
            int currentFrame = Time.frameCount;
            if (m_lastFrameUpdated != -1 && m_lastFrameUpdated == currentFrame)
                return;

            m_lastFrameUpdated = currentFrame;

            if (m_buffer == null)
            {
                m_buffer = new ComputeBuffer(MAX_GRASS_DISPLACEMENT_SPHERES, GrassDisplacement.Stride);
                Shader.SetGlobalBuffer(BufferNameID, m_buffer);
            }

            Shader.SetGlobalInt(BufferCountID, m_allGrassDisplacementSpheres.Count);

            m_buffer.SetData(
                    m_allGrassDisplacementSpheres
                    .Select(sphere => sphere.GenerateDataStruct())
                    .ToArray());
        }

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
        private static void ClearStaticData()
        {
            if (m_allGrassDisplacementSpheres != null)
                m_allGrassDisplacementSpheres.Clear();

            m_buffer?.Release();
            m_buffer = null;
        }

        #endregion
    }
    
    public struct GrassDisplacement
    {
        public const int Stride = sizeof(float) * 5;//

        public Vector3 Position;
        public float InverseRadius;
        public float Power;

        public GrassDisplacement(Vector3 position, float radius, float power)
        {
            Position = position;
            InverseRadius = radius == 0f ? 0f : 1f / radius;
            Power = power;
        }
    }
}

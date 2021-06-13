using UnityEditor;
using UnityEngine;
using static Grass.Editor.HDMaterialProperties;

namespace Grass.Editor
{
    class GrassDebugUIBlock : MaterialUIBlock
    {
        static class Styles
        {
            public const string optionText = "Debug";

            public static GUIContent debugViewText = new GUIContent("Debug View", "Visualize the wind, displacement, or LODs of the grass.");
            public static GUIContent drawSourceGeometryText = new GUIContent("Draw Source Geometry", "Display the mesh this material is applied to instead of the grass.");
        }

        private const string VISUALIZE_WIND_PROPERTY = "VISUALIZE_WIND";
        private const string VISUALIZE_DISPLACEMENT_PROPERTY = "VISUALIZE_DISPLACEMENT";
        private const string VISUALIZE_LODS_PROPERTY = "VISUALIZE_LODS";
        private const string DRAW_SOURCE_GEOMETRY_PROPERTY = "DRAW_SOURCE_GEOMETRY";

        private Expandable m_ExpandableBit;
        private int m_LayerCount;
        private int m_LayerIndex;

        private enum DebugView { Off, Wind, Displacement, LODs }
        private string[] m_debugViewLabels  = new string[] { "Off", "Wind", "Displacement", "LODs" };

        public GrassDebugUIBlock(Expandable expandableBit, int layerCount = 1, int layerIndex = 0)
        {
            m_ExpandableBit = expandableBit;
            m_LayerCount = layerCount;
            m_LayerIndex = layerIndex;
        }

        public override void LoadMaterialProperties()
        {
            
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
        private DebugView GetCurrentDebugView()
        {
            foreach (Material material in materials)
            {
                if (material.IsKeywordEnabled(VISUALIZE_WIND_PROPERTY))
                    return DebugView.Wind;
                if (material.IsKeywordEnabled(VISUALIZE_DISPLACEMENT_PROPERTY))
                    return DebugView.Displacement;
                if (material.IsKeywordEnabled(VISUALIZE_LODS_PROPERTY))
                    return DebugView.LODs;
            }

            return DebugView.Off;
        }

        private void SetCurrentDebugView(DebugView view)
        {
            foreach (Material material in materials)
            {
                if (view == DebugView.Wind)
                {
                    material.EnableKeyword(VISUALIZE_WIND_PROPERTY);
                    material.DisableKeyword(VISUALIZE_DISPLACEMENT_PROPERTY);
                    material.DisableKeyword(VISUALIZE_LODS_PROPERTY);
                }
                else if (view == DebugView.Displacement)
                {
                    material.DisableKeyword(VISUALIZE_WIND_PROPERTY);
                    material.EnableKeyword(VISUALIZE_DISPLACEMENT_PROPERTY);
                    material.DisableKeyword(VISUALIZE_LODS_PROPERTY);
                }
                else if (view == DebugView.LODs)
                {
                    material.DisableKeyword(VISUALIZE_WIND_PROPERTY);
                    material.DisableKeyword(VISUALIZE_DISPLACEMENT_PROPERTY);
                    material.EnableKeyword(VISUALIZE_LODS_PROPERTY);
                }
                else
                {
                    material.DisableKeyword(VISUALIZE_WIND_PROPERTY);
                    material.DisableKeyword(VISUALIZE_DISPLACEMENT_PROPERTY);
                    material.DisableKeyword(VISUALIZE_LODS_PROPERTY);
                }
            }
        }

        private void DrawGUI()
        {
            DebugView debugView = GetCurrentDebugView();

            EditorGUI.BeginChangeCheck();
            debugView = (DebugView)EditorGUILayout.Popup(Styles.debugViewText, (int)debugView, m_debugViewLabels);
            if (EditorGUI.EndChangeCheck())
                SetCurrentDebugView(debugView);

            EditorGUI.BeginChangeCheck();
            bool drawGeometry = EditorGUILayout.Toggle(Styles.drawSourceGeometryText, materials[0].IsKeywordEnabled(DRAW_SOURCE_GEOMETRY_PROPERTY));
            if (EditorGUI.EndChangeCheck())
            {
                foreach (Material material in materials)
                {
                    if (drawGeometry)
                        material.EnableKeyword(DRAW_SOURCE_GEOMETRY_PROPERTY);
                    else
                        material.DisableKeyword(DRAW_SOURCE_GEOMETRY_PROPERTY);
                }
            }
        }
    }
}

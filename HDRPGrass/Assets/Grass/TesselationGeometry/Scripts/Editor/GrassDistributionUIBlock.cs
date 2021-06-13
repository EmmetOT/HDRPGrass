using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEditor;

using static Grass.Editor.HDMaterialProperties;

namespace Grass.Editor
{
    class GrassDistributionUIBlock : MaterialUIBlock
    {
        static class Styles
        {
            public const string optionText = "Grass Distribution";

            public static GUIContent grassDensityText = new GUIContent("Grass Density", "The density of the grass. This will be proportional to the amount of vertices on the original mesh.");
            public static GUIContent positionRandomizationText = new GUIContent("Position Randomization", "Randomly offsets the grass blades' positions from their source vertices. Good for breaking up the pattern created by tesselation.");
            public static GUIContent grassMap = new GUIContent("Grass Map", "Samples using the source geometry's UVs to affect the distribution of grass. Vertex colours are also used. Leave this blank to put grass everywhere.");
        }

        private MaterialProperty[] m_grassPositionProperty = new MaterialProperty[kMaxLayerCount];
        private const string GRASS_POSITION_RANDOMIZATION = "_GrassOffset";

        private MaterialProperty[] m_grassMapProperty = new MaterialProperty[kMaxLayerCount];
        private const string GRASS_MAP_PROPERTY = "_GrassMap";
        
        private Expandable m_ExpandableBit;
        private int m_LayerCount;
        private int m_LayerIndex;

        public GrassDistributionUIBlock(Expandable expandableBit, int layerCount = 1, int layerIndex = 0)
        {
            m_ExpandableBit = expandableBit;
            m_LayerCount = layerCount;
            m_LayerIndex = layerIndex;
        }

        public override void LoadMaterialProperties()
        {
            base.LoadMaterialProperties();
            
            m_grassPositionProperty = FindPropertyLayered(GRASS_POSITION_RANDOMIZATION, m_LayerCount);
            m_grassMapProperty = FindPropertyLayered(GRASS_MAP_PROPERTY, m_LayerCount);
        }

        public override void OnGUI()
        {
            using (MaterialHeaderScope header = new MaterialHeaderScope(Styles.optionText, (uint)m_ExpandableBit, materialEditor))
            {
                if (header.expanded)
                    DrawGUI();
            }
        }

        private void DrawGUI()
        {
            float density = GetScaledDensity(0);

            EditorGUI.BeginChangeCheck();
            density = EditorGUILayout.Slider(Styles.grassDensityText, density, 0f, 1f);//Mathf.Lerp(0f, GetMaxDensity(), EditorGUILayout.Slider(Styles.grassDensityText, density, 0f, 1f));
            if (EditorGUI.EndChangeCheck())
                SetScaledDensity(density, 0);
                //m_grassDensityProperty.floatValue = density;

            if (density <= 0f)
                EditorGUILayout.HelpBox("Density of 0 might produce no geometry!", MessageType.Warning);

            materialEditor.ShaderProperty(m_grassPositionProperty[m_LayerIndex], Styles.positionRandomizationText);
            materialEditor.TexturePropertySingleLine(Styles.grassMap, m_grassMapProperty[m_LayerIndex]);

            materialEditor.TextureScaleOffsetProperty(m_grassMapProperty[m_LayerIndex]);
        }
    }
}

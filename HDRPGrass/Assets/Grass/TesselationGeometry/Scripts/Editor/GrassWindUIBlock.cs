using UnityEditor;
using UnityEngine;
using static Grass.Editor.HDMaterialProperties;

namespace Grass.Editor
{
    class GrassWindUIBlock : MaterialUIBlock
    {
        static class Styles
        {
            public const string optionText = "Wind";

            public static GUIContent windMapText = new GUIContent("Wind Distortion Map", "This texture describes the shape of the wind which displaces the grass blades. It should be tileable, with red representing movement on the x axis and green representing movement on the z axis.");
            public static GUIContent windFrequencyText = new GUIContent("Wind Frequency", "The speed of the wind displacement along the x and z axes.");
            public static GUIContent windStrengthText = new GUIContent("Wind Strength", "The power of the wind displacement.");
        }

        private MaterialProperty[] m_windMapProperty = new MaterialProperty[kMaxLayerCount];
        private const string WIND_MAP_PROPERTY = "_WindDistortionMap";

        private MaterialProperty[] m_windFrequencyProperty = new MaterialProperty[kMaxLayerCount];
        private const string WIND_FREQUENCY_PROPERTY = "_WindFrequency";

        private MaterialProperty[] m_windStrengthProperty = new MaterialProperty[kMaxLayerCount];
        private const string WIND_STRENGTH_PROPERTY = "_WindStrength";
        
        private Expandable m_ExpandableBit;
        private int m_LayerCount;
        private int m_LayerIndex;

        public GrassWindUIBlock(Expandable expandableBit, int layerCount = 1, int layerIndex = 0)
        {
            m_ExpandableBit = expandableBit;
            m_LayerCount = layerCount;
            m_LayerIndex = layerIndex;
        }

        public override void LoadMaterialProperties()
        {
            m_windMapProperty = FindPropertyLayered(WIND_MAP_PROPERTY, m_LayerCount);
            m_windFrequencyProperty = FindPropertyLayered(WIND_FREQUENCY_PROPERTY, m_LayerCount);
            m_windStrengthProperty = FindPropertyLayered(WIND_STRENGTH_PROPERTY, m_LayerCount);
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
            materialEditor.TexturePropertySingleLine(Styles.windMapText, m_windMapProperty[m_LayerIndex]);

            materialEditor.ShaderProperty(m_windStrengthProperty[m_LayerIndex], Styles.windStrengthText);
            
            EditorGUI.BeginChangeCheck();
            Vector2 windFrequencySetting = EditorGUILayout.Vector2Field(Styles.windFrequencyText, m_windFrequencyProperty[m_LayerIndex].vectorValue);
            if (EditorGUI.EndChangeCheck())
                m_windFrequencyProperty[m_LayerIndex].vectorValue = windFrequencySetting;
        }
    }
}

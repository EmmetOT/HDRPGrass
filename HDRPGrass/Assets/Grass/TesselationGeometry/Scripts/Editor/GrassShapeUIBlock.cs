using UnityEditor;
using UnityEngine;
using static Grass.Editor.HDMaterialProperties;

namespace Grass.Editor
{
    class GrassShapeUIBlock : MaterialUIBlock
    {
        static class Styles
        {
            public const string optionText = "Grass Shape";

            public static GUIContent styleText = new GUIContent("Style", "The shape of the generated grass.");
            public static GUIContent billboardText = new GUIContent("Billboarding", "Grass always rotates to face the camera.");
            public static GUIContent medianBladeWidthText = new GUIContent("Median Blade Width", "The width of the average grass blade.");
            public static GUIContent maxRandomWidthOffsetText = new GUIContent("Max Random Width Offset", "The variation of the grass blade width from the average. Sampled uniformly.");
            public static GUIContent medianBladeHeightText = new GUIContent("Median Blade Height", "The height of the average grass blade.");
            public static GUIContent maxRandomHeightOffsetText = new GUIContent("Max Random Height Offset", "The variation of the grass blade height from the average. Sampled uniformly.");
            public static GUIContent rotationRangeText = new GUIContent("Rotation Range", "The max rotation of the grass blades around their local y axis, in degrees.");
            public static GUIContent maxDownwardRotationText = new GUIContent("Max Downward Rotation", "The max rotation of the grass blades around their local x axis, in degrees.");
            public static GUIContent curvatureText = new GUIContent("Curvature", "How much the grass blades curve along their height.");
            public static GUIContent curvatureTipBiasText = new GUIContent("Curvature Tip Bias", "The offset along the blades' local z axis from the tip relative to the base.");
        }

        private MaterialProperty[] m_bladeWidthProperty = new MaterialProperty[kMaxLayerCount];
        private const string BLADE_WIDTH_PROPERTY = "_BladeWidth";

        private MaterialProperty[] m_bladeWidthRandomProperty = new MaterialProperty[kMaxLayerCount];
        private const string BLADE_WIDTH_RANDOM_PROPERTY = "_BladeWidthRandom";

        private MaterialProperty[] m_bladeHeightProperty = new MaterialProperty[kMaxLayerCount];
        private const string BLADE_HEIGHT_PROPERTY = "_BladeHeight";

        private MaterialProperty[] m_bladeHeightRandomProperty = new MaterialProperty[kMaxLayerCount];
        private const string BLADE_HEIGHT_RANDOM_PROPERTY = "_BladeHeightRandom";

        private MaterialProperty[] m_bladeRotationRangeProperty = new MaterialProperty[kMaxLayerCount];
        private const string BLADE_ROTATION_RANGE_PROPERTY = "_BladeRotationRange";

        private MaterialProperty[] m_maxDownwardRotationProperty = new MaterialProperty[kMaxLayerCount];
        private const string MAX_DOWNWARD_ROTATION_PROPERTY = "_BendRotationRandom";

        private MaterialProperty[] m_curvatureProperty = new MaterialProperty[kMaxLayerCount];
        private const string CURVATURE_PROPERTY = "_BladeCurve";

        private MaterialProperty[] m_curvatureTipBiasProperty = new MaterialProperty[kMaxLayerCount];
        private const string CURVATURE_TIP_BIAS = "_BladeForward";

        private const string BILLBOARD_PROPERTY = "BILLBOARD";

        private const string GENERATE_QUADS_PROPERTY = "GENERATE_QUADS";

        private Expandable m_ExpandableBit;
        private int m_LayerCount;
        private int m_LayerIndex;

        public GrassShapeUIBlock(Expandable expandableBit, int layerCount = 1, int layerIndex = 0)
        {
            m_ExpandableBit = expandableBit;
            m_LayerCount = layerCount;
            m_LayerIndex = layerIndex;
        }

        public override void LoadMaterialProperties()
        {
            m_bladeWidthProperty = FindPropertyLayered(BLADE_WIDTH_PROPERTY, m_LayerCount);
            m_bladeWidthRandomProperty = FindPropertyLayered(BLADE_WIDTH_RANDOM_PROPERTY, m_LayerCount);
            m_bladeHeightProperty = FindPropertyLayered(BLADE_HEIGHT_PROPERTY, m_LayerCount);
            m_bladeHeightRandomProperty = FindPropertyLayered(BLADE_HEIGHT_RANDOM_PROPERTY, m_LayerCount);
            m_bladeRotationRangeProperty = FindPropertyLayered(BLADE_ROTATION_RANGE_PROPERTY, m_LayerCount);
            m_maxDownwardRotationProperty = FindPropertyLayered(MAX_DOWNWARD_ROTATION_PROPERTY, m_LayerCount);
            m_curvatureProperty = FindPropertyLayered(CURVATURE_PROPERTY, m_LayerCount);
            m_curvatureTipBiasProperty = FindPropertyLayered(CURVATURE_TIP_BIAS, m_LayerCount);
        }

        public override void OnGUI()
        {
            using (MaterialHeaderScope header = new MaterialHeaderScope(Styles.optionText, (uint)m_ExpandableBit, materialEditor))
            {
                if (header.expanded)
                    DrawGUI();
            }
        }

        private enum GrassStyle { Blade, Quad }

        private void DrawGUI()
        {
            bool generateQuads = GetKeyword(GENERATE_QUADS_PROPERTY);
            GrassStyle currentGrassStyle = generateQuads ? GrassStyle.Quad : GrassStyle.Blade;

            EditorGUI.BeginChangeCheck();
            currentGrassStyle = (GrassStyle)EditorGUILayout.EnumPopup(Styles.styleText, currentGrassStyle);
            if (EditorGUI.EndChangeCheck())
            {
                SetKeyword(GENERATE_QUADS_PROPERTY, currentGrassStyle == GrassStyle.Quad);
            }

            bool billboarding = DrawKeyword(BILLBOARD_PROPERTY, Styles.billboardText);

            void SetPropertyWithMin(MaterialProperty property, GUIContent label, MaterialProperty variationProperty, GUIContent variationLabel, float min, string warning = null)
            {
                float current = property.floatValue;

                EditorGUI.BeginChangeCheck();
                current = Mathf.Max(min, EditorGUILayout.FloatField(label, current));
                if (EditorGUI.EndChangeCheck())
                    property.floatValue = current;

                materialEditor.ShaderProperty(variationProperty, variationLabel);

                float variation = variationProperty.floatValue;

                if (current <= min && variation == 0f && !string.IsNullOrEmpty(warning))
                    EditorGUILayout.HelpBox(warning, MessageType.Warning);
            }

            SetPropertyWithMin(m_bladeWidthProperty[m_LayerIndex], Styles.medianBladeWidthText, m_bladeWidthRandomProperty[m_LayerIndex], Styles.maxRandomWidthOffsetText, 0f, "Width and width offset of 0 might produce no geometry!");
            SetPropertyWithMin(m_bladeHeightProperty[m_LayerIndex], Styles.medianBladeHeightText, m_bladeHeightRandomProperty[m_LayerIndex], Styles.maxRandomHeightOffsetText, 0f, "Height and height offset of 0 might produce no geometry!");

            if (!billboarding)
                materialEditor.ShaderProperty(m_bladeRotationRangeProperty[m_LayerIndex], Styles.rotationRangeText);
            else
                EditorGUILayout.HelpBox("Grass blade local transform settings are disabled when billboarding. (Temporarily)", MessageType.Warning);

            GUI.enabled = !billboarding;

            materialEditor.ShaderProperty(m_maxDownwardRotationProperty[m_LayerIndex], Styles.maxDownwardRotationText);
            materialEditor.ShaderProperty(m_curvatureProperty[m_LayerIndex], Styles.curvatureText);
            materialEditor.ShaderProperty(m_curvatureTipBiasProperty[m_LayerIndex], Styles.curvatureTipBiasText);

            GUI.enabled = true;
        }
    }
}

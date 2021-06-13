using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEditor;

using static Grass.Editor.HDMaterialProperties;

namespace Grass.Editor
{
    class ColourOptionUIBlock : MaterialUIBlock
    {
        static class Styles
        {
            public const string optionText = "Colour Options";

            public static GUIContent grassTextureText = new GUIContent("Grass Colours", "Use this texture to colour the grass, and the two colours to modify the bottom and top of the grass blades respectively.");
            public static GUIContent grassFieldTextureText = new GUIContent("Grass Field Texture", "Apply a texture to the entire field of grass.");
            public static GUIContent metallicText = new GUIContent("Metallic", "Controls the scale factor for the material's metallic effect.");
            public static GUIContent smoothnessText = new GUIContent("Smoothness", "Controls the scale factor for the material's smoothness.");
        }
        
        private MaterialProperty[] m_grassBottomColourProperty = new MaterialProperty[kMaxLayerCount];
        private const string GRASS_BOTTOM_COLOUR_PROPERTY = "_GrassBottomColour";

        private MaterialProperty[] m_grassTopColourProperty = new MaterialProperty[kMaxLayerCount];
        private const string GRASS_TOP_COLOUR_PROPERTY = "_GrassTopColour";

        private MaterialProperty[] m_fieldTextureProperty = new MaterialProperty[kMaxLayerCount];
        private const string FIELD_TEXTURE_PROPERTY = "_FieldTexture";

        private MaterialProperty[] m_bladeTextureProperty = new MaterialProperty[kMaxLayerCount];
        private const string BLADE_TEXTURE_PROPERTY = "_BladeTexture";

        MaterialProperty[] m_metallicProperty = new MaterialProperty[kMaxLayerCount];
        private const string METALLIC_PROPERTY = "_Metallic";

        MaterialProperty[] m_smoothnessProperty = new MaterialProperty[kMaxLayerCount];
        private const string SMOOTHNESS_PROPERTY = "_Smoothness";

        private Expandable m_ExpandableBit;
        private int m_LayerCount;
        private int m_LayerIndex;

        public ColourOptionUIBlock(Expandable expandableBit, int layerCount = 1, int layerIndex = 0)
        {
            m_ExpandableBit = expandableBit;
            m_LayerCount = layerCount;
            m_LayerIndex = layerIndex;
        }

        public override void LoadMaterialProperties()
        {
            m_fieldTextureProperty = FindPropertyLayered(FIELD_TEXTURE_PROPERTY, m_LayerCount);
            m_bladeTextureProperty = FindPropertyLayered(BLADE_TEXTURE_PROPERTY, m_LayerCount);

            m_grassTopColourProperty = FindPropertyLayered(GRASS_TOP_COLOUR_PROPERTY, m_LayerCount);
            m_grassBottomColourProperty = FindPropertyLayered(GRASS_BOTTOM_COLOUR_PROPERTY, m_LayerCount);

            m_metallicProperty = FindPropertyLayered(METALLIC_PROPERTY, m_LayerCount);
            m_smoothnessProperty = FindPropertyLayered(SMOOTHNESS_PROPERTY, m_LayerCount);
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
            materialEditor.TexturePropertySingleLine(Styles.grassTextureText, m_bladeTextureProperty[m_LayerIndex], m_grassBottomColourProperty[m_LayerIndex], m_grassTopColourProperty[m_LayerIndex]);

            //materialEditor.ShaderProperty(m_metallicProperty[m_LayerIndex], Styles.metallicText);
            //materialEditor.ShaderProperty(m_smoothnessProperty[m_LayerIndex], Styles.smoothnessText);

            //materialEditor.TextureScaleOffsetProperty(m_grassTextureProperty[m_LayerIndex]);

            // materialEditor.TextureProperty()
            //materialEditor.TextureProperty(Styles.grassTextureText, m_fieldTextureProperty[m_LayerIndex]);
            materialEditor.TexturePropertySingleLine(Styles.grassFieldTextureText, m_fieldTextureProperty[m_LayerIndex]);
            materialEditor.TextureScaleOffsetProperty(m_fieldTextureProperty[m_LayerIndex]);
        }
    }
}

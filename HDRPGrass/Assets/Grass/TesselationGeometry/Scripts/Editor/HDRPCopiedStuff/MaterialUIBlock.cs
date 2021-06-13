using System;
using System.Linq;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEditor.Rendering;
using UnityEditor;

namespace Grass.Editor
{
    abstract class MaterialUIBlock
    {
        protected const float MAX_DENSITY_UNIFORM = 64f;
        protected const float MAX_DENSITY_PROPORTIONAL = 7f;


        //protected MaterialProperty m_grassDensityProperty = new MaterialProperty();
        //protected const string GRASS_DENSITY_PROPERTY = "_GrassDensity";


        protected MaterialProperty m_lodDensitiesProperty = new MaterialProperty();
        protected const string LOD_DENSITIES_PROPERTY = "_GrassLODDensities";


        protected const string PROPORTIONAL_TESSELATION_PROPERTY = "PROPORTIONAL_TESSELATION";

        protected float GetMaxDensity()
        {
            bool isProportionalDensity = GetKeyword(PROPORTIONAL_TESSELATION_PROPERTY);
            return isProportionalDensity ? MAX_DENSITY_PROPORTIONAL : MAX_DENSITY_UNIFORM;

        }

        protected float GetScaledDensity(int lod)
        {
            return Mathf.InverseLerp(0f, GetMaxDensity(), m_lodDensitiesProperty.vectorValue[lod]);
        }

        protected void SetScaledDensity(float density, int lod)
        {
            Vector4 val = m_lodDensitiesProperty.vectorValue;
            val[lod] = Mathf.Lerp(0f, GetMaxDensity(), density);
            m_lodDensitiesProperty.vectorValue = val;
        }

        // doesnt really work well for multiple materials selected but neither does any enum so whatever
        protected bool GetKeyword(string keyword)
        {
            foreach (Material material in materials)
            {
                if (material.IsKeywordEnabled(keyword))
                    return true;
            }

            return false;
        }

        protected void SetKeyword(string keyword, bool val)
        {
            foreach (Material material in materials)
            {
                if (val)
                    material.EnableKeyword(keyword);
                else
                    material.DisableKeyword(keyword);
            }
        }

        protected bool DrawKeyword(string keyword, GUIContent label)
        {
            bool val = GetKeyword(keyword);
            EditorGUI.BeginChangeCheck();
            val = EditorGUILayout.Toggle(label, val);
            if (EditorGUI.EndChangeCheck())
                SetKeyword(keyword, val);

            return val;
        }


        protected MaterialEditor materialEditor;
        protected Material[] materials;
        protected MaterialProperty[] properties;

        protected MaterialUIBlockList parent;

        [Flags]
        public enum Expandable : uint
        {
            // Standard
            Base = 1 << 0,
            Colour = 1 << 1,
            Distribution = 1 << 2,
            Shape = 1 << 3,
            Wind = 1 << 4,
            Advanced = 1 << 5,
            Debug = 1 << 6,
        }

        public void Initialize(MaterialEditor materialEditor, MaterialProperty[] properties, MaterialUIBlockList parent)
        {
            this.materialEditor = materialEditor;
            this.parent = parent;
            materials = materialEditor.targets.Select(target => target as Material).ToArray();

            // We should always register the key used to keep collapsable state
            materialEditor.InitExpandableState();
        }

        public void UpdateMaterialProperties(MaterialProperty[] properties)
        {
            this.properties = properties;
            LoadMaterialProperties();
        }

        protected MaterialProperty FindProperty(string propertyName, bool isMandatory = false)
        {
            // ShaderGUI.FindProperty is a protected member of ShaderGUI so we can't call it here:
            // return ShaderGUI.FindProperty(propertyName, properties, isMandatory);

            // TODO: move this to a map since this is done at every editor frame
            foreach (var prop in properties)
                if (prop.name == propertyName)
                    return prop;

            if (isMandatory)
                throw new ArgumentException("Could not find MaterialProperty: '" + propertyName + "', Num properties: " + properties.Length);
            return null;
        }

        protected MaterialProperty[] FindPropertyLayered(string propertyName, int layerCount, bool isMandatory = false)
        {
            MaterialProperty[] properties = new MaterialProperty[layerCount];

            // If the layerCount is 1, then it means that the property we're fetching is not from a layered material
            // thus it doesn't have a prefix
            string[] prefixes = (layerCount > 1) ? new[] { "0", "1", "2", "3" } : new[] { "" };

            for (int i = 0; i < layerCount; i++)
            {
                properties[i] = FindProperty(string.Format("{0}{1}", propertyName, prefixes[i]), isMandatory);
            }

            return properties;
        }

        public virtual void LoadMaterialProperties()
        {
            m_lodDensitiesProperty = FindProperty(LOD_DENSITIES_PROPERTY);
        }

        public abstract void OnGUI();
    }
}

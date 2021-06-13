using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEngine.Rendering;
using UnityEditor.Rendering.HighDefinition;
using UnityEditor.Rendering;
using UnityEditor.Experimental.Rendering;

using UnityEditor;

namespace Grass.Editor
{
    public class GrassGUI : ShaderGUI
    {
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            using (EditorGUI.ChangeCheckScope changed = new EditorGUI.ChangeCheckScope())
            {
                uiBlocks.OnGUI(materialEditor, properties);
            }
        }

        MaterialUIBlockList uiBlocks = new MaterialUIBlockList
        {
            new ColourOptionUIBlock(MaterialUIBlock.Expandable.Colour),
            new GrassDistributionUIBlock(MaterialUIBlock.Expandable.Distribution),
            new GrassShapeUIBlock(MaterialUIBlock.Expandable.Shape),
            new GrassWindUIBlock(MaterialUIBlock.Expandable.Wind),
            new GrassAdvancedUIBlock(MaterialUIBlock.Expandable.Advanced),
            new GrassDebugUIBlock(MaterialUIBlock.Expandable.Debug),
        };
        
        //protected bool m_FirstFrame = true;

        //protected void ApplyKeywordsAndPassesIfNeeded(bool changed, Material[] materials)
        //{
        //    // !!! HACK !!!
        //    // When a user creates a new Material from the contextual menu, the material is created from the editor code and the appropriate shader is applied to it.
        //    // This means that we never setup keywords and passes for a newly created material. The material is then in an invalid state.
        //    // To work around this, as the material is automatically selected when created, we force an update of the keyword at the first "frame" of the editor.

        //    // Apply material keywords and pass:
        //    if (changed || m_FirstFrame)
        //    {
        //        m_FirstFrame = false;

        //        foreach (var material in materials)
        //            SetupMaterialKeywordsAndPassInternal(material);
        //    }
        //}

    }
}

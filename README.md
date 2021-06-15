
# HDRPGrass
Grass for Unity's HD render pipeline. This project was an experiment to learn more about hand-writing HDRP shaders and writing shaders with custom tesselation steps. There's also an additional attempt to create grass using compute shaders + DrawProceduralIndirect. This project was written for Unity version 2019.4.11f1 and given the volatile nature of hand-writing HDRP shaders I doubt it will work in newer versions!

This project was initially part of a larger 3D platformer game but I decided to separate the grass out as a little showcase. The grass was originally meant to be based off [this tutorial here](https://roystan.net/articles/grass-shader.html), but quickly veered off course when I realized I couldn't just write HDRP shaders easily, and shadergraph doesn't support tessellation. So began a week of hair-pulling as I disentangled the HDRP lit shader! In the end I not only matched the tutorial but added a few other nice features.

I should note however that my end conclusion is that were I to do this again, I would not under ANY circumstances attempt to do it with tessellation. It's an outmoded approach and was a real pain to get working, and honestly, it takes up a lot of VRAM. I'd like to attempt this again and just use instances meshes. 

![hdrpGrass0](https://user-images.githubusercontent.com/18707147/121815886-81bd4380-cc70-11eb-98f6-b842c7ba6033.gif)

This project is divided by the two approaches: named 'TessellationGeometry' and 'Compute.' TessellationGeometry being much more fleshed out.

## TesselationGeometry

TessellationGeometry grass is rendered simply by applying a material with the shader 'Grass/Grass_TessellationGeometry' to a mesh. The mesh geometry will be transformed into a field of verdant grass!

This shader has a full custom material inspector in the style of Unity's render pipeline shaders. Each of these fields are explained via tooltips but I'll go over some of the more obtuse ones here.

![hdrpGrass1](https://user-images.githubusercontent.com/18707147/121816574-58061b80-cc74-11eb-9537-0ed09c654be3.png)

- **Grass Colours**: This dictates how individual blades of grass are coloured from top to bottom. You can both specify two colours as a sample gradient and provide a texture.
- **Grass Field Texture**: multiply the grass colour across the whole field, sampling a texture using the original geometry's UVs. This is how I create the alternate green colours in the lawn grass in the gif above.
- **Grass Map**: A greyscale texture which affects the size of grass blades, again sampled using the original object's UVs. **Grass height can also be affected via the r channel of the geometry's vertex colours.**
- **Style**: You can decide whether you want your blades of grass to taper to a point or be quads.
- **Billboarding**: The grass can be set to rotat around its local vertical axis to face the camera.
- **Wind Distortion Map**: A red and green texture which pushes the grass around over time, simulating wind. 
- **Apply Displacement**: Whether this grass is pushed around by displacement spheres.
- **Tessellation Type**: This controls how the original geometry's polygons are tessellated. Proportional tessellation will tessellate large polygons more in order to produce a more even density. Uniform will tessellate all polygons equally.
- **Normal Type**: How the normals of the grass blade vertices are determined. The default setting is 'From Source' which reproduces the normal of the source geometry at that point. This looks the best by far. I also include a 'true' setting which gives each grass blade vertex a normal perpendicular to the grass blade, and a normal override setting.

### LODs 

![hdrpGrass2](https://user-images.githubusercontent.com/18707147/121816886-1d9d7e00-cc76-11eb-87d8-112943c4db18.png)

You can have up to three levels of detail for the TessellationGeometry grass, based on its distance from the camera.

From left to right, you have highest to lowest level of detail. In the above example, LOD0 displays when the grass is <10 units away, LOD1 at <30, and LOD2 at <90. At greater than 90 units, the grass is culled.

For each LOD you can control how many segments the grass blades are broken into (which only really matters visually if the grass blade has curvature) and how dense the field of grass is. LOD0's density is controlled by the default density slider.

You can view the LODs explicitly as a debug view. (See below).

### Debug Views

![hdrpGrass3](https://user-images.githubusercontent.com/18707147/121817042-ef6c6e00-cc76-11eb-9903-e7b0e021b4ca.png)

#### Wind

Display the wind texture as the grass field colour.

![hdrpGrass4](https://user-images.githubusercontent.com/18707147/121817140-6efa3d00-cc77-11eb-99bf-870a4db3fd5c.gif)

#### Displacement

Double check that displacement by GrassDisplacementSpheres is working.

![hdrpGrass5](https://user-images.githubusercontent.com/18707147/121817178-a5d05300-cc77-11eb-80fb-9968146790fc.gif)

#### LOD

Colour each LOD by RGB.

![hdrpGrass6](https://user-images.githubusercontent.com/18707147/121817221-f182fc80-cc77-11eb-8e48-fef1f637f546.gif)

## Compute

![hdrpGrass6](https://user-images.githubusercontent.com/18707147/122127471-1f5c7280-ce2b-11eb-8d8a-d4ac9f34f322.png)

The demo for the Compute version is comparitively much simpler. Instead of using tessellation, the compute grass takes some input geometry and generates a fixed number of random evenly distributed points on its surface. Grass geometry is then generated at these points and buffered, making this approach a lot faster than tessellation, at the cost of being more unwieldy (it's not just a drag-and-drop material anymore.)

This grass is controlled with a ProceduralGrassRenderer component. This component is also capable of 'baking' the generated mesh and saving it as an asset. When combined with the correct material, the result is exactly like the procedural output...

![hdrpGrass6](https://user-images.githubusercontent.com/18707147/122127802-a27dc880-ce2b-11eb-8db0-f9073fdec921.png)

but now your asset can be used as a brush in terrain!

![placing-compute-shader-hdrp-grass](https://user-images.githubusercontent.com/18707147/122127892-c5a87800-ce2b-11eb-82a9-03a2126d6f4c.gif)

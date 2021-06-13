
# HDRPGrass
Grass for Unity's HD render pipeline. This project was an experiment to learn more about hand-writing HDRP shaders and writing shaders with custom tesselation steps. There's also an additional attempt to create grass using compute shaders + DrawProceduralIndirect. This project was written for Unity version 2019.4.11f1 and given the volatile nature of hand-writing HDRP shaders I doubt it will work in newer versions!

This project was initially part of a larger 3D platformer game but I decided to separate the grass out as a little showcase. The grass was originally meant to be based off [this tutorial here](https://roystan.net/articles/grass-shader.html), but quickly veered off course when I realized I couldn't just write HDRP shaders easily, and shadergraph doesn't support tessellation. So began a week of hair-pulling as I disentangled the HDRP lit shader!

![hdrpGrass0](https://user-images.githubusercontent.com/18707147/121815886-81bd4380-cc70-11eb-98f6-b842c7ba6033.gif)

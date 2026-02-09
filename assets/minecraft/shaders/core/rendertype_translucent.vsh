#version 150

#moj_import <light.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
in ivec2 UV2;
in vec3 Normal;

uniform sampler2D Sampler2;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec3 ChunkOffset;

out float vertexDistance;
out vec4 vertexColor;
out vec2 texCoord0;
flat out ivec2 rawLightCoord;

// ESTE ES EL DATO CLAVE
out vec3 flatNormal; 
out vec3 viewPos; 

void main() {
    vec4 pos = ModelViewMat * vec4(Position + ChunkOffset, 1.0);
    gl_Position = ProjMat * pos;

    vertexDistance = length(pos.xyz);
    vertexColor = Color * minecraft_sample_lightmap(Sampler2, UV2);
    texCoord0 = UV0;
    
    // Convertimos la normal del bloque a espacio de vista.
    // Para el agua plana, esto nos dice exactamente la inclinación de la cámara.
    flatNormal = (ModelViewMat * vec4(Normal, 0.0)).xyz;
    
    rawLightCoord = UV2;
    viewPos = pos.xyz;
}
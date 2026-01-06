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
out vec4 normal;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position + ChunkOffset, 1.0);

    vertexDistance = length((ModelViewMat * vec4(Position + ChunkOffset, 1.0)).xyz);
    
    // 1. Calculamos el color base con la luz vanilla
    vec4 vColor = Color * minecraft_sample_lightmap(Sampler2, UV2);

    // 2. LÓGICA DE DETECCIÓN DE LUZ (BLOOM SELECTIVO)
    // UV2.x es la luz del bloque (entero).
    // Usamos la marca 0.80 que es más segura y fácil de detectar.
    if (UV2.x > 210) {
        vColor.a = 0.80;
    }

    vertexColor = vColor;
    texCoord0 = UV0;
    normal = ProjMat * ModelViewMat * vec4(Normal, 0.0);
}
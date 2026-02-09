#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;

// --- CONFIGURACIÓN DE BLOOM ---
const float EMISSIVE_ID = 0.80;
const float GLOW_THRESHOLD = 0.0; // Umbral de brillo para activar el bloom

// Funciones de utilidad
float getLuma(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

vec3 increaseSaturation(vec3 color, float factor) {
    float gray = getLuma(color);
    return mix(vec3(gray), color, 1.0 + factor);
}

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }

    // --- PROCESADO VISUAL (Estilo ReShaded) ---
    color.rgb *= 1.3;
    color.rgb = increaseSaturation(color.rgb, 0.3);

    // Sistema de Banding (Sombreado estilizado)
    float vertexBrightness = max(max(vertexColor.r, vertexColor.g), vertexColor.b);
    
    // Sombras medias
    if (vertexBrightness <= 0.6420) { color.rgb *= vec3(0.968, 0.971, 1.005); }
    if (vertexBrightness <= 0.6260) { color.rgb *= vec3(0.968, 0.971, 1.005); }
    if (vertexBrightness <= 0.6100) { color.rgb *= vec3(0.968, 0.971, 1.005); }
    
    // Sombras oscuras
    if (vertexBrightness <= 0.2085) { color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.1990) { color.rgb *= vec3(0.976, 0.976, 0.986); }

    // --- LÓGICA DE BLOOM SELECTIVO ---
    // Calculamos el brillo real del píxel final
    float particleLuma = getLuma(color.rgb);

    // Si la partícula brilla más que el umbral (ej. Fuego, Lava, Magia)...
    if (particleLuma > GLOW_THRESHOLD) {
        // ...le asignamos el ID exacto que afterglow.fsh busca.
        // GRACIAS al particle.json modificado, este 0.80 se guarda puro en el buffer.
        color.a = EMISSIVE_ID; 
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
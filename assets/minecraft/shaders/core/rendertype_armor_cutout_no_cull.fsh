#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec2 texCoord0;
in vec4 overlayColor; // Necesario para el efecto de daño (rojo)

out vec4 fragColor;

// --- CONSTANTES DE CONTROL (Estilo ReShaded) ---
const float CONTRAST_STRENGTH = 1.0;
const float SATURATION_STRENGTH = 1.0;

// --- FUNCIONES DE MEJORA VISUAL ---

vec3 applyVibrance(vec3 color, float vibranceStrength) {
    float luminance = dot(color, vec3(0.3));
    float maxChannel = max(max(color.r, color.g), color.b);
    float minChannel = min(min(color.r, color.g), color.b);
    float saturation = maxChannel - minChannel;
    float vibranceFactor = (1.0 - saturation) * vibranceStrength;
    return mix(vec3(luminance), color, 1.0 + vibranceFactor);
}

vec3 reduceOverbrightWhites(vec3 color) {
    float luminance = dot(color, vec3(0.333));
    float maxC = max(max(color.r, color.g), color.b);
    float minC = min(min(color.r, color.g), color.b);
    float saturation = maxC - minC;
    float lumFactor = smoothstep(0.6, 0.95, luminance);
    float satFactor = 1.0 - smoothstep(0.0, 0.4, saturation); 
    float whiteFactor = lumFactor * satFactor;
    return color * mix(1.0, 0.95, whiteFactor);
}

vec3 adjustPixelLuminanceGradient(vec3 color) {
    float brightness = dot(color, vec3(0.333));
    float distance = abs(brightness - 0.325);
    float falloff = 1.0 - smoothstep(0.0, 0.65, distance);
    float boost = mix(1.0, 2.0, falloff);
    return clamp(color * boost, 0.0, 1.0);
}

vec3 increaseContrastByLuminance(vec3 color) {
    float luminance = dot(color, vec3(0.333));
    float underFactor = 1.0 - smoothstep(0.0, 0.5, luminance);
    return mix(color, vec3(0.0), underFactor * 0.1 * CONTRAST_STRENGTH);
}

void main() {
    // 1. Obtener color base de la textura de la armadura
    vec4 baseColor = texture(Sampler0, texCoord0);

    // 2. Descartar partes transparentes
    if (baseColor.a < 0.1) {
        discard;
    }

    // 3. Aplicar color de vértice y modulador
    vec4 color = baseColor * vertexColor * ColorModulator;

    // 4. Aplicar Overlay (Efecto rojo de daño) - ESTO ES CRUCIAL PARA ARMADURAS
    color.rgb = mix(color.rgb, overlayColor.rgb, overlayColor.a);

    // --- INICIO LÓGICA RESHADED ---

    // 5. Brillo global inicial (Igual que en cutout_mipped)
    color.rgb *= 0.65;

    // 6. Aplicar Vibranza
    color.rgb = applyVibrance(color.rgb, 0.4 * SATURATION_STRENGTH);

    // 7. Lógica de sombreado por brillo de vértice (Banding System)
    float vertexBrightness = max(max(vertexColor.r, vertexColor.g), vertexColor.b);
    
    // Bloque laterales/superiores
    if (vertexBrightness <= 0.6420) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6380) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6340) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6300) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6260) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6220) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6180) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6140) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6100) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }
    if (vertexBrightness <= 0.6060) { color.rgb *= vec3(0.9583, 0.9752, 0.9971); }

    // Bloque sombras profundas y tintes oscuros
    if (vertexBrightness <= 0.1960) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.1975) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.1990) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2005) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2020) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2025) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2040) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2055) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2070) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2085) { color.rgb *= vec3(0.96473); }

    if (vertexBrightness <= 0.2)  { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.18) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.16) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.14) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.12) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.10) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.08) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.06) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.04) { color.rgb *= vec3(1.1); }
    if (vertexBrightness <= 0.02) { color.rgb *= vec3(1.1); }

    // 8. Post-procesado final
    color.rgb = adjustPixelLuminanceGradient(color.rgb);
    color.rgb = increaseContrastByLuminance(color.rgb);
    color.rgb = reduceOverbrightWhites(color.rgb);

    // --- FIN LÓGICA RESHADED ---

    // 9. Niebla
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
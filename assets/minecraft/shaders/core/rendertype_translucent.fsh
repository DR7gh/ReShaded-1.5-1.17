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
// Recibimos la luz del VSH
flat in ivec2 rawLightCoord;

out vec4 fragColor;

// --- CONFIGURACIÓN DE BLOOM ---
const float EMISSIVE_ID = 0.80;
// Nivel de luz mínimo (240 = Nivel 15)
const float LIGHT_LEVEL_THRESHOLD = 240.0;

// UMBRAL DE BRILLO (CRÍTICO):
// Lo bajamos a 0.1 para que el Portal (que es oscuro) active el bloom.
// Como esto es solo para translúcidos, no afectará a bloques sólidos.
const float LUMA_THRESHOLD = 0.1; 

// --- CONSTANTES DE CONTROL VISUAL ---
const float CONTRAST_STRENGTH = 1.0;
const float SATURATION_STRENGTH = 1.0;

// --- FUNCIONES ---
float getLuma(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

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
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    
    // Validar descarte de invisibles
    if (color.a < 0.01) {
        discard;
    }

    // --- LÓGICA RESHADED (Mejora de Color) ---
    // Aumentamos un poco el brillo base (1.3) pero NO x9.
    color.rgb *= 0.65;
    color.rgb = applyVibrance(color.rgb, 0.0 * SATURATION_STRENGTH);

    // Sistema de Banding (Sombras Estilizadas)
    float vertexBrightness = max(max(vertexColor.r, vertexColor.g), vertexColor.b);

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

    // Post-procesado final
    color.rgb = adjustPixelLuminanceGradient(color.rgb);
    color.rgb = increaseContrastByLuminance(color.rgb);
    color.rgb = reduceOverbrightWhites(color.rgb);

    // --- APLICACIÓN DE BLOOM SELECTIVO ---
    // Criterio: Luz 15 Y que el píxel tenga un mínimo de color visible (0.1)
    float pixelLuma = getLuma(color.rgb);
    
    if (float(rawLightCoord.x) >= LIGHT_LEVEL_THRESHOLD && pixelLuma > LUMA_THRESHOLD) {
        // Asignamos el ID de bloom
        color.a = EMISSIVE_ID;
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
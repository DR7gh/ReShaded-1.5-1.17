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
flat in ivec2 rawLightCoord;
in vec3 viewPos; 
in vec3 flatNormal; 

out vec4 fragColor;

// --- CONFIGURACIÓN ---
const float ID_BLOOM = 0.80;    
const float ID_WATER_BASE = 0.60;  
const float ID_WATER_RANGE = 0.10; 

// --- CONFIGURACIÓN DE FADE (ÁNGULO) ---
// Define cuándo el reflejo empieza a perder fuerza.
// 0.0 = Mirando abajo | 1.0 = Mirando horizonte
const float FADE_START = 0.0; // Empieza a bajar intensidad al mirar un poco hacia abajo
const float FADE_END   = 1.0; // Intensidad máxima al mirar al horizonte

const float LIGHT_LEVEL_THRESHOLD = 240.0;
const float LUMA_THRESHOLD = 0.1; 
const float FRESNEL_POWER = 4.0;   

// --- PALETA ---
const vec3 DAY_SKY      = vec3(0);   
const vec3 SUNSET_SKY   = vec3(0);    
const vec3 NIGHT_SKY    = vec3(0); 

float getLuma(vec3 color) { return dot(color, vec3(0.299, 0.587, 0.114)); }
vec3 applyVibrance(vec3 color, float strength) {
    float lum = getLuma(color);
    vec3 sat = vec3(lum);
    return mix(sat, color, 1.0 + strength);
}

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    
    if (color.a < 0.01) discard;

    // --- CÁLCULO ROBUSTO DE INTENSIDAD ---
    // Usamos la normal plana para saber qué tan horizontal es nuestra vista respecto al agua.
    vec3 viewDir = normalize(-viewPos);
    vec3 norm = normalize(flatNormal);
    
    // 0.0 = Mirando verticalmente (Abajo/Arriba)
    // 1.0 = Mirando rasante (Horizonte)
    float angleFactor = abs(dot(viewDir, norm)); 
    // Invertimos porque dot(view, norm) da 1.0 si miras perpendicular (abajo)
    float horizontalFactor = 1.0 - angleFactor; 

    // Calculamos la fuerza del reflejo (0.0 a 1.0)
    float globalIntensity = smoothstep(FADE_START, FADE_END, horizontalFactor);

    // --- CODIFICACIÓN EN ALPHA ---
    if (color.a > 0.15 && color.a < 0.95) {
        color.a = ID_WATER_BASE + (globalIntensity * ID_WATER_RANGE);
    }

    // --- TINTE VISUAL ---
    if (color.a >= ID_WATER_BASE && color.a <= ID_WATER_BASE + ID_WATER_RANGE + 0.01) {
         float brightness = length(ColorModulator.rgb);
         float wDay = smoothstep(0.55, 1.1, brightness);
         float wNight = 1.0 - smoothstep(0.15, 0.4, brightness);
         float wSunset = 1.0 - wDay - wNight; wSunset = max(0.0, wSunset);
         vec3 skyReflectColor = (DAY_SKY * wDay) + (SUNSET_SKY * wSunset) + (NIGHT_SKY * wNight);
         float fresnel = pow(1.0 - angleFactor, FRESNEL_POWER);
         color.rgb = mix(color.rgb, skyReflectColor, fresnel * 0.5);
    }

    color.rgb *= 1.3; 
    color.rgb = applyVibrance(color.rgb, 0.0);

    float pixelLuma = getLuma(color.rgb);
    if (float(rawLightCoord.x) >= LIGHT_LEVEL_THRESHOLD && pixelLuma > LUMA_THRESHOLD) {
        color.a = ID_BLOOM;
    }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
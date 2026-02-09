#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler; 

varying vec2 texCoord;
varying vec2 oneTexel;

// --- CONFIGURACIÓN DE CALIDAD ---
const float BLOOM_DISPERSION_RADIUS = 55.0; 
const int TOTAL_BLOOM_SAMPLES = 8; 
const float NOISE_GRAIN_SIZE = 10000000000000000000000000000000.0; 

// --- SISTEMA 1: BLOOM SELECTIVO (ID) ---
const float EMISSIVE_MARKER = 0.80; 
const float MARKER_TOLERANCE = 0.02;
const float BLOCK_INTENSITY = 0.3; 

// --- SISTEMA 2: BLOOM CLÁSICO (SOL, NUBES, FOG) ---
const float FADE_START = 0.999;   // Tu ajuste de profundidad
const float FADE_END   = 0.9999; 

// UMBRAL DE BRILLO: Solo píxeles con luma mayor a este valor brillarán (Cielo = ~0.5-0.6, Nubes/Sol = >0.7)
const float ATMOSPHERE_LUMA_THRESHOLD = 0.05; 

// INTENSIDAD: Aumentada para que el sol y nubes "sangren" más luz
const float GLOBAL_ATMOSPHERE_INTENSITY = 0.07; 

const float GOLDEN_ANGLE = 2.3999632;

float Luma(vec3 rgb) { return dot(rgb, vec3(0.2125, 0.7154, 0.0721)); }
float getNoise(vec2 coord) { return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453); }

vec3 toneMap(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

vec3 bloom() {
    vec3 glow = vec3(0.0);
    float totalWeight = 0.0;
    
    vec2 pixelCoord = texCoord / oneTexel;
    vec2 noiseCoord = floor(pixelCoord / NOISE_GRAIN_SIZE);
    float randomRotation = getNoise(noiseCoord) * 6.2831;

    for (int i = 0; i < TOTAL_BLOOM_SAMPLES; i++) {
        float fraction = float(i) / float(TOTAL_BLOOM_SAMPLES);
        float r = sqrt(fraction); 
        float theta = float(i) * GOLDEN_ANGLE + randomRotation;
        
        vec2 offset = vec2(cos(theta), sin(theta)) * r * BLOOM_DISPERSION_RADIUS * oneTexel;
        
        vec4 sampleData = texture2D(DiffuseSampler, texCoord + offset);
        vec3 diffuse_sample = sampleData.rgb;
        float alphaID = sampleData.a;
        float sampleDepth = texture2D(DepthSampler, texCoord + offset).r;

        float weight = 1.0 - fraction; 
        float sampleLuma = Luma(diffuse_sample);
        float brightness = 0.0;

        // 1. Detección Selectiva (ID 0.80)
        bool isMarked = abs(alphaID - EMISSIVE_MARKER) < MARKER_TOLERANCE;

        if (isMarked) {
            brightness = pow(sampleLuma, 0.6) * BLOCK_INTENSITY;
        } else {
            // 2. Bloom Clásico con Filtro de Brillo
            float distanceMask = smoothstep(FADE_START, FADE_END, sampleDepth);
            
            // Restamos el umbral para que solo los pixeles muy claros generen luz
            // Esto evita que el azul del cielo brille, pero permite que el Sol y las Nubes blancas sí.
            float lumaMask = smoothstep(ATMOSPHERE_LUMA_THRESHOLD, 1.0, sampleLuma);
            
            brightness = sampleLuma * GLOBAL_ATMOSPHERE_INTENSITY * distanceMask * lumaMask;
        }

        glow += diffuse_sample * pow(brightness * 2.5, 1.5) * 8.0 * weight;
        totalWeight += weight;
    }

    return (totalWeight > 0.0 ? glow / totalWeight : vec3(0.0)) / 4.0;
}

void main() {
    vec4 sampleData = texture2D(DiffuseSampler, texCoord);
    vec3 colorOriginal = sampleData.rgb;

    vec3 finalColor = colorOriginal + bloom();
    finalColor = toneMap(finalColor);

    gl_FragColor = vec4(finalColor, 1.0);
}
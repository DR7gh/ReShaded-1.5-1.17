#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DepthSampler; 

varying vec2 texCoord;
varying vec2 oneTexel;

// --- CONSTANTES MODIFICABLES ---
const float BLOOM_DISPERSION_RADIUS = 30.0; 
const int TOTAL_BLOOM_SAMPLES = 3; 
const float NOISE_GRAIN_SIZE = 1.0; 
const float GOLDEN_ANGLE = 2.3999632;

// --- NUEVA VARIABLE DE CONTROL ---
const float BLOOM_THRESHOLD = 0.65; // 0.0 = Todo el cielo sangra | 0.8 = Solo zonas muy brillantes

// Rango donde el bloque empieza a recibir luz del cielo
const float FADE_START = 0.9999; 
const float FADE_END = 0.99999; 

float Luma(vec3 rgb) { return dot(rgb, vec3(0.2125, 0.7154, 0.0721)); }

float getNoise(vec2 coord) { 
    return fract(sin(dot(coord, vec2(12.9898, 78.233))) * 43758.5453); 
}

vec3 getSkyBleed() {
    vec3 accumulation = vec3(0.0);
    float totalWeight = 0.0;
    
    vec2 pixelCoord = texCoord / oneTexel;
    vec2 noiseCoord = floor(pixelCoord / NOISE_GRAIN_SIZE);
    float randomRotation = getNoise(noiseCoord) * 6.2831;

    for (int i = 0; i < TOTAL_BLOOM_SAMPLES; i++) {
        float fraction = float(i) / float(TOTAL_BLOOM_SAMPLES);
        float theta = float(i) * GOLDEN_ANGLE + randomRotation;
        
        vec2 offset = vec2(cos(theta), sin(theta)) * sqrt(fraction) * BLOOM_DISPERSION_RADIUS * oneTexel;
        vec3 sampleColor = texture2D(DiffuseSampler, texCoord + offset).rgb;
        float sampleDepth = texture2D(DepthSampler, texCoord + offset).r;

        // Detectamos si la muestra es cielo
        float isSky = smoothstep(FADE_START, FADE_END, sampleDepth);
        
        // Aplicamos el Threshold: restamos el umbral a la luminosidad de la muestra
        float brightness = max(0.0, Luma(sampleColor) - BLOOM_THRESHOLD);
        
        // El peso depende de la distancia, de si es cielo y de si supera el umbral
        float weight = (1.0 - fraction) * isSky * (brightness > 0.0 ? 1.0 : 0.0);

        // Multiplicamos por la luminosidad filtrada para que el desvanecimiento sea suave
        accumulation += sampleColor * brightness * weight;
        totalWeight += weight;
    }
    
    return (totalWeight > 0.0) ? (accumulation / totalWeight) : vec3(0.0);
}

void main() {
    vec3 colorOriginal = texture2D(DiffuseSampler, texCoord).rgb;
    
    // Obtenemos el color del cielo que sobrepasa el threshold
    vec3 skyGlow = getSkyBleed();

    // Sumamos el sangrado ruidoso. 
    // He mantenido un valor alto como pediste (0.95) para que sea muy evidente.
    vec3 finalColor = colorOriginal + (skyGlow * 1.35);

    gl_FragColor = vec4(finalColor, 1.0);
}
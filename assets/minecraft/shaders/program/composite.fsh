#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;      
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;

uniform float GameTime; 

varying vec2 texCoord;

const float CLOUD_BRIGHTNESS_MULT = 1.3; 
const float ID_BLOOM = 0.80; 
const float ID_TOLERANCE = 0.005; 

// --- CONFIGURACIÓN TÉCNICA ---
const float ID_WATER_BASE = 0.60;
const float ID_WATER_RANGE = 0.10;

// --- CONFIGURACIÓN DE REFLEJOS ---
const float MAX_REFLECTION_STRENGTH = 1.95; 
const float WAVE_SIZE = 0.003;          
const float WAVE_SPEED = 3.0;
const float REFLECTION_BLUR_RADIUS = 2.0; 
const float REFLECTION_FADE_CURVE = 4.5; 
const float REFLECTION_SATURATION = 1.0; // Ajustable

// --- CONFIGURACIÓN DE DARK BLOCKS ---
const float BLOCK_DARKEN_FACTOR = 0.6; 
const float BLOCK_BRIGHTNESS_CAP = 0.35; 

// --- FADE POR DISTANCIA ---
const float REFLECTION_DIST_START = 0.99;   
const float REFLECTION_DIST_END   = 0.9999999; 

// --- NUEVO: ESTIRAMIENTO DINÁMICO (Sustituye a la estabilización) ---
// Define cuánto se deforma la imagen cuando miras hacia abajo.
// 1.0 = Sin deformación extra.
// 3.0 = Se estira mucho verticalmente al mirar abajo.
const float DYNAMIC_STRETCH_STRENGTH = 6.5; 

float random(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 blendLayer(vec3 baseColor, float blockageDepth, sampler2D layerSampler, sampler2D depthSampler, float brightnessMult, bool distanceFade, inout float currentAlphaID) {
    vec4 layerColor = texture2D(layerSampler, texCoord);
    float layerDepth = texture2D(depthSampler, texCoord).r;

    if (layerColor.a <= 0.001) return baseColor;

    layerColor.rgb *= brightnessMult;

    if (distanceFade) {
        float fadeFactor = smoothstep(0.999, 1.0, layerDepth);
        layerColor.a *= (1.0 - fadeFactor);
    }

    bool isSky = blockageDepth >= 0.9999;
    bool isCloser = layerDepth < blockageDepth;

    if (isSky || isCloser) {
        
        if (abs(layerColor.a - ID_BLOOM) < ID_TOLERANCE) {
            currentAlphaID = ID_BLOOM;
            return mix(baseColor, layerColor.rgb, 1.0);
        }
        
        else if (layerColor.a >= ID_WATER_BASE - 0.001 && layerColor.a <= (ID_WATER_BASE + ID_WATER_RANGE + 0.001)) {
            
            // 1. Intensidad Base (0.0 a 1.0)
            float rawIntensity = (layerColor.a - ID_WATER_BASE) / ID_WATER_RANGE;
            rawIntensity = clamp(rawIntensity, 0.0, 1.0);
            
            // 2. Curva de Fade Visual
            float globalIntensity = pow(rawIntensity, REFLECTION_FADE_CURVE);

            // 3. Intensidad por Distancia
            float distFade = 1.0 - smoothstep(REFLECTION_DIST_START, REFLECTION_DIST_END, layerDepth);
            globalIntensity *= distFade;

            if (globalIntensity < 0.001) {
                 return mix(baseColor, layerColor.rgb, layerColor.a);
            }

            // --- CÁLCULO DE ESTIRAMIENTO DINÁMICO ---
            // Si rawIntensity es 1.0 (Horizonte) -> stretch = 1.0 (Normal)
            // Si rawIntensity es 0.0 (Abajo)     -> stretch = DYNAMIC_STRETCH_STRENGTH
            // Usamos "mix" para transicionar suavemente entre los dos estados.
            float currentStretch = mix(DYNAMIC_STRETCH_STRENGTH, 1.0, rawIntensity);

            // Aplicamos el estiramiento ANTES de invertir la coordenada
            float stretchedY = pow(texCoord.y, currentStretch);
            
            // Inversión Y (Espejo plano con estiramiento aplicado)
            vec2 reflectCoord = vec2(texCoord.x, 1.0 - stretchedY);
            
            // Ondas
            float wave = sin(texCoord.y * 60.0 + GameTime * WAVE_SPEED) * WAVE_SIZE;
            reflectCoord.x += wave;
            
            reflectCoord = clamp(reflectCoord, 0.001, 0.999);

            vec3 reflectedScene = vec3(0.0);
            
            // --- BLUR ---
            if (REFLECTION_BLUR_RADIUS <= 0.01) {
                reflectedScene = texture2D(DiffuseSampler, reflectCoord).rgb;
            } 
            else {
                float blurStep = REFLECTION_BLUR_RADIUS * 0.0015; 
                float totalWeight = 0.0;

                for (float i = -1.0; i <= 1.0; i += 1.0) {
                    for (float j = -1.0; j <= 1.0; j += 1.0) {
                        vec2 offset = vec2(i, j) * blurStep;
                        vec2 samplePos = reflectCoord + offset;
                        samplePos = clamp(samplePos, 0.001, 0.999);
                        float weight = 4.0 - (abs(i) + abs(j)) * 1.5; 
                        reflectedScene += texture2D(DiffuseSampler, samplePos).rgb * weight;
                        totalWeight += weight;
                    }
                }
                reflectedScene /= totalWeight;
            }

            // --- DARK BLOCKS FIX ---
            float reflectDepth = texture2D(DiffuseDepthSampler, reflectCoord).r;
            if (reflectDepth < 0.9999) {
                reflectedScene *= BLOCK_DARKEN_FACTOR;
                reflectedScene = min(reflectedScene, vec3(BLOCK_BRIGHTNESS_CAP));
            }

            // --- POST-PROCESO ---
            float luma = dot(reflectedScene, vec3(0.299, 0.587, 0.114));
            vec3 grayReflect = vec3(luma);
            
            // Saturación Configurable
            vec3 finalReflectionColor = mix(grayReflect, reflectedScene, REFLECTION_SATURATION);

            float noise = (random(texCoord + GameTime * 0.1) - 0.5) * 0.05;
            float ditheredLuma = clamp(luma + noise, 0.0, 1.0);
            float suppressionMask = 1.0 - ditheredLuma;
            
            vec3 waterWithReflection = mix(layerColor.rgb, finalReflectionColor, MAX_REFLECTION_STRENGTH * globalIntensity * suppressionMask);
            
            return mix(baseColor, waterWithReflection, 0.7); 
        }

        return mix(baseColor, layerColor.rgb, layerColor.a);
    }
    
    return baseColor;
}

void main() {
    vec4 solidColor = texture2D(DiffuseSampler, texCoord);
    float solidDepth = texture2D(DiffuseDepthSampler, texCoord).r;
    float transDepth = texture2D(TranslucentDepthSampler, texCoord).r;

    float closestObstacle = min(solidDepth, transDepth);

    float alphaID = solidColor.a;
    vec3 finalRGB = solidColor.rgb;

    finalRGB = blendLayer(finalRGB, solidDepth, TranslucentSampler, TranslucentDepthSampler, 1.0, true, alphaID);
    
    finalRGB = blendLayer(finalRGB, solidDepth, ParticlesSampler, ParticlesDepthSampler, 1.0, true, alphaID);
    finalRGB = blendLayer(finalRGB, solidDepth, ItemEntitySampler, ItemEntityDepthSampler, 1.0, false, alphaID);
    
    finalRGB = blendLayer(finalRGB, closestObstacle, CloudsSampler, CloudsDepthSampler, CLOUD_BRIGHTNESS_MULT, false, alphaID);
    finalRGB = blendLayer(finalRGB, closestObstacle, WeatherSampler, WeatherDepthSampler, 1.0, false, alphaID);

    gl_FragColor = vec4(finalRGB, alphaID);
}
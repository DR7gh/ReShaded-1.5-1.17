#version 120

uniform sampler2D DiffuseSampler;        // Sólidos
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;    // Agua, Cristal
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;      // Partículas (Fuego, Humo, etc.)
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;

varying vec2 texCoord;

// --- CONFIGURACIÓN ---
const float CLOUD_BRIGHTNESS_MULT = 1.0; 
const float EMISSIVE_ID = 0.80; 
const float ID_TOLERANCE = 0.01; // Tolerancia estricta

// Función de mezcla MAESTRA
// currentAlphaID: Variable que viaja y se actualiza si encontramos algo que debe brillar
vec3 blendLayer(vec3 baseColor, float blockageDepth, sampler2D layerSampler, sampler2D depthSampler, float brightnessMult, bool distanceFade, inout float currentAlphaID) {
    vec4 layerColor = texture2D(layerSampler, texCoord);
    float layerDepth = texture2D(depthSampler, texCoord).r;

    // Si la capa es invisible, salir rápido
    if (layerColor.a <= 0.001) return baseColor;

    // 1. Aplicar Brillo Extra (Solo afecta a Nubes si se pide)
    layerColor.rgb *= brightnessMult;

    // 2. Lógica de Niebla Manual (Suavizado de agua en el horizonte)
    if (distanceFade) {
        float fadeFactor = smoothstep(0.999, 1.0, layerDepth);
        layerColor.a *= (1.0 - fadeFactor);
    }

    // 3. Lógica de Visibilidad (Depth Test)
    bool isSky = blockageDepth >= 0.9999;
    bool isCloser = layerDepth < blockageDepth;

    if (isSky || isCloser) {
        
        // --- DETECCIÓN DE ID DE PARTÍCULAS ---
        // Si la partícula (fuego) trae el ID 0.80, sobrescribimos el ID del pixel.
        if (abs(layerColor.a - EMISSIVE_ID) < ID_TOLERANCE) {
            currentAlphaID = EMISSIVE_ID;
        }

        // Mezcla normal de color
        return mix(baseColor, layerColor.rgb, layerColor.a);
    }
    
    return baseColor;
}

void main() {
    // 1. Base Sólida (Terreno)
    vec4 solidColor = texture2D(DiffuseSampler, texCoord);
    float solidDepth = texture2D(DiffuseDepthSampler, texCoord).r;
    float transDepth = texture2D(TranslucentDepthSampler, texCoord).r;

    // Calculamos el obstáculo más cercano para capas atmosféricas
    float closestObstacle = min(solidDepth, transDepth);

    // Inicializamos el ID y Color con lo que haya en el bloque sólido
    float alphaID = solidColor.a;
    vec3 finalRGB = solidColor.rgb;

    // 2. Capas que respetan profundidad de sólidos (Agua, Partículas, Items)
    finalRGB = blendLayer(finalRGB, solidDepth, TranslucentSampler, TranslucentDepthSampler, 1.0, true, alphaID);
    finalRGB = blendLayer(finalRGB, solidDepth, ParticlesSampler, ParticlesDepthSampler, 1.0, true, alphaID);
    finalRGB = blendLayer(finalRGB, solidDepth, ItemEntitySampler, ItemEntityDepthSampler, 1.0, false, alphaID);
    
    // 3. Capas Atmosféricas (CORRECCIÓN DE ORDEN AQUÍ)
    
    // PRIMERO: Las Nubes (Fondo)
    // Se dibujan antes para quedar "atrás" de la lluvia.
    finalRGB = blendLayer(finalRGB, closestObstacle, CloudsSampler, CloudsDepthSampler, CLOUD_BRIGHTNESS_MULT, false, alphaID);

    // SEGUNDO: El Clima (Frente)
    // Se dibuja al final para que la lluvia/nieve cubra las nubes.
    finalRGB = blendLayer(finalRGB, closestObstacle, WeatherSampler, WeatherDepthSampler, 1.0, false, alphaID);

    // Salida final
    gl_FragColor = vec4(finalRGB, alphaID);
}
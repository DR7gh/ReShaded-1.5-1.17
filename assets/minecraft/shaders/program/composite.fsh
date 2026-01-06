#version 120

uniform sampler2D DiffuseSampler;        // Sólidos
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentSampler;    // Agua, Cristal
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D ItemEntitySampler;
uniform sampler2D ItemEntityDepthSampler;
uniform sampler2D ParticlesSampler;
uniform sampler2D ParticlesDepthSampler;
uniform sampler2D WeatherSampler;
uniform sampler2D WeatherDepthSampler;
uniform sampler2D CloudsSampler;
uniform sampler2D CloudsDepthSampler;

varying vec2 texCoord;

// --- CONFIGURACIÓN ---
// Multiplicador de brillo para las nubes (1.4 = +40% brillo)
const float CLOUD_BRIGHTNESS_MULT = 1.2; 

// Función de mezcla GENÉRICA MEJORADA
// Ahora acepta un 'brightnessMult' para ajustar la intensidad de la capa
vec3 blendLayer(vec3 baseColor, float blockageDepth, sampler2D layerSampler, sampler2D depthSampler, float brightnessMult) {
    vec4 layerColor = texture2D(layerSampler, texCoord);
    float layerDepth = texture2D(depthSampler, texCoord).r;

    if (layerColor.a <= 0.0) return baseColor;

    // --- APLICAR BRILLO EXTRA ---
    layerColor.rgb *= brightnessMult;

    // LÓGICA DE VISIBILIDAD:
    bool isSky = blockageDepth >= 0.9999;
    bool isCloser = layerDepth < blockageDepth;

    if (isSky || isCloser) {
        return mix(baseColor, layerColor.rgb, layerColor.a);
    }
    
    return baseColor;
}

void main() {
    vec4 solidColor = texture2D(DiffuseSampler, texCoord);
    float solidDepth = texture2D(DiffuseDepthSampler, texCoord).r;
    
    float transDepth = texture2D(TranslucentDepthSampler, texCoord).r;

    // Cálculo de obstáculos (Pared o Cristal)
    float closestObstacle = min(solidDepth, transDepth);

    float alphaID = solidColor.a;
    vec3 finalRGB = solidColor.rgb;

    // 1. Capas estándar (Brillo 1.0)
    finalRGB = blendLayer(finalRGB, solidDepth, TranslucentSampler, TranslucentDepthSampler, 1.0);
    finalRGB = blendLayer(finalRGB, solidDepth, ItemEntitySampler, ItemEntityDepthSampler, 1.0);
    finalRGB = blendLayer(finalRGB, solidDepth, ParticlesSampler, ParticlesDepthSampler, 1.0);
    
    // 2. Capas atmosféricas
    // Clima (Lluvia/Nieve) - Brillo normal (1.0)
    finalRGB = blendLayer(finalRGB, closestObstacle, WeatherSampler, WeatherDepthSampler, 1.0);
    
    // NUBES - ¡Brillo aumentado! (CLOUD_BRIGHTNESS_MULT)
    finalRGB = blendLayer(finalRGB, closestObstacle, CloudsSampler, CloudsDepthSampler, CLOUD_BRIGHTNESS_MULT);

    gl_FragColor = vec4(finalRGB, alphaID);
}
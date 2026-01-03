#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;
uniform sampler2D TranslucentDepthSampler;
uniform sampler2D CloudsDepthSampler;

varying vec2 texCoord;

// --- CONSTANTE DE ESCALA DE BLUR ---
const float BLUR_SCALE = 0.0; // Factor de amplificación del radio de desenfoque
// ------------------------------------

vec3 diffuse() {
    // Multiplicamos todos los desplazamientos por BLUR_SCALE para aumentar el radio de muestreo.
    vec3 diffusion = texture2D(DiffuseSampler, texCoord + vec2(0.0, 0.0009765625) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0, 0.001953125) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.000845728, 0.0004882812) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.001691456, 0.0009765624) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.0008457279, -0.0004882814) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(-0.001691456, -0.0009765627) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(1.551271e-10, -0.0009765626) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(3.102542e-10, -0.001953125) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0008457282, -0.0004882811) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.001691456, -0.0009765623) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.0008457279, 0.0004882815) * BLUR_SCALE).rgb;
    diffusion += texture2D(DiffuseSampler, texCoord + vec2(0.001691456, 0.0009765631) * BLUR_SCALE).rgb;
    
    return diffusion / 12.0; // El divisor se mantiene en 12.0 porque seguimos tomando 12 muestras.
}

void main() {
    // 1. CAPTURAR EL ID DE BLOOM (La corrección clave)
    // Leemos el alpha original antes de procesar nada.
    float alphaID = texture2D(DiffuseSampler, texCoord).a;

    float diffuseDepth = texture2D(DiffuseDepthSampler, texCoord).r;
    float translucentDepth = texture2D(TranslucentDepthSampler, texCoord).r;
    float cloudsDepth = texture2D(CloudsDepthSampler, texCoord).r;
    
    // Lógica de umbral de profundidad
    float threshold = diffuseDepth - min(translucentDepth, cloudsDepth);
    
    // Aplicar blur si corresponde
    vec3 gjengi = threshold > 0.0 ? diffuse() : texture2D(DiffuseSampler, texCoord).rgb;

    // 2. SALIDA CON EL ID RESTAURADO
    // En lugar de poner 1.0, ponemos 'alphaID' para que el dato (0.80) siga su viaje.
    gl_FragColor = vec4(gjengi, alphaID);
    gl_FragDepth = diffuseDepth;
}
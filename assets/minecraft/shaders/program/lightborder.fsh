#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;

varying vec2 texCoord;

const float angle = radians(60.0);
const float angleSin = sin(angle);
const float angleCos = cos(angle);
const mat2 rotationMatrix = mat2(angleCos, angleSin, -angleSin, angleCos);

// --- CONSTANTE DE BRILLO DE BORDE ---
const float EDGE_HIGHLIGHT_BRIGHTNESS = 1.4; 
const float SSAO_THRESHOLD_INVERT = 0.5; 
// ------------------------------------

float ssao(float rootDepth) {
    vec2 direction = vec2(0.0, 1.0 / 256.0);
    float distance = 1.0 - pow(rootDepth, 64.0);
    float occlusion = 0.0;

    for (float i = 0.0; i < 6.0; ++i) {
        direction *= rotationMatrix;

        for (float j = 1.0; j < 7.0; ++j) {
            float radius = distance * j;
            float sampleDepth = texture2D(DiffuseDepthSampler, texCoord + (direction * radius)).r;
            float rangeCheck = smoothstep(0.0, 1.0, radius / abs(rootDepth - sampleDepth));

            // Lógica de SSAO Invertida
            occlusion += sampleDepth <= rootDepth ? rangeCheck : 0.0;
        }
    }

    return occlusion / 36.0;
}

void main() {
    float depth = texture2D(DiffuseDepthSampler, texCoord).r;
    
    // 1. LEER EL ALPHA ORIGINAL (Aquí viaja tu ID de Bloom)
    vec4 texData = texture2D(DiffuseSampler, texCoord);
    vec3 gjengi = texData.rgb;
    float alphaID = texData.a; // Guardamos el 0.984

    // Calcular SSAO
    float ao_concavity = depth < 1.0 ? ssao(depth) : 1.0;
    
    // Invertir la Oclusión
    float ao_borde_expuesto = 1.0 - ao_concavity;
    
    // Aplicar factor de intensidad
    float highlight_factor = smoothstep(SSAO_THRESHOLD_INVERT, 1.0, ao_borde_expuesto);
    
    // Crear el Color Final
    vec3 final_color = mix(gjengi, gjengi * EDGE_HIGHLIGHT_BRIGHTNESS, highlight_factor);

    // 2. SALIDA FINAL CON EL ALPHA ORIGINAL
    // En lugar de poner 1.0, ponemos 'alphaID' para que el dato llegue a afterglow
    gl_FragColor = vec4(final_color, alphaID);
    gl_FragDepth = depth;
}
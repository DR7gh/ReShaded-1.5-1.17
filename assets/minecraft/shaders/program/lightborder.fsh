#version 120

uniform sampler2D DiffuseSampler;
uniform sampler2D DiffuseDepthSampler;

varying vec2 texCoord;

const float angle = radians(60.0);
const float angleSin = sin(angle);
const float angleCos = cos(angle);
const mat2 rotationMatrix = mat2(angleCos, angleSin, -angleSin, angleCos);

// --- CONFIGURACIÓN DE EFECTOS ---
const float EDGE_HIGHLIGHT_BRIGHTNESS = 1.4; 
const float SSAO_DARK_INTENSITY = 0.5; 
const float SSAO_THRESHOLD = 0.5;

// --- CONFIGURACIÓN DE DISTANCIA (NUEVO) ---
// Define a qué profundidad el efecto deja de funcionar.
// 0.9 es "lejos", 1.0 es el cielo/infinito.
const float FADE_START = 0.99; // Empieza a desvanecerse aquí
const float FADE_END   = 0.9999; // Desaparece totalmente aquí (Evita el cielo)

// ------------------------------------

float ssao(float rootDepth) {
    vec2 direction = vec2(0.0, 1.0 / 256.0);
    // Limitamos el radio basado en la profundidad para no muestrear cosas lejanas por error
    float distance = 1.0 - pow(rootDepth, 64.0); 
    float occlusion = 0.0;
    
    for (float i = 0.0; i < 6.0; ++i) {
        direction *= rotationMatrix;
        for (float j = 1.0; j < 7.0; ++j) {
            float radius = distance * j;
            float sampleDepth = texture2D(DiffuseDepthSampler, texCoord + (direction * radius)).r;
            // Range check más estricto para evitar halos en bordes lejanos
            float rangeCheck = smoothstep(0.0, 1.0, radius / abs(rootDepth - sampleDepth));
            occlusion += sampleDepth <= rootDepth ? rangeCheck : 0.0;
        }
    }

    return occlusion / 36.0;
}

void main() {
    float depth = texture2D(DiffuseDepthSampler, texCoord).r;
    
    vec4 texData = texture2D(DiffuseSampler, texCoord);
    vec3 color = texData.rgb;
    float alphaID = texData.a; 

    // --- MÁSCARA DE DISTANCIA ---
    // Si la profundidad es alta (lejos), el factor baja a 0.
    // Esto protege al cielo y la niebla de ser sombreados.
    float distanceFade = 1.0 - smoothstep(FADE_START, FADE_END, depth);

    // Solo calculamos SSAO si estamos lo suficientemente cerca (Optimización)
    if (distanceFade > 0.01) {
        float ao_val = depth < 1.0 ? ssao(depth) : 1.0;

        // Factores originales
        float shadow_factor = smoothstep(SSAO_THRESHOLD, 1.0, ao_val);
        float exposed_val = 1.0 - ao_val;
        float highlight_factor = smoothstep(SSAO_THRESHOLD, 1.0, exposed_val);

        // APLICAR FADE
        // Multiplicamos la intensidad por la distancia.
        // Si está lejos, shadow_factor y highlight_factor se vuelven 0.
        shadow_factor *= distanceFade;
        highlight_factor *= distanceFade;

        // Aplicar Oscuridad
        color *= (1.0 - shadow_factor * SSAO_DARK_INTENSITY);

        // Aplicar Brillo
        color = mix(color, color * EDGE_HIGHLIGHT_BRIGHTNESS, highlight_factor);
    }

    gl_FragColor = vec4(color, alphaID);
    gl_FragDepth = depth;
}
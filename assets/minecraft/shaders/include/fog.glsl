#version 150

// --- CONFIGURACIÓN DE DENSIDAD Y MULTIPLICADORES (Ajustados para evitar capas) ---
const float ENVIRONMENTAL_DENSITY = 1.0; 
const float RENDER_DENSITY        = 1.0; 

// Sincronizamos los inicios en 0.25 para eliminar el tercer color cercano
const float ENVIRONMENTAL_START_MULT = 0.01;
const float ENVIRONMENTAL_END_MULT   = 1.0;
const float RENDER_START_MULT        = 0.5;
const float RENDER_END_MULT          = 1.00;

// --- CONFIGURACIÓN DE TINTE ---
const vec3 FOG_TINT = vec3(0.8, 1.0, 1.2); 
const float FOG_TINT_INTENSITY = 0.6; // Reducido un poco para mayor suavidad

float get_fog_value(float dist, float start, float end) {
    if (dist <= start) return 0.0;
    if (dist >= end) return 1.0;
    // Interpolación cúbica para un desvanecimiento perfecto
    float v = (dist - start) / (end - start);
    return v * v * (3.0 - 2.0 * v);
}

vec4 linear_fog(vec4 inColor, float vertexDistance, float fogStart, float fogEnd, vec4 fogColor) {
    
    // 1. CÁLCULO DE NIEBLA UNIFICADA
    // Al usar los mismos multiplicadores de inicio, eliminamos el escalonamiento de colores
    float envStart = (fogStart * ENVIRONMENTAL_START_MULT) * (1.5 / ENVIRONMENTAL_DENSITY);
    float envEnd   = (fogEnd * ENVIRONMENTAL_END_MULT) / ENVIRONMENTAL_DENSITY;
    float envFog   = get_fog_value(vertexDistance, envStart, envEnd);

    float rendStart = (fogStart * RENDER_START_MULT) * (1.0 / RENDER_DENSITY);
    float rendEnd   = (fogEnd * RENDER_END_MULT) / RENDER_DENSITY;
    float rendFog   = get_fog_value(vertexDistance, rendStart, rendEnd);

    // Combinamos para obtener la curva más suave
    float fogValue = max(envFog, rendFog);

    // 2. DESVANECIMIENTO DE COLOR (Gradiente de 2 tonos)
    // El tinte se funde con el color original del cielo basado en la distancia total
    vec3 tintedFogColor = mix(fogColor.rgb, fogColor.rgb * FOG_TINT, FOG_TINT_INTENSITY);
    
    // Creamos un degradado suave entre el color tintado y el color base del cielo
    float colorTransition = smoothstep(fogStart * 0.5, fogEnd, vertexDistance);
    vec3 finalFogColor = mix(tintedFogColor, fogColor.rgb, colorTransition);

    // 3. MEZCLA FINAL CON EL MUNDO
    return vec4(mix(inColor.rgb, finalFogColor, fogValue * fogColor.a), inColor.a);
}

float linear_fog_fade(float vertexDistance, float fogStart, float fogEnd) {
    float envStart = (fogStart * ENVIRONMENTAL_START_MULT) * (1.5 / ENVIRONMENTAL_DENSITY);
    float envEnd   = (fogEnd * ENVIRONMENTAL_END_MULT) / ENVIRONMENTAL_DENSITY;
    float envFog   = get_fog_value(vertexDistance, envStart, envEnd);

    float rendStart = (fogStart * RENDER_START_MULT) * (1.0 / RENDER_DENSITY);
    float rendEnd   = (fogEnd * RENDER_END_MULT) / RENDER_DENSITY;
    float rendFog   = get_fog_value(vertexDistance, rendStart, rendEnd);

    return 1.0 - clamp(max(envFog, rendFog), 0.0, 1.0);
}

// by DR7 (Clean 2-Tone Gradient Version)
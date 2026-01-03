#version 120

uniform sampler2D DiffuseSampler;
varying vec2 texCoord;

// =========================================================================
//                       CONFIGURACIÓN DE CORRECCIÓN SELECTIVA
// =========================================================================

// Activar corrección de amarillos (Calabazas, Madera, Antorchas)
const bool FIX_SICKLY_YELLOWS = true;

// Qué tanto desaturar el amarillo (0.0 = Nada, 0.5 = Bastante grisáceo)
// 0.25 es ideal para quitar el efecto "radioactivo" sin dejarlo blanco.
const float YELLOW_DESATURATION = 0.45; 

// Qué tanto empujar el amarillo hacia el rojo/naranja.
// Esto convierte el tono "limón" en un tono "calidez/madera".
const float YELLOW_RED_SHIFT = 0.025; 

// Rango de detección (No tocar a menos que sepas de HSV)
const float YELLOW_HUE_CENTER = 0.14; // El centro del amarillo en HSV
const float YELLOW_HUE_WIDTH  = 0.07; // Qué tan amplio es el rango (agarra naranjas y amarillos)

// =========================================================================
//                       CONFIGURACIÓN GLOBAL ANTERIOR
// =========================================================================
const float VIBRANCE_AMOUNT = 0.0; // Subí un poco para compensar la corrección
const float CONTRAST_AMOUNT = 1.00; 
const float BRIGHT_SAT_BOOST = 0.05; 
const float BRIGHT_REDUCTION = 1.0; 
const float BRIGHTNESS_MULT  = 1.0; 

const float TONE_SHADOW = 1.2; 
const float TONE_MID    = 1; 
const float TONE_HIGH   = 0.8; 

const float SAT_SHADOW = 0.5; 
const float SAT_MID    = 0.8; 
const float SAT_HIGH   = 4.0; 

const float DETAIL_SHADOW = 0.10; 
const float DETAIL_MID    = 0.70; 
const float DETAIL_HIGH   = 0.90; 

// Balance RGB Global (Mantenemos el ajuste cálido anterior)
const vec3 RGB_HIGHLIGHTS = vec3(1.02, 0.96, 1.01);
const vec3 RGB_SHADOWS    = vec3(1.00, 0.98, 1.02);

// =========================================================================
//                              FUNCIONES
// =========================================================================

float getLuma(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// --- CONVERSIÓN RGB <-> HSV ---
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// --- FUNCIÓN CORRECTORA DE AMARILLOS ---
vec3 fixYellowArtifacts(vec3 color) {
    vec3 hsv = rgb2hsv(color);
    
    // Calculamos qué tan cerca está el píxel del tono amarillo problemático
    float dist = abs(hsv.x - YELLOW_HUE_CENTER);
    
    // Creamos una máscara suave: 1.0 si es amarillo, 0.0 si es verde o rojo
    float mask = 1.0 - smoothstep(0.0, YELLOW_HUE_WIDTH, dist);
    
    // Solo aplicamos si hay suficiente saturación (para no teñir grises)
    mask *= smoothstep(0.1, 0.3, hsv.y);

    if (mask > 0.0) {
        // 1. Reducir saturación del amarillo (quita el efecto neón)
        hsv.y -= (YELLOW_DESATURATION * mask * hsv.y);
        
        // 2. Mover el tono hacia el rojo (baja el valor del Hue)
        // Esto convierte el amarillo-verdoso en naranja-madera
        hsv.x -= (YELLOW_RED_SHIFT * mask);
    }
    
    return hsv2rgb(hsv);
}

// --- FUNCIONES RESTANTES (Ya optimizadas) ---
vec3 applyRGBBalance(vec3 color, float luma) {
    float shadowMask = 1.0 - smoothstep(0.0, 0.6, luma);
    float highlightMask = smoothstep(0.4, 1.0, luma);
    vec3 shadowColor = color * RGB_SHADOWS;
    vec3 highlightColor = color * RGB_HIGHLIGHTS;
    vec3 result = color;
    result = mix(result, shadowColor, shadowMask);
    result = mix(result, highlightColor, highlightMask);
    return result;
}

vec3 applyTextureOverlay(vec3 processedColor, vec3 originalColor, float strength) {
    float originalLuma = getLuma(originalColor);
    vec3 multiply = processedColor * originalColor * 2.0; 
    vec3 screen = 1.0 - 2.0 * (1.0 - processedColor) * (1.0 - originalColor);
    float lumaStep = step(0.5, originalLuma);
    vec3 overlayClassic = mix(multiply, screen, lumaStep);
    float brightnessDampener = smoothstep(0.5, 1.0, originalLuma);
    vec3 smartDetail = mix(overlayClassic, multiply, brightnessDampener * 0.8); 
    return mix(processedColor, smartDetail, strength);
}

vec3 adjustTonality(vec3 color, float luma) {
    float shadowFactor = 1.0 - smoothstep(0.0, 0.5, luma);
    float highlightFactor = smoothstep(0.5, 1.0, luma);
    float midtoneFactor = 1.0 - shadowFactor - highlightFactor;
    vec3 shadowColor    = color * TONE_SHADOW;
    vec3 midtoneColor   = color * TONE_MID;
    vec3 highlightColor = color * TONE_HIGH;
    return (shadowColor * shadowFactor) + (midtoneColor * midtoneFactor) + (highlightColor * highlightFactor);
}

vec3 adjustZoneSaturation(vec3 color, float luma) {
    float shadowFactor = 1.0 - smoothstep(0.0, 0.5, luma);
    float highlightFactor = smoothstep(0.5, 1.0, luma);
    float midtoneFactor = 1.0 - shadowFactor - highlightFactor;
    float targetSat = (SAT_SHADOW * shadowFactor) + (SAT_MID * midtoneFactor) + (SAT_HIGH * highlightFactor);
    return mix(vec3(luma), color, targetSat);
}

float getDetailStrength(float luma) {
    float shadowFactor = 1.0 - smoothstep(0.0, 0.5, luma);
    float highlightFactor = smoothstep(0.5, 1.0, luma);
    float midtoneFactor = 1.0 - shadowFactor - highlightFactor;
    return (DETAIL_SHADOW * shadowFactor) + (DETAIL_MID * midtoneFactor) + (DETAIL_HIGH * highlightFactor);
}

vec3 adjustVibrance(vec3 color, float amount) {
    float luma = getLuma(color);
    float maxColor = max(color.r, max(color.g, color.b));
    float saturation = maxColor - luma;
    return mix(vec3(luma), color, 1.0 + (amount * (1.0 - saturation)));
}

vec3 handleHighLights(vec3 color) {
    float luma = dot(color, vec3(0.333)); 
    float highlightMask = smoothstep(0.6, 1.0, luma);
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 saturated = mix(vec3(gray), color, 1.0 + BRIGHT_SAT_BOOST);
    vec3 reducedBright = saturated * BRIGHT_REDUCTION;
    return mix(color, reducedBright, highlightMask);
}

// =========================================================================
//                                  MAIN
// =========================================================================

void main() {
    vec4 texData = texture2D(DiffuseSampler, texCoord);
    vec3 originalColor = texData.rgb;
    vec3 color = originalColor;

    // 1. --- CORRECCIÓN QUIRÚRGICA DE AMARILLOS ---
    // Aplicamos esto PRIMERO para limpiar la base antes de darle contraste
    if (FIX_SICKLY_YELLOWS) {
        color = fixYellowArtifacts(color);
    }

    color *= BRIGHTNESS_MULT;
    float currentLuma = getLuma(color);
    
    color = adjustTonality(color, currentLuma);
    currentLuma = getLuma(color); 
    color = adjustZoneSaturation(color, currentLuma);

    currentLuma = getLuma(color);
    color = applyRGBBalance(color, currentLuma);

    color = (color - 0.5) * CONTRAST_AMOUNT + 0.5;

    color = handleHighLights(color);
    color = adjustVibrance(color, VIBRANCE_AMOUNT);

    currentLuma = getLuma(color);
    float zoneDetail = getDetailStrength(currentLuma);
    
    // Usamos el color original limpio si es posible, o el procesado
    color = applyTextureOverlay(color, originalColor, zoneDetail);

    gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
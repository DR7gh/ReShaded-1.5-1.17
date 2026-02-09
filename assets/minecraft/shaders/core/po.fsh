#version 150

#moj_import <fog.glsl>

uniform vec4 ColorModulator;
uniform float GameTime;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;
uniform mat4 ModelViewMat;
uniform mat4 ProjMat;
uniform vec2 ScreenSize;

in float vertexDistance;
in vec4 rawPos;

out vec4 fragColor;

// =========================================================================
//                        CONTROL DE COLORES (TU PALETA)
// =========================================================================

// --- FASE 1: MEDIODÍA (Ticks ~6000) ---
const vec3 DAY_SKY      = vec3(0.6, 0.74, 1.0);   
const vec3 DAY_CLOUD    = vec3(0.2); // Subí el brillo para que no se vean grises
const vec3 DAY_FOG      = vec3(0.75, 0.80, 1.0);    

// --- FASE 2: GOLDEN HOUR (Atardecer/Amanecer) ---
const vec3 SUNSET_SKY   = vec3(0.612, 0.612, 0.612);    
const vec3 SUNSET_CLOUD = vec3(0.2); // Ajusté un poco a tono cálido
const vec3 SUNSET_FOG   = vec3(1.0, 0.9, 0.8); // Blanco cálido (no 100% blanco puro)

// --- FASE 3: MEDIANOCHE (Ticks ~18000) ---
const vec3 NIGHT_SKY    = vec3(0.045, 0.04, 0.065); 
const vec3 NIGHT_CLOUD_A= vec3(12, 12, 12)/255.0; 
const vec3 NIGHT_CLOUD_B= vec3(21, 21, 21)/255.0; 
const vec3 NIGHT_FOG    = vec3(0.045, 0.045, 0.085); 

// --- CONFIGURACIÓN TÉCNICA ---
// IMPORTANTE: Ya no usamos FOG_HEIGHT estricto para evitar el corte.
// Usaremos una curva de caída (Falloff). Cuanto mayor el número, más corta la niebla.
const float FOG_FALLOFF = 1.5; 
const float FOG_DENSITY = 1.0; 


float snoise(vec3 P) {
	const float SKEWFACTOR = 1.0/3.0;
	const float UNSKEWFACTOR = 1.0/6.0;
	const float SIMPLEX_CORNER_POS = 0.5;
	const float SIMPLEX_TETRAHADRON_HEIGHT = 0.70710678118654752440084436210485;

	P *= SIMPLEX_TETRAHADRON_HEIGHT;
	vec3 Pi = floor( P + dot( P, vec3( SKEWFACTOR) ) );

	vec3 x0 = P - Pi + dot(Pi, vec3( UNSKEWFACTOR ) );
	vec3 g = step(x0.yzx, x0.xyz);
	vec3 l = 1.0 - g;
	vec3 Pi_1 = min( g.xyz, l.zxy );
	vec3 Pi_2 = max( g.xyz, l.zxy );
	vec3 x1 = x0 - Pi_1 + UNSKEWFACTOR;
	vec3 x2 = x0 - Pi_2 + SKEWFACTOR;
	vec3 x3 = x0 - SIMPLEX_CORNER_POS;

	vec4 v1234_x = vec4( x0.x, x1.x, x2.x, x3.x );
	vec4 v1234_y = vec4( x0.y, x1.y, x2.y, x3.y );
	vec4 v1234_z = vec4( x0.z, x1.z, x2.z, x3.z );

	Pi.xyz = Pi.xyz - floor(Pi.xyz * ( 1.0 / 69.0 )) * 69.0;
	vec3 Pi_inc1 = step( Pi, vec3( 69.0 - 1.5 ) ) * ( Pi + 1.0 );

	vec4 Pt = vec4( Pi.xy, Pi_inc1.xy ) + vec2( 50.0, 161.0 ).xyxy;
	Pt *= Pt;
	vec4 V1xy_V2xy = mix( Pt.xyxy, Pt.zwzw, vec4( Pi_1.xy, Pi_2.xy ) );
	Pt = vec4( Pt.x, V1xy_V2xy.xz, Pt.z ) * vec4( Pt.y, V1xy_V2xy.yw, Pt.w );
	const vec3 SOMELARGEFLOATS = vec3( 635.298681, 682.357502, 668.926525 );
	const vec3 ZINC = vec3( 48.500388, 65.294118, 63.934599 );
	vec3 lowz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + Pi.zzz * ZINC.xyz ) );
	vec3 highz_mods = vec3( 1.0 / ( SOMELARGEFLOATS.xyz + Pi_inc1.zzz * ZINC.xyz ) );
	Pi_1 = ( Pi_1.z < 0.5 ) ? lowz_mods : highz_mods;
	Pi_2 = ( Pi_2.z < 0.5 ) ? lowz_mods : highz_mods;
	vec4 hash_0 = fract( Pt * vec4( lowz_mods.x, Pi_1.x, Pi_2.x, highz_mods.x ) ) - 0.49999;
	vec4 hash_1 = fract( Pt * vec4( lowz_mods.y, Pi_1.y, Pi_2.y, highz_mods.y ) ) - 0.49999;
	vec4 hash_2 = fract( Pt * vec4( lowz_mods.z, Pi_1.z, Pi_2.z, highz_mods.z ) ) - 0.49999;

	vec4 grad_results = inversesqrt( hash_0 * hash_0 + hash_1 * hash_1 + hash_2 * hash_2 ) * ( hash_0 * v1234_x + hash_1 * v1234_y + hash_2 * v1234_z );
	const float FINAL_NORMALIZATION = 37.837227241611314102871574478976;
	vec4 kernel_weights = v1234_x * v1234_x + v1234_y * v1234_y + v1234_z * v1234_z;
	kernel_weights = max(0.5 - kernel_weights, 0.0);
	kernel_weights = kernel_weights*kernel_weights*kernel_weights;

	return dot( kernel_weights, grad_results ) * FINAL_NORMALIZATION;
}

float fbm(vec3 x) {
    const int octaves = 4;
	float lacunarity = 2.5;
	float gain = 0.5;
	float amplitude = 0.5;
	float frequency = 1.;
	float y = 0.0;
	for (int i = 0; i < octaves; i++) {
		y += amplitude * snoise(frequency*x);
		frequency *= lacunarity;
		amplitude *= gain;
	}
	return y;
}

// --- GENERADOR DE CIELO ---
vec3 sampleSky(vec3 v, float wDay, float wSunset, float wNight) {
    
    // 1. GENERACIÓN DE NUBES Y ESTRELLAS
	float starNoise = snoise(v * 100.0 + GameTime * 100.0);
	float stars = max(0.0, starNoise - 0.7) * 5.0;
	float starfield = max(0.05, snoise(v * vec3(1.0, 1.0, 0.5) + GameTime * 100.0));
	
    float starVisibility = wNight + (wSunset * 0.2); 
	stars *= starfield * starVisibility; 
    float backgroundStars = starfield * 0.1 * starVisibility;

    // Nubes
	float res = fbm(v * 2.0 + vec3(GameTime * 10.0, 0.0, 0.0));
	float cloud1Shape = max(0.0, res + 0.1);
	float res2 = fbm(v * 2.5 + vec3(0.0, GameTime * 10.0, 0.0) + vec3(10.4, 0.0, 0.0));
	float cloud2Shape = max(0.0, res2 + 0.15);

    // 2. MEZCLA DE COLORES
    vec3 currentSky = (DAY_SKY * wDay) + (SUNSET_SKY * wSunset) + (NIGHT_SKY * wNight);
    vec3 currentFog = (DAY_FOG * wDay) + (SUNSET_FOG * wSunset) + (NIGHT_FOG * wNight);
    
    vec3 cloud1Tint = (DAY_CLOUD * wDay) + (SUNSET_CLOUD * wSunset) + (NIGHT_CLOUD_A * wNight);
    vec3 cloud2Tint = (DAY_CLOUD * wDay * 0.9) + (SUNSET_CLOUD * wSunset * 0.8) + (NIGHT_CLOUD_B * wNight);

    vec3 sky = currentSky;
    sky += cloud1Shape * cloud1Tint;
    sky += cloud2Shape * cloud2Tint;
	sky += stars;
	sky += backgroundStars;

    // 3. FIX DE HORIZONTE (CURVA EXPONENCIAL)
    // En lugar de cortar abruptamente, usamos una curva suave.
    // 'v.y' va de -1 a 1. Hacemos clamp a 0-1 para solo afectar arriba.
    float height = clamp(v.y, 0.0, 1.0);
    
    // Fórmula Mágica: pow(1.0 - height, FOG_FALLOFF)
    // Esto crea un degradado perfecto que sube alto pero se desvanece suavemente.
    float horizonIntensity = pow(1.0 - height, FOG_FALLOFF);
    
    // Mezcla final
    sky = mix(sky, currentFog, horizonIntensity * FOG_DENSITY);

	// Dithering
	float grid_position = fract(dot(gl_FragCoord.xy - vec2(0.5,0.5), vec2(1.0/16.0,10.0/36.0)+0.25));
	float dither = grid_position / 256.0;

	sky += dither;

	return sky;
}

void main() {
    // --- LÓGICA DE DURACIÓN EXTENDIDA ---
    float brightness = length(ColorModulator.rgb);

    // ANTES: Day terminaba en 0.8 y Night empezaba en 0.6. (Gap muy corto)
    // AHORA: Ampliamos el rango medio para que el atardecer dure mucho más.

    // 1. DÍA: Se apaga antes (al llegar a brillo 1.1 empieza a bajar)
    // Termina totalmente en 0.55.
    float wDay = smoothstep(0.55, 1.1, brightness);
    
    // 2. NOCHE: Tarda mucho más en empezar.
    // Solo empieza a aparecer cuando el brillo baja de 0.4.
    float wNight = 1.0 - smoothstep(0.15, 0.4, brightness);
    
    // 3. ATARDECER: Rellena el hueco enorme entre 0.15 y 0.55
    float wSunset = 1.0 - wDay - wNight;
    wSunset = max(0.0, wSunset); 

	vec2 pos = gl_FragCoord.xy / ScreenSize;
	pos -= vec2(0.5, 0.5);
	pos *= 2.0;

	vec4 cast_pos = vec4(pos, 1.0, 1.0);
	cast_pos = inverse(ProjMat) * cast_pos;
	cast_pos = normalize(cast_pos);

	vec3 v = normalize(cast_pos.xyz * mat3(ModelViewMat));

	fragColor = vec4(sampleSky(v, wDay, wSunset, wNight), 1.0);
}
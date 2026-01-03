#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;
uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec4 vertexColor;
in vec4 lightMapColor;
in vec4 overlayColor;
in vec2 texCoord0;

out vec4 fragColor;

const float SATURATION_STRENGTH = 1.0;

// PLAYER 1ST LAYER HAND

vec3 applyVibrance(vec3 color, float vibranceStrength) {
    float luminance = dot(color, vec3(0.3));
    float saturation = max(max(color.r, color.g), color.b) - min(min(color.r, color.g), color.b);
    return mix(vec3(luminance), color, 1.0 + (1.0 - saturation) * vibranceStrength);
}

vec3 adjustPixelLuminanceGradient(vec3 color) {
    float brightness = dot(color, vec3(0.333));
    float boost = mix(1.0, 2.0, 1.0 - smoothstep(0.0, 0.65, abs(brightness - 0.325)));
    return clamp(color * boost, 0.0, 1.0);
}

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    color *= lightMapColor;

    color.rgb *= 0.65;
    color.rgb = applyVibrance(color.rgb, 0.4 * SATURATION_STRENGTH);

    float vertexBrightness = max(max(vertexColor.r, vertexColor.g), vertexColor.b);
    if (vertexBrightness <= 0.6420) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6380) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6340) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6300) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6260) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6220) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6180) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6140) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6100) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }
    if (vertexBrightness <= 0.6060) { color.rgb *= vec3(0.9478, 0.9743, 1.0085); }

    if (vertexBrightness <= 0.1960) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.1975) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.1990) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2005) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2020) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2025) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2040) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2055) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2070) { color.rgb *= vec3(0.96473); }
    if (vertexBrightness <= 0.2085) { color.rgb *= vec3(0.96473); }

    if (vertexBrightness <= 0.2)  { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.18) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.16) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.14) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.12) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.10) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.08) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.06) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.04) { color.rgb *= vec3(1.063); }
    if (vertexBrightness <= 0.02) { color.rgb *= vec3(1.063); }

    color.rgb = adjustPixelLuminanceGradient(color.rgb);

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}
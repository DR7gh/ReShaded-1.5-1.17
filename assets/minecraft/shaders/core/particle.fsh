#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in float vertexDistance;
in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;

vec3 increaseSaturation(vec3 color, float factor) {
    float gray = dot(color, vec3(0.299, 0.587, 0.114));
    return mix(vec3(gray), color, 1.0 + factor);
}

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }

    color.rgb *= 1.3;

    color.rgb = increaseSaturation(color.rgb, 0.3);

    float vertexBrightness = max(max(vertexColor.r, vertexColor.g), vertexColor.b);
    if (vertexBrightness <= 0.6420) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6380) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6340) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6300) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6260) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6220) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6180) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6140) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6100) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.6060) {
        color.rgb *= vec3(0.96844, 0.97131, 1.00486);
    }
    if (vertexBrightness <= 0.1960) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.1975) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.1990) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.2005) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.2020) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.2025) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.2040) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.2055) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.2070) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }
    if (vertexBrightness <= 0.2085) { 
       color.rgb *= vec3(0.976, 0.976, 0.986); }

    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}

// by DR7 https://modrinth.com/user/DR7
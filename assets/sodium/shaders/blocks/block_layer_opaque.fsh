#version 330 core

#import <sodium:include/fog.glsl>

in vec4 v_Color; 
in vec2 v_TexCoord; 
in float v_FragDistance; 

in float v_MaterialMipBias;
in float v_MaterialAlphaCutoff;

uniform sampler2D u_BlockTex; // The block texture

uniform vec4 u_FogColor; 
uniform float u_FogStart; 
uniform float u_FogEnd; 

out vec4 fragColor; 

vec3 increaseSaturation(vec3 color, float factor) {
    float gray = (color.r + color.g + color.b) / 3.0;
    return clamp(gray + (color - vec3(gray)) * factor, 0.0, 1.0);
}

void main() {
    vec4 diffuseColor = texture(u_BlockTex, v_TexCoord, v_MaterialMipBias);

    diffuseColor *= v_Color;

#ifdef USE_FRAGMENT_DISCARD
    if (diffuseColor.a < v_MaterialAlphaCutoff) {
        discard;
    }
#endif

    float vertexBrightness = max(max(v_Color.r, v_Color.g), v_Color.b);

    if (vertexBrightness <= 0.6420) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6380) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6340) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6300) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6260) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6220) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6180) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6140) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6100) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.6060) {
        diffuseColor.rgb *= vec3(0.96511, 0.97798, 1.00153);
    }
    if (vertexBrightness <= 0.1960) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.1975) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.1990) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.2005) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.2020) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.2025) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.2040) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.2055) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.2070) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }
    if (vertexBrightness <= 0.2085) { 
       diffuseColor.rgb *= vec3(0.966, 0.966, 0.976); }

    diffuseColor.rgb *= 1.3;

    diffuseColor.rgb = increaseSaturation(diffuseColor.rgb, 1.3);

    fragColor = _linearFog(diffuseColor, v_FragDistance, u_FogColor, u_FogStart, u_FogEnd);
}

// by DR7 https://modrinth.com/user/DR7

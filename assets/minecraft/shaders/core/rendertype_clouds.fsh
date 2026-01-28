#version 150

#moj_import <fog.glsl>

uniform sampler2D Sampler0;

uniform vec4 ColorModulator;
uniform float FogStart;
uniform float FogEnd;
uniform vec4 FogColor;

in vec2 texCoord0;
in float vertexDistance;
in vec4 vertexColor;

out vec4 fragColor;

void main() {
    vec4 color = texture(Sampler0, texCoord0) * vertexColor * ColorModulator;
    if (color.a < 0.1) {
        discard;
    }
        float brightness = (color.r + color.g + color.b) / 3.0;
    if (brightness < 0.8) {
        color.rgb *= vec3(0.85,0.9,1.3);
    }
    if (brightness < 1) {
        color.rgb *= vec3(1.3);
    }
    fragColor = linear_fog(color, vertexDistance, FogStart, FogEnd, FogColor);
}

// by DR7 https://modrinth.com/user/DR7
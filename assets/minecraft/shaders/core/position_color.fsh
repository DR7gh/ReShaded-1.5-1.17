#version 150

in vec4 vertexColor;

uniform vec4 ColorModulator;

out vec4 fragColor;

void main() {
    vec4 color = vertexColor;

    if (color.a == 0.0) {
        discard;
    }

    color.rgb *= 1.5;

    fragColor = color * ColorModulator;
}

// by DR7 https://modrinth.com/user/DR7
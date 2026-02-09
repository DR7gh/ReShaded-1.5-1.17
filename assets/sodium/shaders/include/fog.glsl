const int FOG_SHAPE_SPHERICAL = 0;
const int FOG_SHAPE_CYLINDRICAL = 1;

vec4 _linearFog(vec4 fragColor, float fragDistance, vec4 fogColor, float fogStart, float fogEnd) {
#ifdef USE_FOG
    float fogDensityStartMult1 = -0.2;
    float fogDensityEndMult1   = 2.0;

    float denseStart1 = fogStart * fogDensityStartMult1;
    float denseEnd1   = fogEnd   * fogDensityEndMult1;

    float factor1 = 0.0;
    if (fragDistance > denseStart1) {
        factor1 = fragDistance < denseEnd1 ? smoothstep(denseStart1, denseEnd1, fragDistance) : 1.0;
    }

    float fogDensityStartMult2 = 0.96;
    float fogDensityEndMult2   = 1.0;

    float denseStart2 = fogStart * fogDensityStartMult2;
    float denseEnd2   = fogEnd   * fogDensityEndMult2;

    float factor2 = 0.0;
    if (fragDistance > denseStart2) {
        factor2 = fragDistance < denseEnd2 ? smoothstep(denseStart2, denseEnd2, fragDistance) : 1.0;
    }

    float factor = clamp((factor1 * 0.6) + (factor2 * 0.4), 0.0, 1.0);

    float blueFactor = smoothstep(fogStart, fogEnd * 0.901, fragDistance);
    vec3 blueTint = mix(vec3(1.0), vec3(0.9, 1.0, 1.2), blueFactor * 0.25);

    vec3 blended = mix(fragColor.rgb, fogColor.rgb, factor * fogColor.a);
    blended *= blueTint;

    return vec4(blended, fragColor.a);
#else
    return fragColor;
#endif
}

float getFragDistance(int fogShape, vec3 position) {
    switch (fogShape) {
        case FOG_SHAPE_SPHERICAL:
            return length(position);
        case FOG_SHAPE_CYLINDRICAL:
            return max(length(position.xz), abs(position.y));
        default:
            return length(position);
    }
}

// by DR7 https://modrinth.com/user/DR7
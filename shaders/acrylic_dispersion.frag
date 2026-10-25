#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform vec4 uTint;
uniform float uRefraction;
uniform float uDispersion;
uniform vec2 uLightDir;

out vec4 fragColor;

float sdRoundedBox(vec2 p, vec2 b, vec4 r) {
    r.xy = (p.x > 0.0) ? r.xy : r.zw;
    r.x  = (p.y > 0.0) ? r.x  : r.y;
    vec2 q = abs(p) - b + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uResolution;
    vec2 p = FlutterFragCoord().xy - uResolution * 0.5;
    
    vec2 halfSize = uResolution * 0.44;
    float radius = uResolution.x * 0.18;
    
    float dist = sdRoundedBox(p, halfSize, vec4(radius));
    
    vec2 eps = vec2(1.5, 0.0);
    vec2 norm = normalize(vec2(
        sdRoundedBox(p + eps.xy, halfSize, vec4(radius)) - sdRoundedBox(p - eps.xy, halfSize, vec4(radius)),
        sdRoundedBox(p + eps.yx, halfSize, vec4(radius)) - sdRoundedBox(p - eps.yx, halfSize, vec4(radius))
    ));
    
    float alphaMask = clamp(-dist, 0.0, 1.0);
    if (alphaMask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    
    // Fresnel grazing-angle rim caustics
    float edgeFactor = clamp(-dist / 16.0, 0.0, 1.0);
    float rim = pow(1.0 - edgeFactor, 2.5);
    
    // Directional specular highlight
    float spec = max(0.0, dot(norm, normalize(uLightDir)));
    float specular = pow(spec, 24.0) * (1.0 - edgeFactor);
    
    // Restrained platinum / cyber-slate palette
    vec3 baseCol = uTint.rgb;
    vec3 causticCol = vec3(0.72, 0.74, 0.77); // Platinum Silver
    vec3 highlightCol = vec3(0.96, 0.98, 1.0); // Pure White Specular
    
    vec3 finalCol = mix(baseCol, causticCol, rim * 0.85);
    finalCol += highlightCol * specular * 1.3;
    
    float outAlpha = alphaMask * uTint.a;
    fragColor = vec4(finalCol * outAlpha, outAlpha);
}

shader_type sky;

uniform float time_of_day : hint_range(0.0, 1.0) = 0.0;

// Colors
uniform vec3 deep_night_color : source_color = vec3(0.02, 0.03, 0.08);
uniform vec3 dawn_color       : source_color = vec3(0.45, 0.25, 0.35);
uniform vec3 day_color        : source_color = vec3(0.55, 0.75, 1.00);
uniform vec3 dusk_color       : source_color = vec3(0.65, 0.35, 0.17);
uniform vec3 night_color      : source_color = vec3(0.02, 0.03, 0.08);

// Stars
uniform float star_intensity : hint_range(0.0, 4.0) = 1.5;
uniform float star_density   : hint_range(50.0, 2000.0) = 800.0;


// Helpers
float phase(float t, float a, float b) {
    return smoothstep(a, b, t);
}

float hash(vec2 p) {
    p = fract(p * 0.3183099 + vec2(0.1, 0.2));
    p *= 17.0;
    return fract(p.x * p.y * (p.x + p.y));
}

void sky() {
    float t = time_of_day;

    // Blending phases
    float dawn  = phase(t, 0.10, 0.20);
    float dayv  = phase(t, 0.20, 0.50);
    float dusk  = phase(t, 0.50, 0.70);
    float night = phase(t, 0.70, 0.90);
    float deep  = phase(t, 0.90, 1.00);

    // Base color
    vec3 col = deep_night_color;

    col = mix(col, dawn_color, dawn);
    col = mix(col, day_color, dayv);
    col = mix(col, dusk_color, dusk);
    col = mix(col, night_color, night);
    col = mix(col, deep_night_color, deep); // Loop back cleanly

    // Night factor for stars
    float night_factor = smoothstep(0.2, 0.55, 1.0 - dayv);

    // Stars
    vec2 uv = SKY_COORDS * star_density;
    float s = hash(uv);

    float star = smoothstep(0.985, 1.0, s) * night_factor * star_intensity;

    col += vec3(star);

    COLOR = col;
}

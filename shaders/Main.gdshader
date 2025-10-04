shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.15, 0.25, 0.5, 0.6);
uniform vec4 color2 : source_color = vec4(0.2, 0.3, 0.6, 0.7);
uniform vec4 color3 : source_color = vec4(0.25, 0.35, 0.45, 0.65);
uniform float speed = 0.5;
uniform float scale = 3.5;
uniform float distortion = 0.5;
uniform float glow_intensity = 0.6;

float fbm(vec2 p, float time) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for(int i = 0; i < 4; i++) {
        value += amplitude * sin(p.x * frequency + time) * cos(p.y * frequency - time * 0.7);
        p *= 2.0;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

vec2 pulse_wave(vec2 uv, float time) {
    vec2 center = vec2(0.5);
    vec2 delta = uv - center;
    float dist = length(delta);

    float wave = sin(dist * 6.0 - time * speed * 2.0) * distortion;
    wave += cos(dist * 3.0 + time * speed * 1.5) * distortion * 0.5;

    float pulse = sin(time * speed * 1.5) * 0.3 + 0.7;
    return uv + delta * wave * pulse * 0.2;
}

void fragment() {
    vec2 uv = UV;

    vec2 pulsed_uv = pulse_wave(uv, TIME * speed);
    pulsed_uv *= scale;

    float plasma = 0.0;
    plasma += sin(pulsed_uv.x * 2.5 + TIME * speed * 1.5);
    plasma += sin(pulsed_uv.y * 2.0 - TIME * speed * 1.2);
    plasma += sin((pulsed_uv.x + pulsed_uv.y) * 1.8 + TIME * speed * 1.8);
    plasma += cos((pulsed_uv.x - pulsed_uv.y) * 2.2 - TIME * speed);
    plasma *= 0.3;

    float noise_val = fbm(pulsed_uv + TIME * speed * 0.3, TIME * 1.5);

    vec2 center_uv = (UV - 2.5) * scale;
    float radial = length(center_uv);
    float rings = sin(radial * 4.0 - TIME * speed * 3.0) * 0.4;

    float combined = plasma + noise_val * 0.5 + rings;
    combined = combined * 0.8 + 0.5;

    float pulse = sin(TIME * speed * 1.8) * 0.5 + 0.5;
    float glow = pow(sin(pulsed_uv.x * 2.0 + TIME * speed * 1.3) *
                     cos(pulsed_uv.y * 1.8 - TIME * speed * 1.1), 2.0);
    glow *= glow_intensity * pulse * 1.5;

    float blend1 = smoothstep(0.25, 0.55, combined);
    float blend2 = smoothstep(0.55, 0.85, combined);

    vec4 blue_boost = color1;
    blue_boost.b *= 1.3;
    blue_boost.a *= 3.0;

    vec4 final_color = mix(blue_boost, color2, blend1);
    final_color = mix(final_color, color3, blend2);

    final_color.rgb += vec3(glow * 0.3, glow * 0.5, glow * 1.2);

    final_color.a *= 0.9 + combined * 0.1;

    COLOR = final_color;
}
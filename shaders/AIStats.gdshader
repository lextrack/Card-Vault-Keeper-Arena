shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.4, 0.05, 0.05, 1.0);
uniform vec4 glow_color : source_color = vec4(0.1, 0.2, 0.1, 1.0); 
uniform float speed = 0.3;
uniform float frequency = 15.0;
uniform float glow_strength = 0.5;

void fragment() {
    vec2 uv = UV;
    float wave = sin((uv.x + TIME * speed) * frequency) * 0.2 + 0.1;
    vec4 final_color = mix(base_color, glow_color, wave * glow_strength);
    COLOR = final_color;
}

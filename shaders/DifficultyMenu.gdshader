shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.5, 0.15, 0.25, 0.6);
uniform vec4 color2 : source_color = vec4(0.2, 0.3, 0.6, 0.7);
uniform float speed = 1.3; 
uniform float scale = 5.0; 

void fragment() {
    vec2 uv = UV * scale;
    uv.x += TIME * speed;
    float gradient = 1.0 + 0.8 * sin(uv.x + uv.y);
    vec4 final_color = mix(color1, color2, gradient);

    COLOR = final_color;
}
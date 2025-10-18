shader_type canvas_item;

uniform float shine_speed : hint_range(0.1, 5.0) = 2.5;
uniform float shine_width : hint_range(0.05, 0.5) = 0.1;
uniform float shine_intensity : hint_range(0.0, 2.0) = 0.7;
uniform vec4 shine_color : source_color = vec4(1.0, 0.9, 0.3, 0.5);
uniform float shine_angle_rad = 0.785398;
uniform bool shine_enabled = false;
uniform float delay_between_shines : hint_range(0.5, 10.0) = 0.8;
uniform float time_offset = 0.0;

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    float shine_amount = 0.0;
    
    if (shine_enabled) {
        float adjusted_time = TIME + time_offset;
        float cycle_duration = delay_between_shines + (1.0 / shine_speed);
        float t = mod(adjusted_time, cycle_duration);
        
        if (t < (1.0 / shine_speed)) {
            float cos_angle = cos(shine_angle_rad);
            float sin_angle = sin(shine_angle_rad);
            
            float rotated_pos = UV.x * cos_angle + UV.y * sin_angle;
            float shine_pos = (t * shine_speed) * (1.0 + shine_width * 2.0) - shine_width;
            float distance_to_shine = abs(rotated_pos - shine_pos);
            
            shine_amount = smoothstep(shine_width, 0.0, distance_to_shine) * shine_intensity;
        }
    }
    
    vec3 final_color = mix(original_color.rgb, shine_color.rgb, shine_amount * shine_color.a);
    COLOR = vec4(final_color, original_color.a);
}
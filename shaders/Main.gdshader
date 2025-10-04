shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.15, 0.25, 0.5, 0.6); // Azul base
uniform vec4 color2 : source_color = vec4(0.2, 0.3, 0.6, 0.7);   // Color resaltado
uniform vec4 color3 : source_color = vec4(0.25, 0.35, 0.45, 0.65); // Color intermedio
uniform float speed = 0.4;
uniform float scale = 3.5;
uniform float distortion = 0.5;
uniform float glow_intensity = 0.6;

// Función de ruido fractal
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

// Efecto de remolino más fuerte
vec2 swirl(vec2 uv, float time) {
    vec2 center = vec2(0.5);
    vec2 delta = uv - center;
    float dist = length(delta);
    float angle = atan(delta.y, delta.x);
    
    // Remolino más pronunciado con múltiples ondas
    angle += sin(time * 0.8 + dist * 8.0) * distortion;
    angle += cos(time * 0.5 + dist * 4.0) * distortion * 0.5;
    
    return center + vec2(cos(angle), sin(angle)) * dist;
}

void fragment() {
    vec2 uv = UV;
    
    // Aplicar remolino más intenso
    vec2 swirled_uv = swirl(uv, TIME * speed);
    swirled_uv *= scale;
    
    // Efecto plasma más pronunciado
    float plasma = 0.0;
    plasma += sin(swirled_uv.x * 2.5 + TIME * speed * 1.5);
    plasma += sin(swirled_uv.y * 2.0 - TIME * speed * 1.2);
    plasma += sin((swirled_uv.x + swirled_uv.y) * 1.8 + TIME * speed * 1.8);
    plasma += cos((swirled_uv.x - swirled_uv.y) * 2.2 - TIME * speed);
    plasma *= 0.3;
    
    // Ruido fractal para textura
    float noise_val = fbm(swirled_uv + TIME * speed * 0.3, TIME * 1.5);
    
    // Ondas circulares más marcadas desde el centro
    vec2 center_uv = (UV - 0.5) * scale;
    float radial = length(center_uv);
    float rings = sin(radial * 4.0 - TIME * speed * 3.0) * 0.4;
    
    // Combinar efectos con más peso
    float combined = plasma + noise_val * 0.5 + rings;
    combined = combined * 0.5 + 0.5;
    
    // Capa de brillo pulsante MÁS FUERTE
    float pulse = sin(TIME * speed * 2.0) * 0.5 + 0.5;
    float glow = pow(sin(swirled_uv.x * 2.0 + TIME * speed * 1.5) * 
                     cos(swirled_uv.y * 1.8 - TIME * speed * 1.2), 2.0);
    glow *= glow_intensity * pulse * 1.5;
    
    // Transición más dramática entre colores
    float blend1 = smoothstep(0.25, 0.55, combined);
    float blend2 = smoothstep(0.55, 0.85, combined);
    
    // Color azul más saturado y visible
    vec4 blue_boost = color1;
    blue_boost.b *= 1.3; // Más azul
    blue_boost.a *= 1.2; // Más opaco
    
    vec4 final_color = mix(blue_boost, color2, blend1);
    final_color = mix(final_color, color3, blend2);
    
    // Añadir brillo con tinte azulado (cian)
    final_color.rgb += vec3(glow * 0.3, glow * 0.5, glow * 1.2);
    
    // Variación de transparencia
    final_color.a *= 0.9 + combined * 0.1;
    
    COLOR = final_color;
}
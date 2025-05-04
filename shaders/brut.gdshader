shader_type canvas_item;

// Niveau de pixelisation (plus c’est haut, plus c’est grossier)
// 256 -> 32
uniform float pixel_size : hint_range(1.0,256.0) = 32.0;

// Seuil de contraste pour accentuer les transitions
uniform float contrast : hint_range(0.0, 2.0) = 0.5;

void fragment() {
    // Pixelation
    vec2 pixel_uv = floor(UV * pixel_size) / pixel_size;
    vec4 col = texture(TEXTURE, pixel_uv);

    // Transformation brutale des couleurs (pour casser les arrondis)
    col.rgb = pow(col.rgb, vec3(contrast));

    COLOR = col;
}

shader_type canvas_item;

uniform float pulse_speed : hint_range(0.1, 10.0) = 2.0;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.1;

void fragment() {
    // Calcul de l'effet de pulse avec sin
    float scale = 1.0 + sin(TIME * pulse_speed) * pulse_strength;

    // On recentre les UV autour du centre de l'image (0.5, 0.5)
    vec2 centered_uv = (UV - vec2(0.5)) / scale + vec2(0.5);

    // Rendu de la texture avec les UV modifiés
    COLOR = texture(TEXTURE, centered_uv);
}

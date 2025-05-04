shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0);

uniform float wave_amplitude = 0.015;
uniform float wave_frequency = 13.0;
uniform float wave_speed = 2.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.6, 1.0, 1.0);

uniform float wave2_amplitude = 0.025;
uniform float wave2_frequency = 7.0;
uniform float wave2_speed = 1.0;
uniform vec4 fill_color2 : source_color = vec4(0.1, 0.3, 0.8, 1.0);

void fragment() {
    vec2 uv = UV;

    // Première vague (devant)
    float wave1 = sin(uv.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
    float fill_limit1 = progress + wave1;

    // Deuxième vague (arrière-plan)
    float wave2 = sin(uv.x * wave2_frequency + TIME * wave2_speed) * wave2_amplitude;
    float fill_limit2 = progress + wave2;

    // Priorité : vague arrière puis vague avant
    if (uv.y >= (1.0 - fill_limit2)) {
        COLOR = fill_color2;
        COLOR.a = 1.0;
    }
    if (uv.y >= (1.0 - fill_limit1)) {
        COLOR = fill_color;
        COLOR.a = 1.0;
    } else if (uv.y < (1.0 - fill_limit2)) {
        discard; // complètement transparent en dehors de la seconde vague
    }
}

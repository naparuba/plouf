shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec2 uv = UV;

    // Vagues dynamiques basées sur le temps
    float wave = sin(uv.y * 20.0 + TIME * 3.0) * 0.01;
    wave += sin(uv.x * 40.0 + TIME * 2.0) * 0.01;

    uv.x += wave * strength;
    uv.y += wave * strength;

    // Décalage de couleurs (chromatic aberration)
    float offset = 0.1 * strength;
    vec4 col;
    col.r = texture(TEXTURE, uv + vec2(offset, 0.0)).r;
    col.g = texture(TEXTURE, uv).g;
    col.b = texture(TEXTURE, uv - vec2(offset, 0.0)).b;
    col.a = texture(TEXTURE, uv).a;

    COLOR = col;
}

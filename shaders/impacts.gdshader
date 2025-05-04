shader_type canvas_item;

render_mode blend_mix, unshaded;

// === Paramètres de déformation + aberration ===
uniform float deform_strength : hint_range(0.0, 1.0) = 0.0;

// === Paramètres de pixelisation brute ===
uniform float pixel_size : hint_range(1.0, 256.0) = 1.0;
uniform float contrast : hint_range(0.0, 2.0) = 1.0;

// === Paramètre de gris progressif ===
uniform float grayness_strength : hint_range(0.0, 1.0) = 0.0;

uniform bool recurring_hide = false;

void fragment() {
    // --- 1. Déformation de l'UV ---
    vec2 uv = UV;
    if (deform_strength > 0.0) {
        float wave = sin(uv.y * 20.0 + TIME * 3.0) * 0.01;
        wave += sin(uv.x * 40.0 + TIME * 2.0) * 0.01;
        uv += wave * deform_strength;
    }

    // --- 2. Chromatic Aberration ---
    float offset = 0.1 * deform_strength;
    vec4 tex_r = texture(TEXTURE, uv + vec2(offset, 0.0));
    vec4 tex_gb = texture(TEXTURE, uv);
    vec4 tex_b = texture(TEXTURE, uv - vec2(offset, 0.0));

    vec4 color = vec4(tex_r.r, tex_gb.g, tex_b.b, tex_gb.a);

    // --- 3. Pixelation + brut ---
    if (pixel_size > 1.0) {
        vec2 pixel_uv = floor(uv * pixel_size) / pixel_size;
        color = texture(TEXTURE, pixel_uv);
        color.rgb = pow(color.rgb, vec3(contrast));
    }

    // --- 4. Passage en niveaux de gris ---
    if (grayness_strength > 0.0) {
        float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
        color.rgb = mix(color.rgb, vec3(gray), grayness_strength);
    }

	if (recurring_hide){
		// Temps total de cycle : 5s
        float t = mod(TIME, 5.0); // cycle de 5 secondes
        float alpha = 1.0;

        if (t >= 3.0 && t < 4.0) {
            // Fade out (1.0 → 0.0)
            alpha = 1.0 - (t - 3.0);
        } else if (t >= 4.0 && t < 5.0) {
            // Fade in (0.0 → 1.0)
            alpha = t - 4.0;
        }

		color.a = alpha;
	}

    COLOR = color;
}

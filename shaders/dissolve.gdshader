shader_type canvas_item;

uniform vec2 position;
uniform float radius : hint_range(0.0,2.0);
uniform float borderWidth = 0.02;
uniform float burnMult = 0.135;
uniform sampler2D noiseTexture;
uniform vec4 burnColor : source_color;
uniform sampler2D backTexture;

uniform float corner_radius_px : hint_range(0.0, 20.0) = 10.0;
uniform vec2 texture_size = vec2(300.0, 300.0);

uniform float grayness_strength : hint_range(0.0, 1.0) = 0.0;

// Border
uniform float border_width_px : hint_range(0.0, 10.0) = 2.0;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 pixel_pos = UV * texture_size;
	float corner_radius = corner_radius_px;

	bool in_bottom_left = pixel_pos.x < corner_radius && pixel_pos.y > (texture_size.y - corner_radius);
	bool in_bottom_right = pixel_pos.x > (texture_size.x - corner_radius) && pixel_pos.y > (texture_size.y - corner_radius);
	bool in_top_left = pixel_pos.x < corner_radius && pixel_pos.y < corner_radius;
	bool in_top_right = pixel_pos.x > (texture_size.x - corner_radius) && pixel_pos.y < corner_radius;

	// Calcul de la distance au coin
	float corner_dist = 0.0;
	if (in_bottom_left) {
		corner_dist = length(pixel_pos - vec2(corner_radius, texture_size.y - corner_radius));
	} else if (in_bottom_right) {
		corner_dist = length(pixel_pos - vec2(texture_size.x - corner_radius, texture_size.y - corner_radius));
	} else if (in_top_left) {
		corner_dist = length(pixel_pos - vec2(corner_radius, corner_radius));
	} else if (in_top_right) {
		corner_dist = length(pixel_pos - vec2(texture_size.x - corner_radius, corner_radius));
	}

	// Masquer les pixels dans les coins arrondis
	bool is_outside_corner = (in_bottom_left || in_bottom_right || in_top_left || in_top_right) && (corner_dist > corner_radius);
	if (is_outside_corner) {
		COLOR.a = 0.0;
		discard;
	}

	// === Dessin du contour noir ===
	bool is_border = false;

	// Bords verticaux et horizontaux
	is_border = (
		pixel_pos.x <= border_width_px ||
		pixel_pos.x >= texture_size.x - border_width_px ||
		pixel_pos.y <= border_width_px ||
		pixel_pos.y >= texture_size.y - border_width_px
	);

	// Bords des coins
	bool is_corner_border = false;
	if (in_bottom_left || in_bottom_right || in_top_left || in_top_right) {
		is_corner_border = (corner_dist > (corner_radius - border_width_px));
	}

	if (is_border || is_corner_border) {
		COLOR = border_color; //vec4(0.0, 0.0, 0.0, 1.0);
		//return;
	}

	// === Burn effect
	vec4 back_rgb = texture(backTexture, UV);
	if (COLOR.a <= 0.1){
		COLOR = back_rgb;
	}

	float dist = length(position - UV) + (texture(noiseTexture, UV).b) * burnMult;
	COLOR.rgb = mix(COLOR.rgb, burnColor.rgb, float(dist < radius + borderWidth));
	COLOR.a *= 1.0 - float(dist < radius);

	// === Grey
	float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grayscale = vec3(gray);
	COLOR = vec4(mix(COLOR.rgb, grayscale, grayness_strength), COLOR.a);
}

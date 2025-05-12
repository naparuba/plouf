shader_type canvas_item;

uniform float corner_radius_px : hint_range(0.0, 20.0) = 10.0;
uniform vec2 texture_size = vec2(300.0, 300.0);

// Border
uniform float border_thickness = 2.0;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform sampler2D backTexture;

void fragment() {
	vec2 uv = UV;

	vec4 back_rgb = texture(backTexture, UV);  // Pixel from the background


	vec4 tex_color = texture(TEXTURE, uv);
	COLOR = tex_color;

	// If the original pixel is transparent, then copy the background one instead
	if (COLOR.a == 0.0){
		COLOR = back_rgb;
	}

	// === Coins arrondis ===
	vec2 pixel_pos = uv * texture_size;
	float corner_radius = corner_radius_px;

	bool in_bottom_left = pixel_pos.x < corner_radius && pixel_pos.y > (texture_size.y - corner_radius);
	bool in_bottom_right = pixel_pos.x > (texture_size.x - corner_radius) && pixel_pos.y > (texture_size.y - corner_radius);
	bool in_top_left = pixel_pos.x < corner_radius && pixel_pos.y < corner_radius;
	bool in_top_right = pixel_pos.x > (texture_size.x - corner_radius) && pixel_pos.y < corner_radius;

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

	if ((in_bottom_left || in_bottom_right || in_top_left || in_top_right) && corner_dist > corner_radius) {
		COLOR.a = 0.0;
	}

	// === Bordure noire ===
	bool is_border =
		pixel_pos.x < border_thickness ||
		pixel_pos.x > texture_size.x - border_thickness ||
		pixel_pos.y < border_thickness ||
		pixel_pos.y > texture_size.y - border_thickness;

	bool is_corner_border = false;
	if ((in_bottom_left || in_bottom_right || in_top_left || in_top_right)) {
		is_corner_border = corner_dist > (corner_radius - border_thickness);
	}

	if ((is_border || is_corner_border) && COLOR.a > 0.0) {
		COLOR = border_color; //vec4(0.0, 0.0, 0.0, 1.0);
	}
}

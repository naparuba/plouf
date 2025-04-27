shader_type canvas_item;

uniform vec2 position;
uniform float radius : hint_range(0.0,2.0);
uniform float borderWidth = 0.02;
uniform float burnMult = 0.135;
uniform sampler2D noiseTexture;
uniform vec4 burnColor : source_color;

uniform float corner_radius_px : hint_range(0.0,20.0) = 10.0;
uniform vec2 texture_size = vec2(300.0, 300.0);

void fragment() {
	float dist = length(position - UV) + (texture(noiseTexture, UV).b) * burnMult;
	COLOR.rgb = mix(COLOR.rgb, burnColor.rgb, float(dist<radius+borderWidth));
	COLOR.a *= 1.0-(float(dist<radius));

	// Maintenant, on s'occupe de rendre transparent dans les coins arrondis
    vec2 pixel_pos = UV * texture_size;
    float corner_radius = corner_radius_px;

    bool in_bottom_left = pixel_pos.x < corner_radius && pixel_pos.y > (texture_size.y - corner_radius);
    bool in_bottom_right = pixel_pos.x > (texture_size.x - corner_radius) && pixel_pos.y > (texture_size.y - corner_radius);
    bool in_top_left = pixel_pos.x < corner_radius && pixel_pos.y < corner_radius;
    bool in_top_right = pixel_pos.x > (texture_size.x - corner_radius) && pixel_pos.y < corner_radius;

    // We are looking the difference with a point near the corner, and look at distance to
	// make a "round"
    float corner_dist = 0.0;
    if (in_bottom_left) {
		corner_dist = length(pixel_pos - vec2(corner_radius, texture_size.y - corner_radius ));
    } else if (in_bottom_right) {
        corner_dist = length(pixel_pos - vec2(texture_size.x - corner_radius, texture_size.y - corner_radius));
    } else if (in_top_left) {
        corner_dist = length(pixel_pos - vec2(corner_radius,corner_radius));
    } else if (in_top_right) {
        corner_dist = length(pixel_pos - vec2(texture_size.x - corner_radius, corner_radius));
    }
    //corner_dist = 0.0;
    if ((in_bottom_left || in_bottom_right || in_top_left || in_top_right) && corner_dist > corner_radius) {
        // On est dans la zone de coin arrondi → supprimer le pixel
        COLOR.a = 0.0;
    }

}
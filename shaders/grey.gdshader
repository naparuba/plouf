shader_type canvas_item;

uniform float grayness_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    float gray = dot(original.rgb, vec3(0.299, 0.587, 0.114));
    vec3 grayscale = vec3(gray);
    COLOR = vec4(mix(original.rgb, grayscale, grayness_strength), original.a);
}

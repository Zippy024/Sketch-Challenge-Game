shader_type canvas_item;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV);
	float curved_right = 1.01 - 0.34 * pow(abs(UV.y * 2.0 - 1.0), 1.75);
	pixel.a *= 1.0 - smoothstep(curved_right - 0.015, curved_right + 0.015, UV.x);
	COLOR = pixel;
}

shader_type canvas_item;
void fragment() {
 vec4 original = texture(TEXTURE, UV);
 vec3 blue = vec3(1.3 * original.r - .3 * original.g, .12 * original.r + .88 * original.g,
                  original.b + .16 * (original.g - original.r));
 COLOR = vec4(clamp(blue, vec3(0.0), vec3(1.0)), original.a);
}

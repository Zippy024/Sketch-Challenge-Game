shader_type canvas_item;

// The original reference already contains blue ink. Hide only that ink during
// the blink's off phase; the supplied image file is never changed.
uniform float outline_visibility : hint_range(0.0, 1.0) = 1.0;
varying vec4 item_tint;

void vertex() {
 item_tint = COLOR;
}

float blue_ink(vec3 color) {
 return smoothstep(0.06, 0.10, color.b - max(color.r, color.g))
  * smoothstep(0.4, 0.6, color.b);
}

void fragment() {
 vec4 original = texture(TEXTURE, UV);
 vec3 result = original.rgb;
 if (outline_visibility < 0.99) {
  float ink = blue_ink(original.rgb);
  if (ink > 0.0) {
   vec2 step_uv = TEXTURE_PIXEL_SIZE * 4.0;
   vec3 left = texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).rgb;
   vec3 right = texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).rgb;
   vec3 above = texture(TEXTURE, UV - vec2(0.0, step_uv.y)).rgb;
   vec3 below = texture(TEXTURE, UV + vec2(0.0, step_uv.y)).rgb;
   vec4 weights = vec4(1.0 - blue_ink(left), 1.0 - blue_ink(right),
    1.0 - blue_ink(above), 1.0 - blue_ink(below));
   float total = dot(weights, vec4(1.0));
   vec3 paper = total > 0.001
    ? (left * weights.x + right * weights.y + above * weights.z + below * weights.w) / total
    : original.rgb;
   result = mix(original.rgb, paper, ink * (1.0 - outline_visibility));
  }
 }
 COLOR = vec4(result, original.a) * item_tint;
}

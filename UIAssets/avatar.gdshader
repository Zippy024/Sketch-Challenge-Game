
shader_type canvas_item;
uniform vec4 ring_color : source_color = vec4(0.47, 0.70, 1.0, 1.0);
uniform float ring_width = 0.035;
void fragment() {
 vec2 p = UV - vec2(0.5);
 float d = length(p);
 float aa = max(fwidth(d), 0.001);
 float a = 1.0 - smoothstep(0.5-aa,0.5+aa,d);
 vec4 t = texture(TEXTURE,UV);
 float ring = smoothstep(0.5-ring_width-aa,0.5-ring_width+aa,d);
 COLOR = vec4(mix(t.rgb,ring_color.rgb,ring), t.a*a);
}

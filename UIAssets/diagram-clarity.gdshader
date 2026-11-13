shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
void vertex() { tint=COLOR; }
void fragment() {
	vec4 center=textureLod(TEXTURE,UV,0.0);
	vec2 pixel=TEXTURE_PIXEL_SIZE;
	vec3 nearby=(textureLod(TEXTURE,UV+vec2(pixel.x,0.0),0.0).rgb+
		textureLod(TEXTURE,UV-vec2(pixel.x,0.0),0.0).rgb+
		textureLod(TEXTURE,UV+vec2(0.0,pixel.y),0.0).rgb+
		textureLod(TEXTURE,UV-vec2(0.0,pixel.y),0.0).rgb)*0.25;
	// A modest edge contrast adjustment; geometry and source pixels are retained.
	COLOR=vec4(clamp(center.rgb+(center.rgb-nearby)*0.2,vec3(0.0),vec3(1.0)),center.a)*tint;
}

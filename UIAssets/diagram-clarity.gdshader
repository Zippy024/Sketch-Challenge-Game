shader_type canvas_item;
render_mode unshaded;
uniform float strength = 0.2;
uniform float ink_boost = 0.0;
varying vec4 tint;
void vertex() { tint=COLOR; }
void fragment() {
	vec4 center=texture(TEXTURE,UV);
	// Sample at the visible pixel footprint, keeping minified diagrams stable.
	vec2 pixel=max(TEXTURE_PIXEL_SIZE,fwidth(UV));
	vec3 nearby=(texture(TEXTURE,UV+vec2(pixel.x,0.0)).rgb+
		texture(TEXTURE,UV-vec2(pixel.x,0.0)).rgb+
		texture(TEXTURE,UV+vec2(0.0,pixel.y)).rgb+
		texture(TEXTURE,UV-vec2(0.0,pixel.y)).rgb)*0.25;
	vec3 sharpened=clamp(center.rgb+(center.rgb-nearby)*strength,vec3(0.0),vec3(1.0));
	// Emphasize neutral cabinet strokes without saturating the blue/tan fills.
	float chroma=max(center.r,max(center.g,center.b))-min(center.r,min(center.g,center.b));
	float ink=(1.0-smoothstep(0.02,0.09,chroma))*(1.0-smoothstep(0.7,0.98,center.r));
	COLOR=vec4(clamp(sharpened-vec3(ink*ink_boost),vec3(0.0),vec3(1.0)),center.a)*tint;
}

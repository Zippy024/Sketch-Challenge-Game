shader_type canvas_item;
void fragment() {
	float d=length(UV-vec2(0.5));
	float aa=max(fwidth(d),0.001);
	vec2 sample_uv=vec2(0.5)+(UV-vec2(0.5))*0.965;
	vec4 photo=texture(TEXTURE,clamp(sample_uv,vec2(0.0),vec2(1.0)));
	float inner=1.0-smoothstep(0.453-aa,0.453+aa,d);
	COLOR=vec4(mix(vec3(0.99,1.0,1.0),photo.rgb,inner),1.0-smoothstep(0.475-aa,0.475+aa,d));
}

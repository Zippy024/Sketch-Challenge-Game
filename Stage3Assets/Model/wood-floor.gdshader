shader_type spatial;
void fragment(){
	// Pale oak planks, staggered joints, soft figure and fine grain.
	vec2 uv=UV*vec2(5.0,16.0);
	float row=floor(uv.y);
	float board=floor(uv.x+mod(row,2.0)*0.5);
	float tone=fract(sin(board*29.19+row*17.42)*4337.25);
	float grain=sin(uv.x*30.0+sin(uv.y*8.0))*0.012;
	grain+=sin(uv.x*78.0+uv.y*5.0)*0.006;
	float seam=step(0.988,fract(uv.y))+step(0.989,fract(uv.x+mod(row,2.0)*0.5));
	vec3 oak=mix(vec3(0.75,0.62,0.42),vec3(0.91,0.79,0.57),tone*0.38+0.43);
	ALBEDO=oak+vec3(grain)-vec3(seam*0.065);
	ROUGHNESS=0.78;
}

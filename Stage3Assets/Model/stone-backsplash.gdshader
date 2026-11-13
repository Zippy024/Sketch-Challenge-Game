shader_type spatial;
uniform float highlighted=0.0;
varying vec3 surface_point;
void vertex(){
	surface_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
void fragment(){
	float n=sin(surface_point.x*17.0+sin(surface_point.y*11.0)*1.3)*0.018;
	n+=sin(surface_point.x*52.0+surface_point.y*32.0)*0.009;
	n+=sin(surface_point.x*7.0+surface_point.y*29.0)*0.014;
	ALBEDO=mix(vec3(0.67,0.66,0.63)+vec3(n*0.35),vec3(0.33,0.79,0.73),highlighted*0.32);
	ROUGHNESS=0.93;
}

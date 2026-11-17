shader_type spatial;
uniform float highlighted=0.0;
varying vec3 surface_point;
void vertex(){surface_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float grain_hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float stone_noise(vec2 p){
 vec2 cell=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(grain_hash(cell),grain_hash(cell+vec2(1,0)),f.x),mix(grain_hash(cell+vec2(0,1)),grain_hash(cell+vec2(1,1)),f.x),f.y);
}
void fragment(){
 float broad=stone_noise(surface_point.xy*5.0+vec2(2.0,7.0));
 float grain=(stone_noise(surface_point.xy*35.0)-0.5)*0.035+(stone_noise(surface_point.xy*170.0)-0.5)*0.012;
 vec3 stone=mix(vec3(0.65,0.64,0.61),vec3(0.77,0.76,0.73),broad)+vec3(grain);
 ALBEDO=mix(stone,vec3(0.33,0.79,0.73),highlighted*0.32);
 ROUGHNESS=0.72;
}

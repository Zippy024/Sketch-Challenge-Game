shader_type spatial;
varying vec3 point;
void vertex(){point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float grain=sin(point.y*460.0+sin(point.x*8.0)*1.4)*0.012+sin(point.y*124.0+point.x*2.0)*0.018;
 float wave=sin(point.y*29.0+sin(point.x*2.4)*1.2)*0.022;
 ALBEDO=vec3(0.56,0.555,0.50)+vec3(grain+wave);
 ROUGHNESS=0.48;
}

shader_type spatial;
void fragment() {
 vec2 p=UV*vec2(6.0,16.0);
 float row=floor(p.y);
 float board=floor(p.x+mod(row,2.0)*0.5);
 float tone=fract(sin(row*43.7+board*17.3)*43758.54);
 float grain=sin(p.x*35.0+sin(p.y*19.0))*0.018+sin(p.x*27.0+p.y*7.0)*0.004;
 float seam=step(0.985,fract(p.y))+step(0.993,fract(p.x+mod(row,2.0)*0.5));
 ALBEDO=mix(vec3(0.48,0.34,0.19),vec3(0.69,0.55,0.34),tone*0.5+0.35)+vec3(grain)-vec3(seam*0.04);
 ROUGHNESS=0.82;
}

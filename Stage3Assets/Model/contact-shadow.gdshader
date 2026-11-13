shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
void fragment(){
 vec2 edge=abs(UV-vec2(0.5))*2.0;
 float blur=1.0-smoothstep(0.52,1.0,max(edge.x,edge.y));
 ALBEDO=vec3(0.17,0.19,0.17);
 ALPHA=blur*0.13;
}

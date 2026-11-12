shader_type canvas_item;
uniform vec2 extent = vec2(120.0,40.0);
void fragment() {
 vec2 p = (UV-vec2(0.5))*extent;
 float r = extent.y*0.5-2.0;
 vec2 q = abs(p)-(extent*0.5-vec2(r+2.0));
 float d = length(max(q,vec2(0.0)))+min(max(q.x,q.y),0.0)-r;
 float clip = 1.0-smoothstep(-1.0,1.0,d);
 float phase = mod(TIME,7.0);
 float center = -0.6+phase*0.9;
 float band = max(0.0,1.0-abs(UV.x+UV.y*0.16-center)/0.11);
 COLOR = vec4(0.85,1.0,1.0,band*band*clip*0.15*step(phase,2.5));
}

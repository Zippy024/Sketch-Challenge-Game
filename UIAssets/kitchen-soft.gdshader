shader_type canvas_item;
void fragment() {
 // Small Gaussian kernel keeps background details soft without ghosted edges.
 vec4 color = vec4(0.0);
 float weights[5] = float[5](1.0, 4.0, 6.0, 4.0, 1.0);
 for (int x=0; x<5; x++) {
  for (int y=0; y<5; y++) {
   vec2 offset = vec2(float(x-2),float(y-2))*TEXTURE_PIXEL_SIZE*2.0;
   color += texture(TEXTURE,UV+offset)*weights[x]*weights[y]/256.0;
  }
 }
 COLOR = color;
}

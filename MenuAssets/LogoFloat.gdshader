shader_type canvas_item;
// Move vertices at fractional pixel positions, avoiding Control layout snapping.
// A single slow float replaces the two independent position/rotation tweens.
void vertex() {
 VERTEX.y += sin(TIME * 0.8975979) * 3.0;
}

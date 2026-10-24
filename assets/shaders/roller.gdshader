shader_type spatial;
// Tapparella con lamelle orizzontali fini.
#include "res://assets/shaders/noise.gdshaderinc"
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float f = fract(world_pos.y / 0.045);
	float aa = max(fwidth(world_pos.y / 0.045), 0.03);
	float seam = 1.0 - smoothstep(0.04, 0.04 + aa, min(f, 1.0 - f));
	ALBEDO = apollo_to_linear(COLOR.rgb) * (1.0 - seam * 0.22);
	ROUGHNESS = 0.72;
}

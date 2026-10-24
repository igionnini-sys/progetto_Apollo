shader_type spatial;
// Rivestimento in blocchi di pietra; dettagli procedurali originali in metri.
#include "res://assets/shaders/noise.gdshaderinc"
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = vec2(world_pos.x + world_pos.z, world_pos.y) / vec2(0.48, 0.22);
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 f = fract(p);
	vec2 edge = min(f, 1.0 - f);
	vec2 aa = max(fwidth(p), vec2(0.008));
	vec2 joints = 1.0 - smoothstep(vec2(0.013), vec2(0.013) + aa, edge);
	float fade = 1.0 - smoothstep(18.0, 60.0, length(CAMERA_POSITION_WORLD - world_pos));
	vec3 c = apollo_to_linear(COLOR.rgb) * (0.89 + apollo_hash(floor(p)) * 0.18);
	c *= 1.0 - max(joints.x, joints.y) * 0.28 * fade;
	c *= 0.95 + apollo_noise(world_pos.xz * 25.0 + world_pos.y) * 0.08 * fade;
	ALBEDO = c;
	ROUGHNESS = 0.93;
}

shader_type spatial;
// Asfalto con rappezzi e grana; coordinate mondo per evitare cuciture fra i tratti.
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 base_color : source_color = vec3(0.36, 0.39, 0.42);
uniform float wear = 0.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz;
	float distance_to_camera = length(CAMERA_POSITION_WORLD - world_pos);
	float patches = apollo_fbm(p * 0.08);
	float grain = apollo_noise(p * 9.0) * (1.0 - smoothstep(10.0, 40.0, distance_to_camera));
	vec3 c = base_color * (0.86 + patches * 0.22) * (0.95 + grain * 0.1);
	if (wear > 0.0) {
		float close_detail = 1.0 - smoothstep(14.0, 45.0, distance_to_camera);
		float fissure = 1.0 - smoothstep(0.004, 0.016, abs(apollo_fbm(p * 0.65) - 0.5));
		fissure *= smoothstep(0.4, 0.65, apollo_noise(p * 0.12));
		c *= 1.0 - fissure * 0.28 * close_detail * wear;
	}
	ALBEDO = c;
	ROUGHNESS = 0.82 - patches * 0.12;
	SPECULAR = 0.35;
}

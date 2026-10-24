shader_type spatial;
render_mode cull_disabled;
#include "res://assets/shaders/noise.gdshaderinc"
uniform vec3 paint_color : source_color = vec3(0.87, 0.89, 0.87);
varying vec3 local_pos;
void vertex() { local_pos = VERTEX; }
void fragment() {
	float film = apollo_noise(local_pos.xz * 24.0 + local_pos.y * 7.0);
	float dust = (1.0 - smoothstep(0.25, 0.82, local_pos.y)) * (0.025 + 0.035 * apollo_noise(local_pos.xz * 3.0));
	ALBEDO = mix(paint_color, vec3(0.26, 0.24, 0.21), dust);
	METALLIC = 0.0;
	ROUGHNESS = 0.20 + film * 0.035 + dust;
	SPECULAR = 0.5;
	CLEARCOAT = 0.9;
	CLEARCOAT_ROUGHNESS = 0.09;
}

shader_type spatial;
render_mode cull_disabled;
#include "res://assets/shaders/noise.gdshaderinc"
uniform vec3 tint : source_color = vec3(0.23, 0.245, 0.255);
varying vec3 local_pos;
void vertex() { local_pos = VERTEX; }
void fragment() {
	float grain = apollo_noise((local_pos.xy + local_pos.z) * 420.0);
	float fade = 1.0 - smoothstep(0.01, 0.08, length(fwidth(local_pos)));
	ALBEDO = tint * (0.95 + grain * 0.08 * fade);
	ROUGHNESS = 0.67 + grain * 0.12 * fade;
	SPECULAR = 0.35;
}

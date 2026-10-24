shader_type spatial;
render_mode diffuse_lambert_wrap;
// Chiome sfaccettate con colore per istanza e oscillazione leggera nel vento.
#include "res://assets/shaders/noise.gdshaderinc"

uniform float sway = 0.035;

varying float local_height;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float phase = TIME * 1.3 + origin.x * 0.21 + origin.z * 0.17;
	float weight = max(VERTEX.y + 0.5, 0.0);
	VERTEX.x += sin(phase) * sway * weight;
	VERTEX.z += cos(phase * 0.8) * sway * weight * 0.6;
	local_height = VERTEX.y;
}

void fragment() {
	vec3 c = apollo_to_linear(COLOR.rgb);
	c *= mix(0.68, 1.12, smoothstep(-0.5, 0.5, local_height));
	ALBEDO = c;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
}

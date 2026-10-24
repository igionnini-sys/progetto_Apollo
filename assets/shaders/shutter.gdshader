shader_type spatial;
// Lamelle con colore per istanza: bordo pieno e fughe attenuate a distanza.
#include "res://assets/shaders/noise.gdshaderinc"
varying vec3 world_pos;
varying vec2 local_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	local_pos = VERTEX.xy;
}
void fragment() {
	float course = world_pos.y / 0.12;
	float aa = max(fwidth(course), 0.015);
	float groove = 1.0 - smoothstep(0.03, 0.03 + aa, min(fract(course), 1.0 - fract(course)));
	float frame = smoothstep(0.35, 0.43, abs(local_pos.x)) + smoothstep(0.42, 0.47, abs(local_pos.y));
	float fade = 1.0 - smoothstep(0.3, 1.0, fwidth(course));
	vec3 color = apollo_to_linear(COLOR.rgb);
	color *= 1.0 - groove * 0.28 * (1.0 - clamp(frame, 0.0, 1.0)) * fade;
	ALBEDO = color;
	ROUGHNESS = 0.82;
	SPECULAR = 0.23;
}

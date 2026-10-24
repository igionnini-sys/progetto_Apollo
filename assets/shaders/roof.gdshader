shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap;
// Coppi in terracotta: UV.x lungo la gronda, UV.y lungo la falda, in metri.
#include "res://assets/shaders/noise.gdshaderinc"

void fragment() {
	vec3 c = apollo_to_linear(COLOR.rgb);
	float course = UV.y / 0.42;
	float row = floor(course);
	float column = (UV.x + mod(row, 2.0) * 0.14) / 0.28;
	float ridge = 0.5 + 0.5 * cos(fract(column) * 6.2831);
	float lip = smoothstep(0.75, 1.0, fract(course));
	float tint = apollo_hash(vec2(floor(column), row));
	float fade = 1.0 - smoothstep(30.0, 120.0, length(VERTEX));
	c *= mix(0.92, 0.82 + ridge * 0.2 - lip * 0.18 + (tint - 0.5) * 0.12, fade);
	ALBEDO = c;
	ROUGHNESS = 0.8;
	SPECULAR = 0.3;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}

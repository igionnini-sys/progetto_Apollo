shader_type spatial;
render_mode diffuse_burley;
// Intonaco caldo e corsi di muratura sui toni terracotta. UV in metri sulle facciate.
#include "res://assets/shaders/noise.gdshaderinc"

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = apollo_to_linear(COLOR.rgb);
	float plaster = apollo_fbm(vec2(world_pos.x + world_pos.z, world_pos.y) * 1.1);
	c *= 0.92 + plaster * 0.14;
	vec2 brick = UV / vec2(0.72, 0.32);
	brick.x += mod(floor(brick.y), 2.0) * 0.5;
	vec2 cell = floor(brick);
	vec2 edge = min(fract(brick), 1.0 - fract(brick));
	vec2 aa = max(fwidth(brick), vec2(0.008));
	vec2 joints = 1.0 - smoothstep(vec2(0.015), vec2(0.015) + aa, edge);
	float masonry = smoothstep(1.12, 1.32, COLOR.r / max(COLOR.g, 0.01));
	float fade = 1.0 - smoothstep(18.0, 70.0, length(CAMERA_POSITION_WORLD - world_pos));
	c *= 1.0 + (apollo_hash(cell) - 0.5) * 0.11 * masonry * fade;
	c = mix(c, c * 0.8, max(joints.x, joints.y) * 0.38 * masonry * fade);
	c *= mix(0.75, 1.0, smoothstep(0.0, 1.0, world_pos.y));
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
}

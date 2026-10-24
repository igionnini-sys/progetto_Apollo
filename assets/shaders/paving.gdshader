shader_type spatial;
// Marciapiede in lastre chiare con fughe sottili, sfumate da lontano.
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 base_color : source_color = vec3(0.84, 0.81, 0.72);
uniform float tile = 0.7;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz / vec2(tile, tile * 0.62);
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 width = fwidth(p) * 1.5 + 0.03;
	vec2 edges = smoothstep(vec2(0.0), width, f) * smoothstep(vec2(0.0), width, 1.0 - f);
	float joint = 1.0 - edges.x * edges.y;
	float fade = 1.0 - smoothstep(12.0, 45.0, length(CAMERA_POSITION_WORLD - world_pos));
	vec3 c = base_color * (0.91 + apollo_hash(cell) * 0.14);
	c *= 1.0 - joint * 0.28 * fade;
	ALBEDO = c;
	ROUGHNESS = 0.9;
}

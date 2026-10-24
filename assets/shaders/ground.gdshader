shader_type spatial;
render_mode diffuse_lambert_wrap;
// Prato cartoon con macchie, fiorellini vicini alla camera e campi coltivati lontani.
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 grass_light : source_color = vec3(0.53, 0.67, 0.40);
uniform vec3 grass_dark : source_color = vec3(0.36, 0.49, 0.32);
uniform vec3 grass_dry : source_color = vec3(0.80, 0.78, 0.44);
uniform bool fields = false;
uniform float flowers = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 field_color(vec2 p) {
	// Appezzamenti rettangolari ruotati: grano, erba medica, terra arata.
	vec2 q = vec2(p.x * 0.94 + p.y * 0.34, -p.x * 0.34 + p.y * 0.94);
	vec2 cell = floor(q / vec2(70.0, 38.0));
	float pick = apollo_hash(cell);
	vec3 c = vec3(0.40, 0.60, 0.29);
	if (pick < 0.25) c = vec3(0.86, 0.74, 0.38);
	else if (pick < 0.45) c = vec3(0.55, 0.70, 0.30);
	else if (pick < 0.6) c = vec3(0.62, 0.50, 0.36);
	else if (pick < 0.8) c = vec3(0.46, 0.64, 0.30);
	float rows = 0.5 + 0.5 * sin(q.x * 2.2);
	return apollo_to_linear(c) * (0.9 + 0.1 * rows);
}

void fragment() {
	vec2 p = world_pos.xz;
	float distance_to_camera = length(CAMERA_POSITION_WORLD - world_pos);
	float large = apollo_fbm(p * 0.045);
	vec3 c = mix(grass_dark, grass_light, smoothstep(0.28, 0.72, large));
	c = mix(c, grass_dry, smoothstep(0.6, 0.8, apollo_fbm(p * 0.02 + 17.0)) * 0.45);
	float detail = 1.0 - smoothstep(25.0, 70.0, distance_to_camera);
	c *= mix(1.0, 0.9 + apollo_noise(p * 2.3) * 0.16, detail);
	if (fields) {
		c = mix(c, field_color(p), smoothstep(150.0, 260.0, length(p - CAMERA_POSITION_WORLD.xz)));
	}
	// Fiorellini sparsi: piccoli punti colorati, attenuati con la distanza.
	vec2 grid = p * 1.4;
	vec2 cell = floor(grid);
	float h = apollo_hash(cell);
	vec2 offset = vec2(apollo_hash(cell + 3.1), apollo_hash(cell + 7.7)) - 0.5;
	float dot_mask = 1.0 - smoothstep(0.07, 0.11, length(fract(grid) - 0.5 - offset * 0.6));
	float flower = step(0.955, h) * dot_mask * detail * flowers;
	vec3 petal = h > 0.985 ? vec3(0.95, 0.55, 0.65) : (h > 0.97 ? vec3(1.0, 0.85, 0.30) : vec3(0.98, 0.97, 0.92));
	c = mix(c, petal, flower);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	SPECULAR = 0.15;
}

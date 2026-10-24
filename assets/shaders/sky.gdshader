shader_type sky;
// Cielo del mattino con sole, nuvole statiche e profilo cartoon delle Alpi a nord-ovest.
// Nessun uso di TIME: la radianza resta economica e stabile.
#include "res://assets/shaders/noise.gdshaderinc"

uniform vec3 top_color : source_color = vec3(0.015, 0.55, 0.66);
uniform vec3 horizon_color : source_color = vec3(0.42, 0.78, 0.79);
uniform vec3 ground_color : source_color = vec3(0.57, 0.72, 0.67);
uniform vec3 mountain_color : source_color = vec3(0.22, 0.57, 0.62);
uniform vec3 hill_color : source_color = vec3(0.32, 0.61, 0.57);
uniform vec3 snow_color : source_color = vec3(0.97, 0.98, 1.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.93, 0.78);
uniform float cloud_amount = 0.48;
uniform float mountain_scale = 1.0;

float ridge_profile(float azimuth, float frequency, float seed) {
	vec2 ring = vec2(cos(azimuth), sin(azimuth)) * frequency + seed;
	float n = apollo_fbm(ring);
	float sharp = 1.0 - abs(apollo_noise(ring * 2.7) * 2.0 - 1.0);
	return n * 0.7 + sharp * 0.3;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float y = dir.y;
	vec3 col = mix(horizon_color, top_color, pow(clamp(y * 1.65, 0.0, 1.0), 0.48));
	col = mix(col, ground_color, smoothstep(0.0, -0.12, y));
	// Nord = -Z nella proiezione locale; ovest = -X.
	float azimuth = atan(dir.x, -dir.z);
	float alps_mask = smoothstep(-2.3, -1.6, azimuth) * (1.0 - smoothstep(0.35, 0.9, azimuth));
	float alps = (0.02 + pow(ridge_profile(azimuth, 4.0, 3.0), 1.8) * 0.21) * alps_mask * mountain_scale;
	float hills_mask = smoothstep(1.3, 2.0, abs(azimuth));
	float hills = (0.006 + ridge_profile(azimuth, 2.0, 11.0) * 0.03) * hills_mask;
	float far_ridge = 0.004 + ridge_profile(azimuth, 6.0, 23.0) * 0.012;
	if (y > -0.02) {
		float clouds_mask = smoothstep(0.02, 0.12, y);
		vec2 plane = dir.xz / (y + 0.18);
		float cloud = apollo_fbm(plane * 1.4 + vec2(4.0, 1.0));
		cloud = smoothstep(1.0 - cloud_amount * 0.75, 1.0 - cloud_amount * 0.35, cloud) * clouds_mask;
		vec3 cloud_col = mix(vec3(0.78, 0.87, 0.86), vec3(1.0, 0.98, 0.91), cloud);
		col = mix(col, cloud_col, cloud * 0.92);
		if (y < far_ridge) {
			col = mix(col, mix(mountain_color, horizon_color, 0.55), 0.8);
		}
		// Quota neve fissa, appena ondulata: imbiancate solo le cime più alte.
		float snowline = (0.07 + (apollo_fbm(vec2(azimuth * 9.0, 1.0)) - 0.5) * 0.014) * mountain_scale;
		if (y < alps) {
			float snow = smoothstep(snowline, snowline + 0.003, y);
			vec3 rock = mix(mountain_color, horizon_color, 0.5 - 0.25 * smoothstep(0.0, alps, y));
			col = mix(rock, mix(snow_color, horizon_color, 0.18), snow);
		}
		// Seconda catena più vicina e più scura, per dare profondità.
		float near_range = (0.008 + pow(ridge_profile(azimuth, 2.6, 9.0), 2.3) * 0.11) * alps_mask * mountain_scale;
		if (y < near_range) {
			float snow = smoothstep(snowline + 0.004, snowline + 0.007, y);
			vec3 rock = mix(mountain_color * 0.82, horizon_color, 0.32 - 0.2 * smoothstep(0.0, near_range, y));
			col = mix(rock, mix(snow_color, horizon_color, 0.08), snow);
		}
		if (y < hills) {
			col = mix(hill_color, horizon_color, 0.35);
		}
	}
	if (LIGHT0_ENABLED) {
		float facing = max(dot(dir, LIGHT0_DIRECTION), 0.0);
		float disk = smoothstep(0.99955, 0.9998, facing);
		col += sun_color * (disk * 6.0 + pow(facing, 220.0) * 0.6 + pow(facing, 12.0) * 0.12) * (AT_CUBEMAP_PASS ? 0.4 : 1.0);
	}
	COLOR = col;
}

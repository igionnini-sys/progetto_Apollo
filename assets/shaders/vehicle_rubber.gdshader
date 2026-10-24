shader_type spatial;
varying vec3 wheel_pos;
void vertex() { wheel_pos = VERTEX; }
void fragment() {
	float angle = atan(wheel_pos.z, wheel_pos.y) / 6.2831853;
	float width = wheel_pos.x;
	float tread = abs(fract(angle * 64.0 + abs(fract(width * 22.0) - 0.5) * 0.6) - 0.5);
	float aa = max(fwidth(tread), 0.025);
	float groove = 1.0 - smoothstep(0.035, 0.035 + aa, tread);
	float fade = 1.0 - smoothstep(0.12, 0.45, fwidth(angle) * 64.0);
	float band = 1.0 - smoothstep(0.065, 0.105, abs(width));
	float longitudinal = 1.0 - smoothstep(0.025, 0.07, abs(fract(width * 26.0) - 0.5));
	ALBEDO = vec3(0.055, 0.060, 0.063) * (1.0 - (groove * 0.28 + longitudinal * 0.20) * band * fade);
	ROUGHNESS = 0.87;
	SPECULAR = 0.28;
}

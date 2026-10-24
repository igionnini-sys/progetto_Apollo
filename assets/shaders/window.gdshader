shader_type spatial;
// Vetrate opache economiche: riflessi del cielo e tende, colore variato per finestra.
#include "res://assets/shaders/noise.gdshaderinc"
varying vec2 pane;
varying float variation;
void vertex() {
	pane = VERTEX.xy + 0.5;
	variation = apollo_hash(MODEL_MATRIX[3].xz);
}
void fragment() {
	vec3 tint = apollo_to_linear(COLOR.rgb);
	float sky = smoothstep(0.12, 0.9, pane.y);
	vec3 room = tint * (0.30 + variation * 0.18);
	vec3 reflection = mix(tint * 0.65, tint * 1.25 + vec3(0.025), sky);
	float cloud = smoothstep(0.56, 0.72, apollo_noise(pane * vec2(2.0, 3.0) + variation * 11.0));
	reflection = mix(reflection, tint * 1.3 + vec3(0.04), cloud * 0.25);
	float curtain = (1.0 - smoothstep(0.04, 0.21, pane.x)) + smoothstep(0.79, 0.96, pane.x);
	vec3 color = mix(room, reflection, 0.68 + variation * 0.18);
	color = mix(color, vec3(0.34, 0.31, 0.24), curtain * step(0.62, variation) * 0.5);
	ALBEDO = color;
	METALLIC = 0.18;
	ROUGHNESS = 0.2;
	SPECULAR = 0.7;
}

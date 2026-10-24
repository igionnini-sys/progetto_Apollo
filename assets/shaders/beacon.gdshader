shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// Colonna di luce della destinazione: sfuma verso l'alto e pulsa piano.
uniform vec4 tint : source_color = vec4(0.45, 0.95, 0.85, 1.0);
uniform float pulse = 1.0;

varying float height;

void vertex() {
	height = VERTEX.y + 0.5;
}

void fragment() {
	float rim = 1.0 - abs(dot(NORMAL, VIEW));
	float fade = (1.0 - smoothstep(0.0, 1.0, height)) * (0.35 + rim * 0.65);
	float wave = 0.75 + 0.25 * sin(TIME * 2.0 * pulse - height * 8.0);
	ALBEDO = tint.rgb * fade * mix(1.0, wave, pulse) * 0.55;
}

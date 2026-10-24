shader_type canvas_item;
// Vignettatura morbida per incorniciare la scena di guida.
uniform float amount = 0.28;

void fragment() {
	vec2 centered = UV - 0.5;
	centered.x *= 1.4;
	float shade = smoothstep(0.35, 0.95, length(centered)) * amount;
	COLOR = vec4(0.03, 0.07, 0.10, shade);
}

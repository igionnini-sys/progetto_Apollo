shader_type spatial;
// Scanalature del battistrada in UV: il dettaglio si attenua senza aliasing a distanza.
uniform vec3 rubber : source_color = vec3(0.075, 0.085, 0.09);
void fragment() {
	float width = max(fwidth(UV.x) * 58.0, 0.015);
	float zigzag = abs(fract(UV.y * 4.0) - 0.5);
	float tread = abs(fract(UV.x * 58.0 + zigzag * 0.45) - 0.5);
	float groove = 1.0 - smoothstep(0.035, 0.035 + width, tread);
	float band = smoothstep(0.18, 0.38, UV.y) * (1.0 - smoothstep(0.62, 0.82, UV.y));
	float fade = 1.0 - smoothstep(0.08, 0.4, fwidth(UV.x) * 58.0);
	ALBEDO = rubber * (1.0 - groove * band * fade * 0.45);
	ROUGHNESS = 0.88;
	SPECULAR = 0.25;
}

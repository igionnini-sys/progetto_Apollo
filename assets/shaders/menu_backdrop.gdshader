shader_type canvas_item;
// Sfondo dei menu: scena sfocata e velata; l'alfa del ColorRect regola l'intensità.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.06, 0.16, 0.22);

void fragment() {
	float strength = COLOR.a;
	// Sotto 0,3 (pannelli laterali) la scena resta nitida.
	float blur = max(strength - 0.3, 0.0) * 5.6;
	vec3 blurred = textureLod(screen_texture, SCREEN_UV, blur).rgb;
	vec2 centered = SCREEN_UV - 0.5;
	float vignette = smoothstep(0.85, 0.25, length(centered));
	vec3 c = mix(blurred, tint, strength * 0.55);
	c *= mix(1.0, 0.75 + vignette * 0.25, strength);
	COLOR = vec4(c, 1.0);
}

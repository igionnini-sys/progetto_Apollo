// Rumore procedurale condiviso: nessuna texture esterna.
// Hash senza seno: stabile rispetto agli arrotondamenti dei compilatori GPU,
// quindi i valori ai vertici delle celle coincidono da entrambi i lati (niente gradini).
float apollo_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float apollo_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(apollo_hash(i), apollo_hash(i + vec2(1.0, 0.0)), u.x),
		mix(apollo_hash(i + vec2(0.0, 1.0)), apollo_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float apollo_fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * apollo_noise(p);
		p = p * 2.03 + vec2(13.1, 7.7);
		amplitude *= 0.5;
	}
	return value;
}

vec3 apollo_to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

shader_type sky;
// Pannelli di luce fotografici: ambiente originale, senza HDRI esterne.
float softbox(vec3 ray, vec3 direction, float width, float height) {
	vec3 forward = normalize(direction);
	vec3 right = normalize(cross(forward, vec3(0.0, 1.0, 0.0)));
	vec3 up = cross(right, forward);
	float depth = dot(ray, forward);
	vec2 plane = vec2(dot(ray, right), dot(ray, up)) / max(depth, 0.001);
	vec2 edge = vec2(1.0) - smoothstep(vec2(width, height), vec2(width, height) + 0.035, abs(plane));
	return edge.x * edge.y * step(0.0, depth);
}
void sky() {
	vec3 base = mix(vec3(0.12, 0.14, 0.17), vec3(0.55, 0.59, 0.64), smoothstep(-0.5, 0.5, EYEDIR.y));
	float panels = softbox(EYEDIR, vec3(-0.8, 0.8, -0.6), 0.36, 0.65);
	panels += softbox(EYEDIR, vec3(0.7, 0.5, 0.3), 0.22, 0.8);
	panels += softbox(EYEDIR, vec3(0.0, 1.0, 0.2), 0.7, 0.4);
	COLOR = base + vec3(1.4) * panels;
}

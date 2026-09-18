shader_type canvas_item;

// Procedural deep-space backdrop: layered fbm nebula clouds + twinkling star specks.
// Drifts with the camera (parallax) so the world feels bigger than the arena.
uniform vec2 cam_pos = vec2(0.0);
uniform float time_s = 0.0;
uniform vec3 tint_a : source_color = vec3(0.10, 0.06, 0.28);
uniform vec3 tint_b : source_color = vec3(0.04, 0.16, 0.30);
uniform vec3 tint_c : source_color = vec3(0.28, 0.06, 0.20);
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash2(i).x;
	float b = hash2(i + vec2(1.0, 0.0)).x;
	float c = hash2(i + vec2(0.0, 1.0)).x;
	float d = hash2(i + vec2(1.0, 1.0)).x;
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 5; i++) {
		v += amp * noise(p);
		p = rot * p * 2.03 + vec2(1.7, 9.2);
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = SCREEN_UV * res;
	vec2 world = (px + cam_pos * 0.12) / 900.0;

	float n1 = fbm(world * 1.4 + vec2(time_s * 0.004, 0.0));
	float n2 = fbm(world * 2.6 + vec2(3.1, -time_s * 0.006));
	float n3 = fbm(world * 0.7 + vec2(-7.0, 2.0));

	vec3 base = vec3(0.006, 0.009, 0.024);
	float cloud1 = smoothstep(0.42, 0.78, n1) * 0.55;
	float cloud2 = smoothstep(0.48, 0.82, n2) * 0.35;
	float cloud3 = smoothstep(0.40, 0.75, n3) * 0.45;
	vec3 col = base;
	col += tint_a * cloud1 * intensity;
	col += tint_b * cloud2 * intensity;
	col += tint_c * cloud3 * cloud1 * 2.0 * intensity;

	// Star specks (fine grid, sparse)
	vec2 sp = (px + cam_pos * 0.2) / 3.0;
	vec2 cell = floor(sp);
	vec2 h = hash2(cell);
	if (h.x > 0.994) {
		float tw = 0.6 + 0.4 * sin(time_s * (1.5 + h.y * 3.0) + h.y * 20.0);
		float d = length(fract(sp) - 0.5);
		float star = smoothstep(0.35, 0.0, d) * tw * (0.5 + h.y);
		col += vec3(0.7, 0.85, 1.0) * star * 0.55;
	}

	COLOR = vec4(col, 1.0);
}

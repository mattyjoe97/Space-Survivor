shader_type canvas_item;
render_mode blend_mix;

// Screen-space post effects for Space Survivors.
// vignette + subtle chromatic aberration (spikes on hits) + low-hull danger pulse + faint grain.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.42;
uniform float aberration : hint_range(0.0, 1.0) = 0.0;
uniform float danger : hint_range(0.0, 1.0) = 0.0;
uniform float grain : hint_range(0.0, 0.2) = 0.035;
uniform float time_s = 0.0;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv - 0.5;
	float r = length(centered);

	// Chromatic aberration: sample channels with radial offset.
	float ab = aberration * 0.012 * (0.3 + r * 2.0);
	vec2 dir = normalize(centered + vec2(0.0001));
	float cr = texture(screen_tex, uv + dir * ab).r;
	float cg = texture(screen_tex, uv).g;
	float cb = texture(screen_tex, uv - dir * ab).b;
	vec3 col = vec3(cr, cg, cb);

	// Vignette
	float vig = smoothstep(0.35, 0.95, r);
	col *= 1.0 - vig * vignette_strength;

	// Danger pulse: red tint creeping in from the edges when hull is low.
	if (danger > 0.001) {
		float pulse = 0.55 + 0.45 * sin(time_s * 6.0);
		float edge = smoothstep(0.35, 0.85, r) * danger * pulse;
		col = mix(col, vec3(0.9, 0.08, 0.12), edge * 0.55);
	}

	// Film grain
	float g = (hash12(uv * vec2(1280.0, 720.0) + vec2(time_s * 60.0)) - 0.5) * grain;
	col += g;

	COLOR = vec4(col, 1.0);
}

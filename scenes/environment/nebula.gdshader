shader_type canvas_item;

global uniform float nebula_time;
uniform vec4 primary_color : source_color = vec4(0.2, 0.1, 0.5, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.8, 0.2, 0.4, 1.0);
uniform vec4 accent_color : source_color = vec4(0.1, 0.6, 0.9, 1.0);
uniform float density : hint_range(0.1, 2.0) = 1.0;
uniform float detail_scale : hint_range(1.0, 10.0) = 4.0;
uniform float movement_speed : hint_range(0.0, 0.5) = 0.02;
uniform float edge_softness : hint_range(0.1, 1.0) = 0.4;
uniform float brightness : hint_range(0.5, 3.0) = 1.2;
uniform float wispy_intensity : hint_range(0.0, 1.0) = 0.6;
uniform vec2 world_offset = vec2(0.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	for (int i = 0; i < octaves; i++) {
		value += amplitude * noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

float ridged_noise(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	float prev = 1.0;
	
	for (int i = 0; i < octaves; i++) {
		float n = 1.0 - abs(noise(p * frequency) * 2.0 - 1.0);
		n = n * n;
		n *= prev;
		prev = n;
		value += amplitude * n;
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 world_uv = UV + world_offset * 0.0005;
	float t = nebula_time;
	
	float base_noise = fbm(world_uv * detail_scale, 3);
	float ridges = ridged_noise(world_uv * detail_scale * 0.7, 2);
	float wisps = ridged_noise(world_uv * detail_scale * 1.2 + vec2(t * movement_speed), 2);
	
	float nebula_shape = base_noise * 0.5 + ridges * 0.3 + wisps * wispy_intensity * 0.2;
	nebula_shape = smoothstep(0.2, 0.8, nebula_shape);
	
	float edge_fade = smoothstep(0.0, 0.25, UV.x) * smoothstep(1.0, 0.75, UV.x);
	edge_fade *= smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.75, UV.y);
	
	float color_var1 = fbm(world_uv * 2.0, 2);
	float color_var2 = fbm(world_uv * 3.0 + 5.0, 2);
	
	vec3 col = mix(primary_color.rgb, secondary_color.rgb, color_var1);
	col = mix(col, accent_color.rgb, color_var2 * 0.3);
	
	float glow = pow(nebula_shape, 0.7) * 0.4;
	col += glow * vec3(1.0, 0.9, 0.95);
	
	col *= brightness;
	
	float alpha = nebula_shape * edge_fade * density;
	alpha = clamp(alpha, 0.0, 0.85);
	
	COLOR = vec4(col, alpha);
}

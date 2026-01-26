shader_type canvas_item;

uniform float time : hint_range(0.0, 1000.0) = 0.0;
uniform int galaxy_type : hint_range(0, 2) = 0; // 0=spiral, 1=elliptical, 2=irregular
uniform float arm_count : hint_range(2.0, 6.0) = 2.0;
uniform float arm_tightness : hint_range(0.1, 1.0) = 0.4;
uniform float rotation_speed : hint_range(0.0, 0.5) = 0.02;
uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform vec4 arm_color : source_color = vec4(0.4, 0.6, 1.0, 1.0);
uniform float core_size : hint_range(0.05, 0.4) = 0.15;
uniform float brightness : hint_range(0.1, 2.0) = 1.0;

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
	for (int i = 0; i < octaves; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

float spiral_galaxy(vec2 uv, float t) {
	vec2 centered = uv - 0.5;
	float dist = length(centered);
	float angle = atan(centered.y, centered.x) + t * rotation_speed;
	
	// Core glow
	float core = exp(-dist * dist / (core_size * core_size * 2.0));
	
	// Spiral arms
	float spiral_angle = angle + dist * arm_tightness * 10.0;
	float arms = pow(0.5 + 0.5 * sin(spiral_angle * arm_count), 3.0);
	
	// Arm falloff with distance
	float arm_envelope = exp(-dist * 2.5) * (1.0 - exp(-dist * 8.0));
	arms *= arm_envelope;
	
	// Add some noise to arms for detail
	float arm_noise = fbm(centered * 8.0 + vec2(t * 0.1), 3);
	arms *= 0.7 + arm_noise * 0.6;
	
	return core + arms * 0.6;
}

float elliptical_galaxy(vec2 uv) {
	vec2 centered = uv - 0.5;
	centered.x *= 1.5; // Elliptical shape
	float dist = length(centered);
	
	// Smooth falloff
	float glow = exp(-dist * dist / 0.08);
	
	// Add subtle noise
	float n = fbm(centered * 6.0, 2);
	glow *= 0.8 + n * 0.4;
	
	return glow;
}

float irregular_galaxy(vec2 uv, float t) {
	vec2 centered = uv - 0.5;
	float dist = length(centered);
	
	// Base shape from noise
	float n1 = fbm(centered * 4.0 + vec2(t * 0.05), 4);
	float n2 = fbm(centered * 8.0 - vec2(t * 0.03), 3);
	
	float shape = n1 * 0.6 + n2 * 0.4;
	shape *= exp(-dist * 3.0);
	
	// Bright knots
	float knots = pow(fbm(centered * 12.0, 2), 2.0) * exp(-dist * 4.0);
	
	return shape + knots * 0.5;
}

void fragment() {
	float intensity = 0.0;
	float t = time;
	
	if (galaxy_type == 0) {
		intensity = spiral_galaxy(UV, t);
	} else if (galaxy_type == 1) {
		intensity = elliptical_galaxy(UV);
	} else {
		intensity = irregular_galaxy(UV, t);
	}
	
	// Color mixing based on distance from center
	vec2 centered = UV - 0.5;
	float dist = length(centered);
	float core_blend = exp(-dist * dist / (core_size * core_size * 3.0));
	
	vec3 final_color = mix(arm_color.rgb, core_color.rgb, core_blend);
	float alpha = intensity * brightness;
	
	// Soft edges
	alpha *= smoothstep(0.5, 0.3, dist);
	
	COLOR = vec4(final_color, alpha * COLOR.a);
}

shader_type canvas_item;

uniform float time : hint_range(0.0, 10000.0) = 0.0;
uniform float drift_speed : hint_range(0.0, 5.0) = 1.0;
uniform float turbulence : hint_range(0.0, 1.0) = 0.3;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.4;
uniform float pulse_intensity : hint_range(0.0, 1.0) = 0.2;

varying float v_particle_type;

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

void vertex() {
	float drift_offset = INSTANCE_CUSTOM.x;
	float drift_phase = INSTANCE_CUSTOM.y;
	float particle_type = INSTANCE_CUSTOM.z;
	
	v_particle_type = particle_type;
	
	float t = time * drift_speed * 0.1;
	
	float drift_x = sin(t * 0.7 + drift_offset * 6.28318) * 3.0;
	float drift_y = cos(t * 0.5 + drift_phase * 6.28318) * 2.0;
	
	float turb_x = noise(vec2(drift_offset * 10.0, t * 0.3)) * 2.0 - 1.0;
	float turb_y = noise(vec2(drift_phase * 10.0, t * 0.3 + 5.0)) * 2.0 - 1.0;
	
	float turb_scale = turbulence * (1.0 + particle_type * 2.0);
	VERTEX.x += drift_x + turb_x * turb_scale * 5.0;
	VERTEX.y += drift_y + turb_y * turb_scale * 5.0;
	
	float pulse = sin(t * 2.0 + drift_offset * 6.28318) * 0.5 + 0.5;
	COLOR.a *= 0.8 + pulse * pulse_intensity;
}

void fragment() {
	vec2 center = UV - vec2(0.5);
	float dist = length(center) * 2.0;
	
	float particle_type = v_particle_type;
	
	float core_alpha;
	float glow_alpha;
	
	if (particle_type > 0.5) {
		float wispy = 1.0 - smoothstep(0.0, 1.0, dist);
		wispy *= wispy;
		float edge_noise = noise(UV * 8.0 + vec2(time * 0.05)) * 0.3;
		core_alpha = wispy * (0.7 + edge_noise);
		glow_alpha = (1.0 - dist) * 0.3 * glow_intensity;
	} else {
		core_alpha = 1.0 - smoothstep(0.0, 0.6, dist);
		core_alpha = pow(core_alpha, 1.5);
		glow_alpha = (1.0 - smoothstep(0.3, 1.0, dist)) * 0.5 * glow_intensity;
	}
	
	float final_alpha = core_alpha + glow_alpha;
	final_alpha *= COLOR.a;
	
	vec3 glow_color = COLOR.rgb * (1.0 + glow_alpha * 0.5);
	
	COLOR = vec4(glow_color, final_alpha);
}

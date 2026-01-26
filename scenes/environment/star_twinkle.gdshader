shader_type canvas_item;

uniform float time : hint_range(0.0, 1000.0) = 0.0;

void vertex() {
	float twinkle_offset = INSTANCE_CUSTOM.x * 6.28318;
	float twinkle_speed = 1.5 + INSTANCE_CUSTOM.y * 2.0;
	float twinkle = (sin(time * twinkle_speed + twinkle_offset) + 1.0) * 0.5;
	COLOR.a *= 0.6 + twinkle * 0.4;
}

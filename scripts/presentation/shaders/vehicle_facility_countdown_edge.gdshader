shader_type canvas_item;
render_mode unshaded;

varying float instance_progress;
varying vec2 local_position;

void vertex() {
	instance_progress = INSTANCE_CUSTOM.r;
	local_position = VERTEX;
}

void fragment() {
	float clockwise_progress = fract(atan(local_position.x, -local_position.y) / (2.0 * PI) + 1.0);
	if (clockwise_progress > clamp(instance_progress, 0.0, 1.0)) {
		discard;
	}
}

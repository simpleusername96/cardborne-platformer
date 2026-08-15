shader_type canvas_item;
render_mode unshaded;

uniform vec4 edge_color : source_color = vec4(1.0);
uniform vec4 inactive_edge_color : source_color = vec4(1.0);
uniform float outline_pixels = 5.0;
uniform bool progress_enabled = false;

varying float instance_opacity;
varying float instance_progress;
varying float instance_active;

void vertex() {
	instance_opacity = INSTANCE_CUSTOM.a;
	instance_progress = INSTANCE_CUSTOM.r;
	instance_active = INSTANCE_CUSTOM.g;
}

void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * outline_pixels;
	float center = texture(TEXTURE, UV).a;
	float neighbor = 0.0;
	neighbor = max(neighbor, texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV + step_uv).a);
	neighbor = max(neighbor, texture(TEXTURE, UV - step_uv).a);
	neighbor = max(neighbor, texture(TEXTURE, UV + vec2(step_uv.x, -step_uv.y)).a);
	neighbor = max(neighbor, texture(TEXTURE, UV + vec2(-step_uv.x, step_uv.y)).a);
	float edge = max(0.0, neighbor - center);
	vec4 resolved_edge_color = edge_color;
	if (progress_enabled && instance_active < 0.5) {
		resolved_edge_color = inactive_edge_color;
	} else if (progress_enabled) {
		vec2 centered = UV - vec2(0.5);
		float clockwise_progress = fract(atan(centered.x, -centered.y) / (2.0 * PI) + 1.0);
		edge *= step(clockwise_progress, clamp(instance_progress, 0.0, 1.0));
	}
	COLOR = vec4(
		resolved_edge_color.rgb,
		edge * resolved_edge_color.a * instance_opacity
	);
}

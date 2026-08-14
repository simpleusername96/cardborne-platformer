shader_type canvas_item;
render_mode unshaded;

uniform vec4 edge_color : source_color = vec4(1.0);
uniform float outline_pixels = 5.0;

varying float instance_opacity;

void vertex() {
	instance_opacity = INSTANCE_CUSTOM.a;
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
	COLOR = vec4(edge_color.rgb, edge * edge_color.a * instance_opacity);
}

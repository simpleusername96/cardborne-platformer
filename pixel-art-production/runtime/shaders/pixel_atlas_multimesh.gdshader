shader_type canvas_item;
render_mode unshaded;

uniform sampler2D atlas_texture : source_color, filter_nearest, repeat_disable;

void vertex() {
	UV = INSTANCE_CUSTOM.xy + UV * INSTANCE_CUSTOM.zw;
}

void fragment() {
	COLOR *= texture(atlas_texture, UV);
}

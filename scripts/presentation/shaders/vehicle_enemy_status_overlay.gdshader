shader_type canvas_item;
render_mode unshaded;

// One shared compositor keeps status color inside the authored actor alpha.
// INSTANCE_CUSTOM carries semantic RGB plus the bounded colorization weight.
varying vec4 instance_modulate;
varying vec4 status_overlay;

void vertex() {
	instance_modulate = COLOR;
	status_overlay = INSTANCE_CUSTOM;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	vec3 base_color = texel.rgb * instance_modulate.rgb;
	float actor_alpha = texel.a * instance_modulate.a;
	float luminance = dot(base_color, vec3(0.299, 0.587, 0.114));
	vec3 colorized_planes = status_overlay.rgb * mix(0.58, 1.12, luminance);
	COLOR = vec4(
		mix(base_color, colorized_planes, clamp(status_overlay.a, 0.0, 1.0)),
		actor_alpha
	);
}

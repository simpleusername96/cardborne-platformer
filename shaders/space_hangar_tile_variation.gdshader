shader_type canvas_item;
render_mode unshaded;

// Re-orient the same seamless approved master per world cell. This breaks the
// obvious wallpaper repeat without inventing new colors or touching collision.
uniform float tile_world_size = 384.0;
uniform float variation_seed = 0.0;

varying vec2 pattern_position;


float cell_hash(vec2 cell) {
	return fract(
		sin(dot(cell + vec2(variation_seed), vec2(127.1, 311.7)))
		* 43758.5453
	);
}


void vertex() {
	pattern_position = VERTEX;
}


void fragment() {
	vec2 grid = pattern_position / tile_world_size;
	vec2 cell = floor(grid);
	vec2 local_uv = fract(grid);
	float variant = floor(cell_hash(cell) * 4.0);
	if (variant < 1.0) {
		local_uv.x = 1.0 - local_uv.x;
	} else if (variant < 2.0) {
		local_uv.y = 1.0 - local_uv.y;
	} else if (variant < 3.0) {
		local_uv = vec2(local_uv.y, 1.0 - local_uv.x);
	}
	COLOR = texture(TEXTURE, local_uv);
}

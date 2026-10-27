shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 8.0) = 2.5;
uniform float color_depth : hint_range(8.0, 64.0) = 24.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.55;
uniform float berserk_blend : hint_range(0.0, 1.0) = 0.0;

// 4x4 Bayer Dither Matrisi (Project Warlock / 90s DOS stili)
const float bayer4[16] = float[16](
	0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
   12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
	3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
   15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0
);

void fragment() {
	vec2 screen_res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 low_res = floor(screen_res / pixel_size);
	vec2 grid_uv = (floor(SCREEN_UV * low_res) + 0.5) / low_res;
	
	vec3 color = texture(screen_texture, grid_uv).rgb;
	
	// Berserk Modu: Sin City / Çizgi Roman tarzı aşırı kontrastlı siyah-beyaz, sadece kırmızılar parlar
	if (berserk_blend > 0.0) {
		float gray = dot(color, vec3(0.299, 0.587, 0.114));
		float red_dominance = max(0.0, color.r - max(color.g, color.b) * 1.4);
		vec3 bw_contrast = vec3(smoothstep(0.25, 0.75, gray));
		vec3 berserk_col = mix(bw_contrast, vec3(1.4, 0.05, 0.05), clamp(red_dominance * 3.5, 0.0, 1.0));
		color = mix(color, berserk_col, berserk_blend);
	}
	
	// Bayer 4x4 Dithering
	ivec2 pixel_coord = ivec2(floor(FRAGCOORD.xy / pixel_size)) % 4;
	int bayer_index = pixel_coord.y * 4 + pixel_coord.x;
	float dither = (bayer4[bayer_index] - 0.5) * (1.0 / color_depth) * dither_strength;
	
	// Renk derinliği kuantizasyonu (Retro DOS paleti)
	color += dither;
	color = floor(color * color_depth + 0.5) / color_depth;
	
	COLOR = vec4(color, 1.0);
}

shader_type canvas_item;

uniform float hue_shift = 0.0;

void fragment() {
	vec4 pixel = COLOR;
	float highest = max(pixel.r, max(pixel.g, pixel.b));
	float lowest = min(pixel.r, min(pixel.g, pixel.b));
	float chroma = highest - lowest;
	if (chroma > 0.001 && pixel.b > pixel.r && pixel.b > pixel.g) {
		float hue = fract(((pixel.r - pixel.g) / chroma + 4.0) / 6.0 + hue_shift);
		vec3 shifted = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
		pixel.rgb = lowest + chroma * shifted;
	}
	COLOR = pixel;
}
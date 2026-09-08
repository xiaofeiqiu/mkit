shader_type canvas_item;
render_mode unshaded;
varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

// The generated atlas has a magenta chroma backing. Remove it in the renderer;
// preserve the source image and feather antialiased boundaries without halos.
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float magenta = min(c.r, c.b) - c.g;
	float key = smoothstep(0.18, 0.42, magenta);
	c.a *= 1.0 - key;
	if (magenta > 0.06) {
		c.r = min(c.r, c.g + 0.14);
		c.b = min(c.b, c.g + 0.14);
	}
	COLOR = c * vertex_color;
}

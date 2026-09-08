shader_type canvas_item;
render_mode unshaded;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 d = TEXTURE_PIXEL_SIZE * 1.5;
	float edge = 0.0;
	edge = max(edge,texture(TEXTURE,UV+vec2(d.x,0)).a);
	edge = max(edge,texture(TEXTURE,UV-vec2(d.x,0)).a);
	edge = max(edge,texture(TEXTURE,UV+vec2(0,d.y)).a);
	edge = max(edge,texture(TEXTURE,UV-vec2(0,d.y)).a);
	vec3 ink = vec3(0.12,0.17,0.20);
	COLOR = vec4(mix(ink,c.rgb,c.a),max(c.a,edge*0.78))*tint;
}

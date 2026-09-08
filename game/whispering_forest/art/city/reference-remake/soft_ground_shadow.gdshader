shader_type canvas_item;
render_mode unshaded;
varying vec4 shadow_tint;

void vertex() { shadow_tint=COLOR; }

void fragment() {
	vec4 tint=shadow_tint;
	vec2 step_uv=TEXTURE_PIXEL_SIZE*1.1;
	float coverage=texture(TEXTURE,UV).a*0.28;
	coverage+=(texture(TEXTURE,UV+vec2(step_uv.x,0)).a+texture(TEXTURE,UV-vec2(step_uv.x,0)).a+texture(TEXTURE,UV+vec2(0,step_uv.y)).a+texture(TEXTURE,UV-vec2(0,step_uv.y)).a)*0.13;
	coverage+=(texture(TEXTURE,UV+step_uv).a+texture(TEXTURE,UV-step_uv).a+texture(TEXTURE,UV+vec2(step_uv.x,-step_uv.y)).a+texture(TEXTURE,UV+vec2(-step_uv.x,step_uv.y)).a)*0.05;
	COLOR=vec4(tint.rgb,coverage*tint.a);
}

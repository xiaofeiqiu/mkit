shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;
uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 stone_color : source_color = vec4(0.80,0.80,0.73,1.0);
void fragment() {
	// Each modelled block samples stone within a mortar-free texture patch.
	// Keep the pale base while letting the actual stone grain remain visible.
	float grain=sqrt(dot(texture(paint,vec2(0.08,0.03)+UV*vec2(0.10,0.06)).rgb,vec3(0.25,0.60,0.15)));
	ALBEDO=stone_color.rgb*(0.61+grain*0.90)*COLOR.rgb;
	ROUGHNESS=1.0;
}

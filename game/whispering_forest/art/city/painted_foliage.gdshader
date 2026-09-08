shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;
uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 leaf_color : source_color = vec4(0.43,0.65,0.45,1.0);
void fragment() {
	float surface = dot(texture(paint, UV*0.48).rgb,vec3(0.25,0.60,0.15));
	ALBEDO = leaf_color.rgb*(0.88+surface*0.24)*COLOR.rgb;
	ROUGHNESS=1.0;
}

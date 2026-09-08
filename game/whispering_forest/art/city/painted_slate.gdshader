shader_type spatial;
render_mode diffuse_lambert, specular_disabled, cull_disabled;
uniform sampler2D paint : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 roof_color : source_color = vec4(0.24,0.37,0.5,1.0);
void fragment() {
	vec3 tex = texture(paint, UV).rgb;
	float value = dot(tex, vec3(0.299,0.587,0.114));
	ALBEDO = roof_color.rgb * (0.70 + sqrt(value) * 0.95) * COLOR.rgb;
	ROUGHNESS = 0.96;
}

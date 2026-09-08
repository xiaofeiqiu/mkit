shader_type canvas_item;
uniform float white_energy : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	texel.rgb = mix(texel.rgb, vec3(0.985, 1.0, 1.0), white_energy);
	COLOR *= texel;
}

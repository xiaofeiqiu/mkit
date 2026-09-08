shader_type spatial;
render_mode cull_disabled;
varying float ground_height;
varying vec3 local_point;
void vertex() {
	ground_height=(MODEL_MATRIX*vec4(VERTEX,1.0)).y;
	local_point=VERTEX;
}
void fragment() {
	if (ground_height < 0.0) discard;
	ALBEDO=COLOR.rgb;
	ROUGHNESS=0.48;
	SPECULAR=0.22;
	// Milky white frost; slight cold shading comes from the shared daylight.
	EMISSION=vec3(0.28,0.29,0.30);
}

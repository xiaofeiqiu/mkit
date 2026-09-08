shader_type spatial;
render_mode cull_disabled, specular_disabled;
varying vec3 surface_position;
float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
	vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
void vertex() { surface_position=VERTEX; }
void fragment() {
	float patches=noise(surface_position*7.0);
	float grain=noise(surface_position*83.0);
	float seam=1.0-smoothstep(0.025,0.06,abs(noise(surface_position*18.0)-0.43));
	float weather=0.70+0.28*patches+0.13*grain-0.14*seam;
	ALBEDO=COLOR.rgb*weather;
	ROUGHNESS=0.97;
}

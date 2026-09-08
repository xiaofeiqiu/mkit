shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 pigment : source_color = vec4(1.0);
uniform float leather = 0.0;
varying vec3 garment_position;

float grain(vec3 p) {
	vec3 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
	return mix(mix(sin(dot(i,vec3(13.1,31.7,7.1))),sin(dot(i+vec3(1,0,0),vec3(13.1,31.7,7.1))),f.x),mix(sin(dot(i+vec3(0,1,0),vec3(13.1,31.7,7.1))),sin(dot(i+vec3(1,1,0),vec3(13.1,31.7,7.1))),f.x),f.y);
}

void vertex() { garment_position=VERTEX; }

void fragment() {
	// Object-space variation follows the garment joint through every pose.
	// Broad paint and restrained weave survive the final 72 px silhouette;
	// no screen-space noise, animated grain, or sparkling normal map.
	vec3 p=garment_position;
	float broad=grain(p*15.0)*0.032;
	float weave=sin(p.x*220.0)*sin(p.y*220.0);
	float filter_out=1.0-smoothstep(0.25,0.9,max(length(dFdx(p)),length(dFdy(p)))*220.0);
	float variation=1.0+broad+weave*filter_out*0.009*(1.0-leather);
	ALBEDO=pigment.rgb*COLOR.rgb*variation;
	ROUGHNESS=mix(0.96,0.88,leather);
	SPECULAR=mix(0.08,0.16,leather);
}

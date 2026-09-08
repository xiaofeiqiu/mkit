shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D paint : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_paint = false;
uniform vec3 paint_mean = vec3(1.0);
uniform float paint_strength = 0.5;
uniform float surface_kind = 0.0; // 0 stone, 1 wood, 2 roof, 3 plaster, 4 leaf, 5 fittings
uniform float roughness_value = 0.92;
varying vec3 local_position;

float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise(vec3 p) {
	vec3 i=floor(p); vec3 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

void vertex() { local_position=VERTEX; }

void fragment() {
	vec3 p=local_position;
	vec3 tex=has_paint ? texture(paint,UV).rgb : vec3(1.0);
	float mottling=noise(p*3.2)*0.65+noise(p*12.0)*0.35;
	// Preserve the chosen material colour. Multiplying two dark albedos made
	// oak and shaded plaster unnaturally black even under daylight.
	vec3 pigment=mix(vec3(1.0),clamp(tex/max(paint_mean,vec3(0.025)),vec3(0.45),vec3(1.65)),paint_strength);
	vec3 albedo=base_color.rgb*pigment*COLOR.rgb;
	if (surface_kind<4.0) {
		albedo*=mix(0.86,1.06,mottling);
		float foot=exp(-max(p.y,0.0)*2.7)*smoothstep(0.42,0.78,noise(p*vec3(4.5,1.2,4.5)));
		albedo=mix(albedo,albedo*vec3(0.73,0.82,0.60),foot*0.31);
		if(surface_kind>1.5 && surface_kind<2.5) {
			float moss=smoothstep(0.76,0.89,noise(p*4.1));
			albedo=mix(albedo,albedo*vec3(0.91,1.07,0.73),moss*0.30);
		}
		float micro=noise(p*17.0)*0.12+dot(tex,vec3(0.333))*0.88;
		vec3 n=normalize(NORMAL);
		vec3 dx=dFdx(VERTEX),dy=dFdy(VERTEX);
		vec3 r1=cross(dy,n),r2=cross(n,dx);
		float det=dot(dx,r1);
		vec3 grad=sign(det)*(dFdx(micro)*r1+dFdy(micro)*r2);
		// Tile relief comes primarily from the solid overlapping geometry.
		// Millimetre-scale grain must not turn into high-contrast pixel noise.
		float relief=surface_kind<0.5 ? 0.012 : (surface_kind>1.5 && surface_kind<2.5 ? 0.0015 : 0.006);
		NORMAL=normalize(abs(det)*n-relief*grad);
	}
	ALBEDO=albedo;
	ROUGHNESS=roughness_value;
	SPECULAR=0.14;
}

shader_type canvas_item;
uniform sampler2D frame_a : source_color, filter_linear, repeat_disable;
uniform sampler2D frame_b : source_color, filter_linear, repeat_disable;
uniform vec4 region_a;
uniform vec4 region_b;
uniform vec4 placement_a;
uniform vec4 placement_b;
uniform float phase : hint_range(0.0, 1.0);
varying vec4 vertex_tint;

void vertex() { vertex_tint=COLOR; }

vec4 sample_frame(sampler2D source, vec4 region, vec4 placement, vec2 uv) {
	vec2 local=(uv-placement.xy)/placement.zw;
	if (local.x<0.0 || local.y<0.0 || local.x>1.0 || local.y>1.0) return vec4(0.0);
	return texture(source,region.xy+local*region.zw);
}

void fragment() {
	vec4 a=sample_frame(frame_a,region_a,placement_a,UV);
	vec4 b=sample_frame(frame_b,region_b,placement_b,UV);
	// Interpolate once in premultiplied space. Two separately translucent
	// sprites would make an opaque ice/stone body become 75% opaque mid-blend.
	float alpha=mix(a.a,b.a,phase);
	vec3 rgb=mix(a.rgb*a.a,b.rgb*b.a,phase)/max(alpha,0.00001);
	COLOR=vec4(rgb,alpha)*vertex_tint;
}

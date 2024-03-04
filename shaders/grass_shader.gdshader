shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,vertex_lighting;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float alpha_scissor_threshold;
uniform float roughness : hint_range(0,1);

//global uniform float fade_distance_min;
//global uniform float fade_distance_max;

global uniform float sway_speed;

void vertex() {
	ROUGHNESS=roughness;
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * (0.75*sway_speed) + UV.y) * ( 1.0 - UV.y) * 0.02;
	VERTEX.z += cos(NODE_POSITION_WORLD.z + TIME * (0.45*sway_speed) + UV.y) * ( 1.0 - UV.y) * 0.02;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA *= albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	
	//// fade logic
	//{
		//float fade_length = length(VERTEX);
		//const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);		float fade = clamp(smoothstep(fade_distance_max, fade_distance_min, fade_length), 0.0, 1.0);
		//if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			//discard;
		//}
	//}
}

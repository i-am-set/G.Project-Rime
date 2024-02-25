// NOTE: Shader automatically converted from Godot Engine 4.2.1.stable.mono's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_disabled;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform float roughness : hint_range(0,1);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

global uniform float fade_distance_min;
global uniform float fade_distance_max;

global uniform float sway_speed;
uniform float sway_strength = 0.05;
uniform float sway_phase_len = 8.0;

void vertex() {
	float strength = COLOR.r * sway_strength;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	VERTEX.x += sin(VERTEX.x * sway_phase_len * 1.123 + TIME * sway_speed) * strength;
	VERTEX.y += sin(VERTEX.y * sway_phase_len + TIME * sway_speed * 1.12412) * strength;
	VERTEX.z += sin(VERTEX.z * sway_phase_len * 0.9123 + TIME * sway_speed * 1.3123) * strength;
}






void fragment() {
	vec2 base_uv = UV;       
	vec4 albedo_tex = texture(texture_albedo,base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.1;
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	
	// fade logic
	{
		float fade_length = length(VERTEX);
		const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);		float fade = clamp(smoothstep(fade_distance_max, fade_distance_min, fade_length), 0.0, 1.0);
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}

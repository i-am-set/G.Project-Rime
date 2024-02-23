shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_noise;
uniform sampler2D tree_base_texture : source_color;
uniform sampler2D tree_base_noise_texture;
uniform float tree_base_height = 1;
uniform float tree_base_darkness = 0.2;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

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
	// apply the spots of the tree
	float f = clamp(NODE_POSITION_WORLD.y, 0.0, 1.0);
	f = clamp(f + texture(texture_noise, UV).r - 0.1, 0.0, 1.0);
	// apply base of tree texture
	vec3 localPos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz; // transform to object space
	float t = clamp(localPos.y - tree_base_height - NODE_POSITION_WORLD.y, 0.0, 1.0); // clamp y-coordinate to [0, 1]
	t = clamp(t + texture(tree_base_noise_texture, UV).r - 0.5, 0.0, 1.0);
	float q = smoothstep(0, 1.0, f*t);
	vec4 tree_base_tex = texture(tree_base_texture, UV);
	tree_base_tex.rgb *= tree_base_darkness;
	
	// apply the rest
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = mix(tree_base_tex, albedo_tex, q).rgb * albedo.rgb;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	NORMAL_MAP = texture(texture_normal,base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	
	
	// fade logic
	{
		float fade_length = length(VERTEX);
		const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);		float fade = clamp(smoothstep(fade_distance_min, fade_distance_max, fade_length), 0.0, 1.0);
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}

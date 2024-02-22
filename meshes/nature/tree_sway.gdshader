shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled, world_vertex_coords;
uniform vec4 albedo : source_color;
uniform sampler2D normal_texture : source_color;
uniform vec4 transmission : source_color;
global uniform float fade_distance;

uniform float sway_speed = 1.0;
uniform float sway_strength = 0.05;
uniform float sway_phase_len = 8.0;

void vertex() {
    float strength = COLOR.r * sway_strength;
    VERTEX.x += sin(VERTEX.x * sway_phase_len * 1.123 + TIME * sway_speed) * strength;
    VERTEX.y += sin(VERTEX.y * sway_phase_len + TIME * sway_speed * 1.12412) * strength;
    VERTEX.z += sin(VERTEX.z * sway_phase_len * 0.9123 + TIME * sway_speed * 1.3123) * strength;
}
void fragment() {
	vec4 albedo_tex = albedo;
	vec4 normal_tex = texture(normal_texture, UV);
	// Calculate the distance from the camera to the fragment
	float distance_to_camera = length(INV_VIEW_MATRIX[1].xyz - VERTEX);
	// Calculate the fade factor based on the distance
	float fade_factor = smoothstep(fade_distance+20.0, fade_distance - 1.0, distance_to_camera);
	ALBEDO = albedo_tex.rgb;
	METALLIC = 0.0;
	ROUGHNESS = 0.75;
	NORMAL_MAP = normal_tex.rgb;
	EMISSION = transmission.rgb;
	ALPHA *= fade_factor;
}
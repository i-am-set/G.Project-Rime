shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_linear_mipmap,repeat_enable;

uniform sampler2D texture_roughness : hint_roughness_r,filter_linear_mipmap,repeat_enable;
uniform float roughness : hint_range(0,1);

uniform sampler2D texture_normal : hint_roughness_normal,filter_linear_mipmap,repeat_enable;
uniform float normal_map_scale = 1.0;

uniform sampler2D parallax_map_texture;
uniform float parallax_map_scale = 0.1;

uniform float subsurface_scattering_scale = 0.5;

global uniform sampler2D heightmap;
global uniform sampler2D normalmap;
global uniform float amplitude;
global uniform vec3 clipmap_position;
global uniform float clipmap_partition_length;
global uniform float lod_step;

global uniform float fade_distance_min;
global uniform float fade_distance_max;

varying vec2 normalmap_position;
varying vec3 dev_albedo;

vec4 hash4( vec2 p ) { return fract(sin(vec4( 1.0+dot(p,vec2(37.0,17.0)), 
                                              2.0+dot(p,vec2(11.0,47.0)),
                                              3.0+dot(p,vec2(41.0,29.0)),
                                              4.0+dot(p,vec2(23.0,31.0))))*103.0); }

vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
    vec2 iuv = floor( uv );
    vec2 fuv = fract( uv );


    vec4 ofa = hash4( iuv + vec2(0.0,0.0) );
    vec4 ofb = hash4( iuv + vec2(1.0,0.0) );
    vec4 ofc = hash4( iuv + vec2(0.0,1.0) );
    vec4 ofd = hash4( iuv + vec2(1.0,1.0) );
    
    vec2 ddx = dFdx( uv );
    vec2 ddy = dFdy( uv );

    // transform per-tile uvs
    ofa.zw = sign(ofa.zw-0.5);
    ofb.zw = sign(ofb.zw-0.5);
    ofc.zw = sign(ofc.zw-0.5);
    ofd.zw = sign(ofd.zw-0.5);
    
    // uv's, and derivarives (for correct mipmapping)
    vec2 uva = uv*ofa.zw + ofa.xy; vec2 ddxa = ddx*ofa.zw; vec2 ddya = ddy*ofa.zw;
    vec2 uvb = uv*ofb.zw + ofb.xy; vec2 ddxb = ddx*ofb.zw; vec2 ddyb = ddy*ofb.zw;
    vec2 uvc = uv*ofc.zw + ofc.xy; vec2 ddxc = ddx*ofc.zw; vec2 ddyc = ddy*ofc.zw;
    vec2 uvd = uv*ofd.zw + ofd.xy; vec2 ddxd = ddx*ofd.zw; vec2 ddyd = ddy*ofd.zw;
        
    // fetch and blend
    vec2 b = smoothstep(0.25,0.75,fuv);
    
    return mix( mix( textureGrad( samp, uva, ddxa, ddya ), 
                     textureGrad( samp, uvb, ddxb, ddyb ), b.x ), 
                mix( textureGrad( samp, uvc, ddxc, ddyc ),
                     textureGrad( samp, uvd, ddxd, ddyd ), b.x), b.y );
}

float true_round(float value){
	return floor(value + 0.5);
}

float get_height(vec3 world_vertex){
	vec2 heightmap_position  = (world_vertex.xz + 0.5)/float(textureSize(heightmap,0).x);
	return texture(heightmap, heightmap_position ).r * amplitude;
}

void vertex(){
	dev_albedo = vec3(0.8, 0.8, 1);
	
	
	vec3 world_vertex = VERTEX + MODEL_MATRIX[3].xyz;
	normalmap_position = (world_vertex.xz + 0.5)/float(textureSize(heightmap,0).x);
	VERTEX.y = get_height(world_vertex);
	
	vec3 clipmap_vertex = world_vertex - clipmap_position;
	float lod = true_round(max(abs(clipmap_vertex.x), abs(clipmap_vertex.z))/clipmap_partition_length) * lod_step;
	
	float subdivision_length = min(pow(2,lod), clipmap_partition_length);
	
	vec3 fraction = fract((VERTEX + clipmap_partition_length / 2.0) / subdivision_length);

	VERTEX.y = mix(
		mix(
			get_height(world_vertex - vec3(fraction.x * subdivision_length, 0, 0)), 
			get_height(world_vertex + vec3((1.0-fraction.x) * subdivision_length, 0, 0)), 
			fraction.x
		), 
		mix(
			get_height(world_vertex - vec3(0, 0, fraction.z * subdivision_length)), 
			get_height(world_vertex + vec3(0, 0, (1.0-fraction.z) * subdivision_length)), 
			fraction.z
		), 
		ceil(fraction.z)
	);
}

void fragment() {
	//// Parallax Mapping
	//vec2 offset = texture(parallax_map_texture, UV).rg;
	//offset = (offset * 2.0 - 1.0) * parallax_map_scale;
	vec2 base_uv = UV;

	// Rughness
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	
	// Normal Map
	NORMAL_MAP = textureNoTile(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_map_scale;
	
	// Subsurface Scattering
	SSS_STRENGTH = subsurface_scattering_scale;
	
	// Albedo
	vec4 albedo_tex = textureNoTile(texture_albedo, base_uv);
	ALBEDO = albedo_tex.rgb * albedo.rgb; 
	
	// fade logic
	{
		float fade_length = length(VERTEX);
		const vec3 magic = vec3(0.06711056f, 0.00583715f, 52.9829189f);		float fade = clamp(smoothstep(fade_distance_max, fade_distance_min, fade_length), 0.0, 1.0);
		if (fade < 0.001 || fade < fract(magic.z * fract(dot(FRAGCOORD.xy, magic.xy)))) {
			discard;
		}
	}
}

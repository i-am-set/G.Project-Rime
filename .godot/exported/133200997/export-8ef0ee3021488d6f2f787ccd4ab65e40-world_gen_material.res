RSRC                    ShaderMaterial            ��������                                                  resource_local_to_scene    resource_name    code    script    render_priority 
   next_pass    shader    shader_parameter/roughness "   shader_parameter/normal_map_scale    shader_parameter/snow_color     shader_parameter/min_rock_slope     shader_parameter/max_snow_slope %   shader_parameter/min_rocksnow_height     shader_parameter/max_mud_height    shader_parameter/snow_texture    shader_parameter/rock_texture    shader_parameter/mud_texture %   shader_parameter/snow_normal_texture %   shader_parameter/rock_normal_texture $   shader_parameter/mud_normal_texture (   shader_parameter/snow_roughness_texture (   shader_parameter/rock_roughness_texture '   shader_parameter/mud_roughness_texture 	   
   Texture2D K   res://textures/nature/ground/snow/lowres/Snow010A_quarterRes-JPG_Color.jpg �4�� bN
   Texture2D K   res://textures/nature/ground/rock/low_res/Rock031_quarterRes-JPG_Color.jpg ʺRXo�
   Texture2D 6   res://textures/nature/ground/mud/Mud_1K-JPG_Color.jpg �����9�G
   Texture2D N   res://textures/nature/ground/snow/lowres/Snow010A_quarterRes-JPG_NormalDX.jpg !�ѵm��_
   Texture2D >   res://textures/nature/ground/rock/Rock031_1K-JPG_NormalGL.jpg ����It|
   Texture2D 9   res://textures/nature/ground/mud/Mud_1K-JPG_NormalGL.jpg 8:����� 
   Texture2D O   res://textures/nature/ground/snow/lowres/Snow010A_quarterRes-JPG_Roughness.jpg K�I���2
   Texture2D ?   res://textures/nature/ground/rock/Rock031_1K-JPG_Roughness.jpg ���W7.
   Texture2D :   res://textures/nature/ground/mud/Mud_1K-JPG_Roughness.jpg ��m�t      local://Shader_xfsc2 �         local://ShaderMaterial_yt264 �         Shader          �  shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform float roughness : hint_range(0,1);
uniform float normal_map_scale = 1.0;

uniform vec3 snow_color: source_color = vec3(0.79,0.87,0.95);
uniform sampler2D snow_texture: source_color,filter_nearest;
uniform sampler2D rock_texture: source_color,filter_nearest;
uniform sampler2D mud_texture: source_color,filter_nearest;
uniform sampler2D snow_normal_texture: source_color,filter_nearest;
uniform sampler2D rock_normal_texture: source_color,filter_nearest;
uniform sampler2D mud_normal_texture: source_color,filter_nearest;
uniform sampler2D snow_roughness_texture: source_color,filter_nearest;
uniform sampler2D rock_roughness_texture: source_color,filter_nearest;
uniform sampler2D mud_roughness_texture: source_color,filter_nearest;

uniform float min_rock_slope:hint_range(0.0,1.0) = 0.5;
uniform float max_snow_slope:hint_range(0.0,1.0) = 0.9;
uniform float min_rocksnow_height = -8.0;
uniform float max_mud_height = -6.0;

varying float normal_y;
varying float vertex_y;

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

void vertex(){
	normal_y = NORMAL.y;
	vertex_y = VERTEX.y;
}

void fragment(){
	vec2 base_uv = UV;
	vec2 snow_uv = base_uv * 20.0;
	
	//Albedo Values
	vec3 snow_albedo = snow_color * textureNoTile(snow_texture,snow_uv).xyz;
	vec3 rock_albedo = texture(rock_texture,base_uv * 20.0).xyz;
	vec3 mud_albedo = texture(mud_texture,base_uv * 80.0).xyz;
	//Normal Values
	vec3 snow_normal = textureNoTile(snow_normal_texture,snow_uv).xyz;
	vec3 rock_normal = texture(rock_normal_texture,base_uv).xyz;
	vec3 mud_normal = texture(mud_normal_texture,base_uv).xyz;
	//Normal Values
	vec3 snow_roughness = texture(snow_roughness_texture,snow_uv).xyz;
	vec3 rock_roughness = texture(rock_roughness_texture,base_uv).xyz;
	vec3 mud_roughness = texture(mud_roughness_texture,base_uv).xyz;
	//Weights
	float rock_snow_weight = normal_y;
	float mud_rocksnow_weight = vertex_y;
	//Calculating Rock/snow Weight
	rock_snow_weight = max(min_rock_slope, rock_snow_weight);
	rock_snow_weight = min(max_snow_slope, rock_snow_weight);
	rock_snow_weight -= min_rock_slope;
	rock_snow_weight /= max_snow_slope - min_rock_slope;
	//Calculating mud/RockSnow Weight
	mud_rocksnow_weight = max(min_rocksnow_height, mud_rocksnow_weight);
	mud_rocksnow_weight = min(max_mud_height, mud_rocksnow_weight);
	mud_rocksnow_weight -= min_rocksnow_height;
	mud_rocksnow_weight /= max_mud_height - min_rocksnow_height;
	//Mixing and Assigning Albedo
	vec3 rocksnow_albedo = mix(rock_albedo, snow_albedo, rock_snow_weight);
	vec3 rocksnow_normal = mix(rock_normal, snow_normal, rock_snow_weight);
	vec3 rocksnow_roughness = mix(rock_roughness, snow_roughness, rock_snow_weight);
	NORMAL_MAP = normalize(mix(mud_normal, rocksnow_normal, mud_rocksnow_weight));
	ROUGHNESS = mix(mud_roughness, rocksnow_roughness, mud_rocksnow_weight).r * roughness;
	NORMAL_MAP_DEPTH = normal_map_scale;
	ALBEDO = mix(mud_albedo, rocksnow_albedo, mud_rocksnow_weight);
}          ShaderMaterial                                        )   �������?        �?	      ��8?��^?��s?  �?
   )   H�z�G�?   )   �������?         �   )   ��(\��@                                                                                                                   RSRC
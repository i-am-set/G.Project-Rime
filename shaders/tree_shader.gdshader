shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;
uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color,filter_nearest,repeat_enable;
uniform sampler2D texture_noise;
uniform sampler2D tree_base_texture : source_color;
uniform sampler2D tree_base_noise_texture;
uniform float tree_base_height = 1;
uniform float tree_base_darkness = 0.2;
uniform float roughness : hint_range(0,1);
uniform sampler2D texture_roughness : hint_roughness_r,filter_nearest,repeat_enable;
uniform sampler2D texture_normal : hint_roughness_normal,filter_nearest,repeat_enable;
uniform float normal_scale : hint_range(-16,16);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;


global uniform float sway_speed;
uniform float sway_strength = 0.05;
uniform float sway_phase_len = 8.0;


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

void vertex() {
	float strength = COLOR.r * sway_strength;
	UV=UV*uv1_scale.xy+uv1_offset.xy;
	VERTEX.x += smoothstep(-1.0, 1.0, sin(VERTEX.x * sway_phase_len * 1.123 + TIME * sway_speed)) * strength;
	VERTEX.y += smoothstep(-1.0, 1.0, sin(VERTEX.y * sway_phase_len + TIME * sway_speed * 1.12412)) * strength;
	VERTEX.z += smoothstep(-1.0, 1.0, sin(VERTEX.z * sway_phase_len * 0.9123 + TIME * sway_speed * 1.3123)) * strength;
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
	vec4 albedo_tex = textureNoTile(texture_albedo, base_uv);
	ALBEDO = mix(tree_base_tex, albedo_tex, q).rgb * albedo.rgb;
	vec4 roughness_texture_channel = vec4(1.0,0.0,0.0,0.0);
	float roughness_tex = dot(texture(texture_roughness,base_uv),roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	NORMAL_MAP = textureNoTile(texture_normal, base_uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	

}

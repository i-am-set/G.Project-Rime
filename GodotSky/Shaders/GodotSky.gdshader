shader_type sky;
render_mode use_half_res_pass, use_quarter_res_pass;

uniform vec4 baseColor : source_color = vec4(0.052192,0.101373,0.192708,1.0);
uniform sampler2D scatteringLUT;
uniform vec3 scatterColor : source_color = vec3(1.0);
uniform vec3 scatterColor2 : source_color = vec3(1.0);

// Bools
uniform bool bAnimClouds = true;
//uniform bool bStaticClouds = true; *DEPRECATED*
uniform bool bAnimStars = true;
uniform int cloudType = 0;

// Sun
uniform float sunRadius;
uniform float sunEdgeBlur;
uniform vec3 sunDiscColor : source_color;
uniform vec4 sunGlowColor : source_color;
uniform vec3 sunlightColor;
uniform float sunGlowIntensity;

// Moon
uniform float moonRadius;
uniform float moonEdgeBlur;
uniform vec4 moonGlowColor : source_color;
uniform vec3 moonLightColor;
uniform float moonGlowIntensity;

// 2D Clouds
uniform vec3 baseCloudColor : source_color = vec3(1.0);
uniform float cloudDensity : hint_range(5.0, 10.0, 0.05) = 7.0;
uniform float cloudEdge : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float cloudCoverage : hint_range(-1.0,1.0,0.01) = 0.0;
uniform vec2 cloudDirection = vec2(1.0,1.0);
uniform sampler2D cloudTexture;
uniform sampler2D cloudTexture2;
uniform sampler2D cloudNoise;
uniform sampler2D weatherMap;
uniform float mgSize : hint_range(0.5, 0.99, 0.01) = 0.92;
uniform float cloudAlpha : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float cloudSpeed = 0.001;
uniform float absorption : hint_range(0.0, 5.0, 0.1) = 5.0;
uniform float henyeyGreensteinLevel : hint_range(0.5, 0.75, 0.01) = 0.69;
uniform float dynamicCloudBrightness : hint_range(0.5, 1.0, 0.01) = 0.9;
uniform float horizonUVCurve : hint_range(0.5, 1.0, 0.01);

// Horizon
uniform vec4 horizonFogColor : source_color;
uniform float horizonAlpha : hint_range(0.0, 1.0, 0.1) = 1.0;
uniform float horizonSize : hint_range(1.0, 7.0, 0.1);

// Stars
uniform sampler2D starTexture;
uniform sampler2D starNoise;
uniform vec3 starColor : source_color;
uniform float starBrightness : hint_range(0.0, 0.5, 0.01) = 0.2;
uniform float twinkleSpeed : hint_range(0.0, 0.05, 0.001) = 0.025;
uniform float twinkleScale : hint_range(0.5, 5.0, 0.1) = 4.0;
uniform float starResolution : hint_range(-1.0, 3.0, 1.0) = 2.0;
uniform float starSpeed = 0.002;

const vec3 camPos = vec3(0.0,1.0,0.0); 

float remap(float v, float minOld, float maxOld, float minNew, float maxNew) {
    return minNew + (v-minOld) * (maxNew - minNew) / (maxOld-minOld);
}

// Phase function
float henyey_greenstein(float cos_theta, float g) {
	const float k = 0.0795774715459;
	return k * (1.0 - g * g) / (pow(1.0 + g * g - 2.0 * g * cos_theta, 1.5));
}

// Create sun and moon discs based on the directional lights
vec3 createSunMoonDisc(vec3 dir, vec3 sunDir, vec3 color, float r, float edgeBlur) {
	float disc = 0.0;
	float discSizeCheck = (1.0 - (r * 2.0));
	if (dot(dir,sunDir) > discSizeCheck) {
		disc = pow((dot(dir,sunDir) - discSizeCheck) * edgeBlur,5.0);
	}
	vec3 discColored;
	discColored = clamp(vec3(disc) * color,0.0,1.0);
	return discColored;
}

vec3 createSunGlow(vec3 dir, vec3 sunDir, float r) {
	float sunGlow = 0.0;
	float glowSize = (1.0 - ((0.0003 * 800.0) * 2.0));
	if (dot(dir,sunDir) > glowSize) {
		sunGlow = mix(0.0,(dot(dir,sunDir) - glowSize * 1.05) * (1.0 - dir.y),sunGlowIntensity);
	}
	vec3 sunGlowFinal = clamp((pow(sunGlow - 0.1,1.0) * sunGlowColor.rgb),0.0,1.0) * sunGlowColor.a;
	return sunGlowFinal;
}

vec3 createMoonGlow(vec3 dir, vec3 moonDir, float r) {
	float moonGlow = 0.0;
	float glowSize = (1.0 - ((0.0003 * 400.0) * 2.0));
	if (dot(dir,moonDir) > glowSize) {
		moonGlow = mix(0.0,(dot(dir,moonDir) - glowSize),moonGlowIntensity);
	}
	vec3 moonGlowFinal = pow(vec3(moonGlow),vec3(3.0)) * moonGlowColor.rgb * moonGlowColor.a;
	return moonGlowFinal;
}

float createHorizonFog(vec3 vertexColor) {
	float clampedVertexColor = 0.0;
	if (vertexColor.y < 0.0) {
		clampedVertexColor = 1.0;
	}
	else { 
		clampedVertexColor = vertexColor.y;
	}
	float fogAlpha = clamp(pow((1.0 - clampedVertexColor),horizonSize) - (1.0 - horizonAlpha),0.0,1.0) * horizonFogColor.a ;
	return fogAlpha;
}

// Setup base light scattering with day and night
vec3 scatterLight(vec3 vertexColor, vec2 skyUV) {

	// Clamp lower hemisphere vertex normal Y (creates solid lower hemisphere color)
	float clampedVertexColor = 0.0;
	if (vertexColor.y < 0.0) { clampedVertexColor = 0.0001; }
	else { clampedVertexColor = vertexColor.y; }
	
	float vertexSlope = pow((1.0 - vertexColor.y),2.0);
	
	// Calculate SUN X and Y position on scattering LUT texture UV
	// Sun
	float UVx = mix(vertexSlope,1.0,0.5);
	float UVy = clamp(LIGHT0_DIRECTION.y / -2.0,-0.495,0.495) + 0.5;
	
	// Moon
	float UVx2 = mix(vertexSlope,1.0,0.1);
	float UVy2 = clamp(LIGHT1_DIRECTION.y / 2.0,-0.495,0.495) + 0.5;
	
	// Sample scattering LUT lexture and apply scattercolor adjustment
	vec3 sunLightScattered = texture(scatteringLUT,vec2(UVx,UVy)).rgb * scatterColor;
	vec3 moonLightScattered = texture(scatteringLUT,vec2(UVx2,UVy2)).rgb * scatterColor2 + 0.15;
	vec3 lightScattered = sunLightScattered + moonLightScattered;
	lightScattered = lightScattered * baseColor.rgb;
	
	vec3 baseSkyColor = lightScattered;
	
	float a1 = 0.0;
	if (bAnimStars == true) {
		a1 = (TIME * starSpeed);
	}
	else {
		a1 = 0.0;
	}
	vec3 starMap = textureLod(starTexture, vec2(skyUV.x + a1,skyUV.y), starResolution).rgb;
	vec3 starMap2 = textureLod(starTexture, vec2(skyUV.x + a1,skyUV.y), starResolution + 1.0).rgb;
	
	vec2 animUV = vec2(vertexColor.x,vertexColor.z) * twinkleScale + (TIME * twinkleSpeed);

	starMap = min(starMap,starMap2 * 0.3) + ((clamp(starMap - (starMap2 * 1.3),0.0,1.0)) * (texture(starNoise,animUV / 4.0).r * 10.0 ));
	
	baseSkyColor += starMap * starColor * starBrightness; // Add stars
	
	return baseSkyColor;
}

vec3 generateStaticClouds(vec3 dir, vec3 pos, vec2 skyUV, vec3 sunDir, vec3 moonDir) {
	vec4 xyMask = vec4(0.0);
	float zMask = 0.0;
	
	float sR = clamp(sunDir.x * -1.0,0.0,1.0);
	float sG = clamp(sunDir.x,0.0,1.0);
	float sB = clamp(sunDir.z,0.0,1.0);
	float sA = clamp(sunDir.z * -1.0,0.0,1.0);
	float sZ = clamp(sunDir.y * -1.0,0.0,1.0);
	
	float mR = clamp(moonDir.x * -1.0,0.0,1.0);
	float mG = clamp(moonDir.x,0.0,1.0);
	float mB = clamp(moonDir.z,0.0,1.0);
	float mA = clamp(moonDir.z * -1.0,0.0,1.0);
	float mZ = clamp(moonDir.y * -1.0,0.0,1.0);
	
	xyMask = mix(vec4(sR,sG,sB,sA), vec4(mR,mG,mB,mA), clamp(sunDir.y * 6.0,0.0,1.0)) * 0.7;
	zMask =  mix(sZ,mZ,clamp(sunDir.y * 6.0,0.0,1.0)) * 0.7;
	
	float a1 = 0.0;
	if (bAnimClouds == true) {
		a1 = (TIME * cloudSpeed);
	}
	else {
		a1 = 0.0;
	}
	
	float cloudsAlpha = textureLod(cloudTexture,vec2(skyUV.x + a1,skyUV.y), -1.0).r;
	float cloudAlpha2 = textureLod(cloudTexture,vec2(skyUV.x + a1,skyUV.y), -1.0).g * zMask;
	vec4 cloudShading = xyMask * textureLod(cloudTexture2,vec2(skyUV.x + a1,skyUV.y), -1.0);
	float cloudShading2 = (cloudShading.r + cloudShading.g) + (cloudShading.b + cloudShading.a);
	float cloudMainShadingMask = pow(cloudAlpha2 + cloudShading2,1.2);
	
	float cloudShine = ((1.0 - cloudsAlpha) + pow(cloudAlpha2 + cloudShading2,2.5)) * 17.0 * createSunGlow(dir,sunDir, 0.5).r;
	
	vec3 clouds = vec3(cloudMainShadingMask,cloudShine,cloudsAlpha);
	
	return clouds;
}

vec2 generate2DClouds(vec3 dir, vec3 sunDir, vec3 moonDir) {
	float cloudsFinal = 0.0;
	
	float horizonCurve = dir.y / horizonUVCurve;
	float clouds = texture(cloudNoise,vec2(dir.x / horizonCurve, dir.z / horizonCurve) / 5.0 + (TIME * 4.0 * cloudSpeed * cloudDirection)).r;
	float density = remap(cloudDensity,0.0,8.0,0.0,1.0);
	clouds *= textureLod(cloudNoise,vec2(dir.x / horizonCurve, dir.z / horizonCurve) / 10.0 + (TIME * 4.0 * cloudSpeed * cloudDirection),-2.0).r;
	clouds = clamp(mix(cloudCoverage,cloudCoverage + 1.0,clouds),cloudCoverage,1.0);
	clouds = clamp(pow(clouds,1.0 + cloudEdge),0.0,1.0);
	float weather = texture(weatherMap,vec2(dir.x / horizonCurve, dir.z / horizonCurve) / 20.0 + (TIME * 6.0 * cloudSpeed * cloudDirection)).r + 0.5;
	float cloudFade = clamp(dir.y,0.0,1.0);
	cloudsFinal = clamp(clouds - (clamp(weather + 0.5,0.0,1.0) * (1.0 - cloudCoverage / 2.0)),0.0,1.0);
	float cloudsFinal2 = cloudsFinal * mix(5.0,cloudDensity,dir.y) * (cloudFade * 2.0);
	float transmittance = exp(-cloudsFinal2);
	return vec2(transmittance,weather);
}

vec3 generateSky(vec3 dir, vec3 pos, vec2 skyUV, vec3 sunDir, float sunEnergy, vec3 sunColor, vec3 moonDir, vec3 moonColor, float moonEnergy) {
	vec3 skyColor = vec3(0.0);
	vec3 cloudColors = vec3(0.0);
	vec3 cloudMask = vec3(0.0);
	vec2 dynClouds = vec2(0.0);
	float dynCloudAlpha = 1.0 - dynClouds.x;
	
	float horizonCurve = dir.y / horizonUVCurve;
	
	float fogA = createHorizonFog(dir);
	vec3 atmos = scatterLight(dir,skyUV);
	
	if (cloudType == 0) {
		cloudMask = generateStaticClouds(dir,pos,skyUV,sunDir,moonDir);
	}
	
	if (cloudType == 1) {
		dynClouds = generate2DClouds(dir,sunDir,moonDir);
		dynCloudAlpha = 1.0 - dynClouds.x;
		cloudMask = clamp(vec3(dynCloudAlpha * 7.0),0.0,1.0);
	}
	
	skyColor += atmos;
	skyColor += createSunMoonDisc(dir,sunDir,sunColor,sunRadius,sunEdgeBlur) * (1.0 - cloudMask.z * cloudAlpha);
	skyColor += createSunMoonDisc(dir,moonDir,moonColor,moonRadius,moonEdgeBlur) * (1.0 - cloudMask.z * cloudAlpha);
	
	if (cloudType == 0) {
		float density = clamp((cloudDensity) / 5.0,0.0,1.0);
		vec3 cloudColor = mix(atmos * mix(dir.y,1.15,0.5),vec3(0.0),density);
		vec3 cloudLight = sunlightColor * 1.4 * cloudColor;
		vec3 cloudShading = pow((cloudLight + (cloudLight * cloudMask.y)) * cloudMask.x,vec3(1.2));
		vec3 cloudFinal = mix(cloudShading,baseCloudColor,0.1);
		
		cloudColors = baseCloudColor * cloudMask.z * cloudMask.x;
		if (dot(dir,sunDir) > mgSize) {
			float cloudGlow = remap(dot(dir,sunDir),mgSize,1.0,0.0,1.0);
			vec3 cloudGlow2 = mix(vec3(1.0),sunlightColor * 5.0,pow(cloudGlow, 3.0));
			float cloudGlow3 = 1.0 - cloudMask.z * 0.9 + cloudMask.x * 0.25;
			cloudColors = baseCloudColor * cloudGlow2 * cloudMask.z * cloudMask.x;
		}
		if (dot(dir,moonDir) > mgSize) {
			float cloudGlow = remap(dot(dir,moonDir),mgSize,1.0,0.0,1.0);
			vec3 cloudGlow2 = mix(vec3(1.0),vec3(1.0) * 10.0,pow(cloudGlow, 4.0));
			float cloudGlow3 = 1.0 - cloudMask.z * 0.9 + cloudMask.x * 0.25;
			cloudColors = baseCloudColor * cloudGlow2 * cloudMask.z * cloudMask.x;
		}
		
		skyColor *= clamp((1.0 - pow(cloudMask.z,3.0) * cloudAlpha),0.0,1.0) ;
		skyColor += (cloudFinal * (pow(cloudMask.z,3.0) * (1.0 - clamp((1.0 - 1.25) * 2.0,0.0,1.0))) + cloudColors) * cloudAlpha;
	}
	
	if (cloudType == 1) {
		float sun = dot(normalize(LIGHT0_DIRECTION), dir);
		float moon = dot(normalize(LIGHT1_DIRECTION), dir);
		skyColor = skyColor * dynClouds.x + (baseCloudColor * dynamicCloudBrightness * dynCloudAlpha);
		float hg = max(henyey_greenstein(sun,henyeyGreensteinLevel - 0.15),henyey_greenstein(moon,henyeyGreensteinLevel + 0.05));
		skyColor = skyColor + ((baseCloudColor * ((dynClouds.x) * hg * absorption)) * dynCloudAlpha);
		skyColor -= (clamp(texture(cloudNoise,vec2(dir.x / horizonCurve, dir.z / horizonCurve) / 5.0 + (TIME * 4.0 * cloudSpeed  * cloudDirection)).r - 0.5,0.0,1.0) *  baseCloudColor) * dynCloudAlpha;
	}
	
	skyColor = mix(skyColor,horizonFogColor.rgb * horizonFogColor.a,fogA) + createSunMoonDisc(dir,sunDir,sunColor,sunRadius,sunEdgeBlur) * (1.0 - cloudMask.z * cloudAlpha) + createSunMoonDisc(dir,moonDir,moonColor,moonRadius,moonEdgeBlur) * (1.0 - cloudMask.z * cloudAlpha);
	if (dir.y < 0.0) {
		skyColor = horizonFogColor.rgb;
	}
	skyColor += createSunGlow(dir,sunDir,sunRadius);
	skyColor += createMoonGlow(dir,moonDir,moonRadius);
	
	return skyColor;
}

void sky() {
	vec3 rayDirection = EYEDIR;
	
	vec3 background = horizonFogColor.rgb * horizonFogColor.a;
	
	if (rayDirection.y > 0.0) {
		background = generateSky(rayDirection, camPos, SKY_COORDS, LIGHT0_DIRECTION, LIGHT0_ENERGY, sunDiscColor, LIGHT1_DIRECTION, LIGHT1_COLOR, LIGHT1_ENERGY);
	}
	
	if (AT_QUARTER_RES_PASS && AT_CUBEMAP_PASS) {
		COLOR = background.rgb;
	} else if (AT_HALF_RES_PASS && !AT_CUBEMAP_PASS) {
		COLOR = background.rgb;
	} else if (AT_CUBEMAP_PASS) {
		COLOR = QUARTER_RES_COLOR.rgb;
	} else {
		COLOR = background.rgb;
	}
}
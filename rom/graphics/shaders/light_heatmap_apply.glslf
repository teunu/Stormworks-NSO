#include "depth_utils.glslh"
#include "lighting_common.glslh"
#include "environment_lighting.glslh"

//in float log_z;
//in vec4 screen_pos_out;
in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D gcolor;
uniform sampler2D water_depth;
uniform sampler2D texture_heatmap;

uniform mat4 mat_view_proj_inverse;

uniform mat4 mat_world_to_heatmap;

uniform vec4 light_pos_range;
uniform vec3 light_color;

uniform vec3 camera_position;
uniform float fog_density;
uniform vec2 rand_offset;

uniform int is_render_halo;

uniform int is_underwater;
uniform vec3 underwater_color;
uniform vec3 sky_color_horizon;
uniform vec3 sky_color_zenith;

float rand(vec2 co) // returns -1 -> +1
{
	return (fract(sin(dot(co.xy + rand_offset, vec2(12.9898,78.233))) * 43758.5453) * 2.0) - 1.0;
}

void main()
{
	vec2 tex_coord = vertex_coord0_out;

    vec3 surface_color = vec3(0.0);

	float depth = decode_depth_delinear(texture(gdepth, tex_coord).r);

    vec3 position = world_pos_from_depth(mat_view_proj_inverse, tex_coord, depth);





	//Heatmap
	vec4 heatmap_coord = mat_world_to_heatmap * vec4(position, 1.0);
	heatmap_coord /= heatmap_coord.w;
	vec2 heat_tex_coord = heatmap_coord.xy * 0.5 + 0.5;
	vec4 heatmap_value = vec4(0.0, 0.0, 0.0, 0.0);
	if(heat_tex_coord.x > 0.0 && heat_tex_coord.x < 1.0 && heat_tex_coord.y > 0.0 && heat_tex_coord.y < 1.0)
	{
		heatmap_value = texture(texture_heatmap, heat_tex_coord.xy);
		heatmap_value.xyz = heatmap_value.xyz / heatmap_value.w;
	}
	else
	{
		discard;
	}

	if(heatmap_value.w < 0.001)
	{
		discard;
	}

	//New
	float intensity = log(heatmap_value.w + 1);
	//float intensity = heatmap_value.w;
	float y_delta =  position.y - heatmap_value.y;
	intensity = mix(intensity, 0.0, abs(y_delta * 0.01) );

	vec3 light_to_fragment = vec3(heatmap_value.x, y_delta, heatmap_value.z);
	light_to_fragment /= length(light_to_fragment);

	vec3 eye_to_fragment = position - camera_position;
	float eye_to_fragment_dist = length(eye_to_fragment);

	if(intensity > 0.0)
	{
	    vec4 normal_light_factor = texture(gnormal, tex_coord);
	    vec3 normal = normal_light_factor.xyz;
	    float light_factor = normal_light_factor.w;
		vec3 diffuse_color = texture(gcolor, tex_coord).rgb;

		// set light incidence amount
		float incidence_factor = max(0.0, -dot(light_to_fragment, normal));

		//Small boost to ambient light in high-intensity areas
		incidence_factor = mix(incidence_factor, 1.0, clamp(intensity * 0.01, 0.0, 1.0));

		//Limit incidence value to make light appear less directional
		incidence_factor = min(incidence_factor, 0.4);

		//Max out incidence for fire pfx
		if(light_factor < 0.25)
	    {
	        incidence_factor = 1.0;
	    }

	    float roughness = 0.8;

		vec3 color = brdf(light_color * 0.2, light_to_fragment, diffuse_color, vec3(0.02), normal, eye_to_fragment / eye_to_fragment_dist, roughness, light_factor);
		color *= intensity * incidence_factor;// * (incidence_factor * intensity);

	    surface_color += max(vec3(0), color);
	}








	float water_depth = decode_depth_delinear(texture(water_depth, tex_coord).r);
	vec3 water_position = world_pos_from_depth(mat_view_proj_inverse, tex_coord, water_depth);

	vec3 eye_to_water = water_position - camera_position;
	float eye_to_water_dist = length(eye_to_water);

	float fog_density_for_light = fog_density * 10.0;
 	vec3 eye = eye_to_fragment / eye_to_fragment_dist; 
    vec3 fog_color = sky_color(eye, sky_color_horizon, sky_color_zenith);

	float underwater_tint_factor = 0;

	if(is_underwater == 1)
	{
		underwater_tint_factor = clamp(min(eye_to_fragment_dist, eye_to_water_dist) * 0.05, 0.0, 1.0);
	}
	else
	{
		underwater_tint_factor = clamp((eye_to_fragment_dist - eye_to_water_dist) * 0.05, 0.0, 1.0);
	}

	surface_color = mix(surface_color, surface_color * normalize(underwater_color) * 16, underwater_tint_factor);
	surface_color *= get_fog_contribution(fog_density, eye_to_fragment_dist, eye_to_water_dist, water_depth, 1.0, is_underwater, 50.0);
 
	// fix for temporal buffer bug where black spreads across screen
	surface_color = max(surface_color, 0.0);

	if(isnan(surface_color.r) || isinf(surface_color.r)) surface_color.r = 0.0;
	if(isnan(surface_color.g) || isinf(surface_color.g)) surface_color.g = 0.0;
	if(isnan(surface_color.b) || isinf(surface_color.b)) surface_color.b = 0.0;

    color_out = vec4(surface_color, 1.0);
}

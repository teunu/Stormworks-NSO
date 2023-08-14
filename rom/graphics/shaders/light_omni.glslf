#include "depth_utils.glslh"
#include "lighting_common.glslh"
#include "environment_lighting.glslh"

in float log_z;
in vec4 screen_pos_out;

out vec4 color_out;

uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D gcolor;
uniform sampler2D water_depth;

uniform mat4 mat_view_proj_inverse;

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
	gl_FragDepth = log_z_to_frag_depth(log_z);
    vec2 tex_coord = (screen_pos_out.xy / screen_pos_out.w) * 0.5 + 0.5;

    vec3 surface_color = vec3(0.0);

	float depth = decode_depth_delinear(texture(gdepth, tex_coord).r);

    vec3 position = world_pos_from_depth(mat_view_proj_inverse, tex_coord, depth);

    vec3 light_to_fragment = position - light_pos_range.xyz;
    float dist = length(light_to_fragment);

	vec3 eye_to_fragment = position - camera_position;
	float eye_to_fragment_dist = length(eye_to_fragment);

	if(dist <= light_pos_range.w)
	{
	    vec4 normal_light_factor = texture(gnormal, tex_coord);
	    vec3 normal = normal_light_factor.xyz;
	    float light_factor = normal_light_factor.w;
		vec3 diffuse_color = texture(gcolor, tex_coord).rgb;

		// set light incidence amount
	    float incidence_factor = max(0.0, -dot(light_to_fragment / (0.01 + dist), normal));

	    if(light_factor < 0.25)
	    {
	        incidence_factor = 1.0;
	    }

	    const float intensity_scale = 0.05;
	    float distance_factor = (intensity_scale / max(0.01, dist)) - (intensity_scale / light_pos_range.w);

	    float roughness = 0.8;
	    vec3 color = brdf(light_color * 0.2, light_to_fragment / (0.01 + dist), diffuse_color, vec3(0.02), normal, eye_to_fragment / eye_to_fragment_dist, roughness, light_factor) * incidence_factor * distance_factor * 16;
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
 
    // TODO: This whole block should be moved into a separate shader, to be applied after
    // water rendering. For reference, look at the volumetric spotlight rendering to see
    // how this should be done. Essentially, it involves moving this code into a separate
    // pass that is rendered additively, using the same omni light geometry we use in
    // this pass.
	if(is_render_halo == 1) 
	{
	    vec3 eye_to_fragment_dir = eye_to_fragment / eye_to_fragment_dist;
		vec3 eye_to_light = light_pos_range.xyz - camera_position;
		float light_depth_dist = max(0.0, dot(eye_to_light, eye_to_fragment_dir));
		float light_dist = light_depth_dist;

	    float behind_water_depth_factor = (clamp((light_depth_dist - eye_to_water_dist) / light_pos_range.w, -1.0, 1.0) + 1.0) * 0.5;

		if(eye_to_fragment_dist < light_depth_dist)
		{
			light_depth_dist = eye_to_fragment_dist;
		}

	    vec3 light_depth_position = camera_position + light_depth_dist * eye_to_fragment_dir;
	    vec3 light_depth_to_light_center = light_pos_range.xyz - light_depth_position;
	    float light_depth_dist_to_center = 0.01 + length(light_depth_to_light_center);

	    float light_volume_factor = max(0.0, (fog_density_for_light / light_depth_dist_to_center) - (fog_density_for_light / light_pos_range.w));

	    vec3 water_depth_position = camera_position + min(eye_to_water_dist, light_depth_dist) * eye_to_fragment_dir;
	    vec3 water_depth_to_light_center = light_pos_range.xyz - water_depth_position;
	    float water_depth_dist_to_center = 0.01 + length(water_depth_to_light_center);

	    float water_volume_factor = max(0.0, (fog_density_for_light / water_depth_dist_to_center) - (fog_density_for_light / light_pos_range.w));

	    surface_color += light_color * ((light_volume_factor * light_volume_factor) - (water_volume_factor * water_volume_factor)) * 10;
	}

	// fix for temporal buffer bug where black spreads across screen
	surface_color = max(surface_color, 0.0);

	if(isnan(surface_color.r) || isinf(surface_color.r)) surface_color.r = 0.0;
	if(isnan(surface_color.g) || isinf(surface_color.g)) surface_color.g = 0.0;
	if(isnan(surface_color.b) || isinf(surface_color.b)) surface_color.b = 0.0;

    color_out = vec4(surface_color, 1.0);
}

#include "depth_utils.glslh"
#include "lighting_common.glslh"

in vec4 screen_pos_out;
in vec3 vertex_world_position_out;
in vec4 flare_pos_out;

out vec4 color_out;

uniform sampler2D gnormal;
uniform sampler2D texture_depth;
uniform sampler2D gcolor;
uniform sampler2D water_depth;

uniform mat4 mat_view_proj_inverse;

uniform vec4 light_pos_range;
uniform vec3 light_color;

uniform vec3 camera_position;
uniform vec3 camera_direction;
uniform float fog_density;
uniform float fog_density_water;

uniform int is_render_halo;

uniform float halo_factor;
uniform int mip_level;
uniform int is_underwater;

void main()
{
    vec2 tex_coord = (screen_pos_out.xy / screen_pos_out.w) * 0.5 + 0.5;

    vec3 surface_color = vec3(0.0);

    vec3 camera_to_light_volume = vertex_world_position_out - camera_position;
	float eye_to_fragment_view = -textureLod(texture_depth, tex_coord, mip_level).r;
	float eye_to_fragment_dist = eye_to_fragment_view / dot(camera_direction, normalize(camera_to_light_volume));
	vec3 eye_to_fragment = normalize(camera_to_light_volume) * eye_to_fragment_dist;
    vec3 position = eye_to_fragment + camera_position;

    // TODO: This whole block should be moved into a separate shader, to be applied after
    // water rendering. For reference, look at the volumetric spotlight rendering to see
    // how this should be done. Essentially, it involves moving this code into a separate
    // pass that is rendered additively, using the same omni light geometry we use in
    // this pass.
	if(is_render_halo == 1)
	{

		float water_depth_dist = decode_depth_delinear(texture(water_depth, tex_coord).r);
		vec3 water_position = world_pos_from_depth(mat_view_proj_inverse, tex_coord, water_depth_dist);

		vec3 eye_to_water = water_position - camera_position;
		float eye_to_water_dist = length(eye_to_water) + 0.25;
		vec3 eye_to_fragment_dir = eye_to_fragment / eye_to_fragment_dist;
		vec3 eye_to_light = light_pos_range.xyz - camera_position;
		float eye_to_light_dist = length(eye_to_light);
		float camera_to_light_volume_dist = length(camera_to_light_volume);
		
		float light_depth_dist = max(0.0, dot(eye_to_light, eye_to_fragment_dir));
		if(eye_to_fragment_dist < light_depth_dist)
		{
			light_depth_dist = eye_to_fragment_dist;
		}

		//Find the light fog contribution due to water (clip behind opaque depth)
		if(true && ((is_underwater == 1) || (eye_to_water_dist < eye_to_fragment_dist)))
		{
			//Get the distance clipped below water suface
			float water_depth_dist_test = max(light_depth_dist, eye_to_water_dist);
			if(is_underwater == 1)
			{
				water_depth_dist_test = min(light_depth_dist, eye_to_water_dist);
			}

			//Add light
			vec3 light_depth_position = camera_position + water_depth_dist_test * eye_to_fragment_dir;
			vec3 light_depth_to_light_center = light_pos_range.xyz - light_depth_position;
			float light_depth_dist_to_center = 0.01 + length(light_depth_to_light_center);
			float light_volume_factor =  clamp(max(0.0, (fog_density_water / light_depth_dist_to_center) - (fog_density_water / light_pos_range.w)), 0.0, 1.0);
			surface_color += (light_color * halo_factor) * light_volume_factor * light_volume_factor;
		}
		
		//Find the fog contribution due to air
		if(true)
		{
			//Get the distance clipped above water suface
			float air_sample_distance = min(light_depth_dist, eye_to_water_dist);
			if(is_underwater == 1)
			{
				air_sample_distance = max(light_depth_dist, eye_to_water_dist);
			}

			float fog_density_air = fog_density * 10.0;

			//Add light
			vec3 light_depth_position = camera_position + air_sample_distance * eye_to_fragment_dir;
			vec3 light_depth_to_light_center = light_pos_range.xyz - light_depth_position;
			float light_depth_dist_to_center = 0.01 + length(light_depth_to_light_center);
			float light_volume_factor = clamp(max(0.0, (fog_density_air / light_depth_dist_to_center) - (fog_density_air / light_pos_range.w)), 0.0, 1.0);
			surface_color += (light_color * halo_factor) * light_volume_factor * light_volume_factor;
		}

		float fog_contribution_fade = get_fog_contribution(fog_density, light_depth_dist, eye_to_water_dist, water_depth_dist, 1.0, is_underwater, 0.0);
		surface_color *= fog_contribution_fade;
	}

	// fix for temporal buffer bug where black spreads across screen
	surface_color = max(surface_color, 0.0);

	if(isnan(surface_color.r) || isinf(surface_color.r)) surface_color.r = 0.0;
	if(isnan(surface_color.g) || isinf(surface_color.g)) surface_color.g = 0.0;
	if(isnan(surface_color.b) || isinf(surface_color.b)) surface_color.b = 0.0;

    color_out = vec4(surface_color * 4, 1.0);
}


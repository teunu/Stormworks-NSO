#include "depth_utils.glslh"
#include "lighting_common.glslh"

in vec3 vertex_position_in;
in vec2 vertex_coord0_in;

out float log_z;
out vec2 vertex_coord0_out;
out float fog_factor;

uniform sampler2D texture_depth;
uniform sampler2D water_depth;

uniform mat4 mat_world;
uniform mat4 mat_view;
uniform mat4 mat_proj;
uniform mat4 mat_view_proj;

uniform mat4 mat_view_proj_inverse;

uniform vec3 flare_world_position;
uniform vec3 camera_position;
uniform float fog_density;
uniform int is_underwater;

void main()
{
	vertex_coord0_out = vertex_coord0_in;
	gl_Position = mat_proj * mat_view  * mat_world * vec4(vertex_position_in, 1);

	vec4 flare_view_pos = mat_view * vec4(flare_world_position, 1);
	vec4 flare_proj_pos = mat_proj * flare_view_pos;
	vec2 flare_uv = ((flare_proj_pos.xy / flare_proj_pos.w) + 1.0) * 0.5;

	float scene_depth = decode_depth_linear(texture(texture_depth, flare_uv).r);

	vec3 eye_to_fragment = flare_world_position - camera_position;
	float eye_to_fragment_dist = length(eye_to_fragment);

	float water_depth = decode_depth_delinear(texture(water_depth, flare_uv).r);
	vec3 water_position = world_pos_from_depth(mat_view_proj_inverse, flare_uv, water_depth);

	vec3 eye_to_water = water_position - camera_position;
	float eye_to_water_dist = length(eye_to_water);

	fog_factor = get_fog_contribution(fog_density * 0.5, eye_to_fragment_dist, eye_to_water_dist, water_depth, 1.0, is_underwater, 0.0);

	if(-flare_view_pos.z * 0.995 > scene_depth)
	{
		gl_Position.w = -100.0;
	}
	
	encode_depth(gl_Position, log_z);
}

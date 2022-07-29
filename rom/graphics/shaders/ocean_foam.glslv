#include "depth_utils.glslh"
#include "ocean_common.glslh"

in vec3 vertex_position_in;
in vec3 vertex_normal_in;
in vec3 vertex_uv_in;

uniform mat4 mat_view;
uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;

out float log_z;
out vec3 world_position_out;
flat out vec3 normal_out;
out float foam_amount_out;
out vec3 view_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform sampler2D texture_wave_height_scale;
uniform float world_to_texture_scale;
uniform vec3 world_offset; // offset for graphics, used in sampling height scale texture

uniform vec3 camera_position;

uniform float wave_timer;
uniform vec3 wave_origin;
uniform float wave_magnitude;
uniform float whirlpool_factor;

void main()
{
	vec3 vertex_position = vertex_position_in.xyz;

	normal_out = vertex_normal_in;
	world_position_out = (mat_world * vec4(vertex_position_in.xyz, 1)).xyz;

	// Scale height according to texture
	// TODO: do we want to scale foam amount as well?
	float height_scale = get_height_scale_from_world(texture_wave_height_scale, world_position_out, world_offset, world_to_texture_scale);
	vertex_position.y *= height_scale;

	// Scale vertex height with distance from camera
	float dist_scale_factor = get_height_scale_from_camera_dist(world_position_out, camera_position);
	vertex_position.y *= dist_scale_factor;
	vertex_position.y += 0.05;

	world_position_out = (mat_world * vec4(vertex_position.xyz, 1)).xyz;

	foam_amount_out = vertex_uv_in.x;

	if(wave_magnitude > 0.0)
	{
		// Gerstner wave
		vec3 gerstner_normal;
		vec3 gerstner_offset = get_gerstner_wave_offset(world_position_out - world_offset, wave_origin, wave_timer, wave_magnitude, whirlpool_factor, gerstner_normal);

		world_position_out += gerstner_offset;
		foam_amount_out += gerstner_offset.y / 130.0;

		normal_out += gerstner_normal;
		normal_out = normalize(normal_out);
	}

	view_position_out = (mat_view * vec4(world_position_out, 1.0)).xyz;

	//No prev/next world matrices
	vertex_position_prev_out = mat_view_proj_prev * vec4(world_position_out, 1);
	vertex_position_next_out = mat_view_proj_next * vec4(world_position_out, 1);

	gl_Position = mat_view_proj * vec4(world_position_out, 1);
	encode_depth(gl_Position, log_z);
}

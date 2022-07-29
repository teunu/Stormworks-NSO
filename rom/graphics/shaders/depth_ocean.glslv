#include "depth_utils.glslh"
#include "ocean_common.glslh"

in vec3 vertex_position_in;

out float log_z;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

uniform sampler2D texture_wave_height_scale;
uniform float world_to_texture_scale;
uniform vec3 world_offset; // offset for graphics, used in sampling height scale texture

uniform vec3 camera_position;

uniform int is_scale_height;

uniform float wave_timer;
uniform vec3 wave_origin;
uniform float wave_magnitude;
uniform float whirlpool_factor;

void main()
{
	vec3 vertex_position = vertex_position_in.xyz;

	vec3 world_position = (mat_world * vec4(vertex_position_in.xyz, 1)).xyz;

	// Scale height according to texture
	if(is_scale_height == 1)
	{
		float height_scale = get_height_scale_from_world(texture_wave_height_scale, world_position, world_offset, world_to_texture_scale);
		vertex_position.y *= height_scale;
	}

	// Scale height with distance from camera
	float dist_scale_factor = get_height_scale_from_camera_dist(world_position, camera_position);
	vertex_position.y *= dist_scale_factor;

	world_position = (mat_world * vec4(vertex_position.xyz, 1)).xyz;

	if(wave_magnitude > 0.0)
	{
		// Gerstner wave
		vec3 gerstner_normal;
		world_position += get_gerstner_wave_offset(world_position - world_offset, wave_origin, wave_timer, wave_magnitude, whirlpool_factor, gerstner_normal);
	}

	gl_Position = mat_view_proj * vec4(world_position, 1);
	encode_depth(gl_Position, log_z);
}

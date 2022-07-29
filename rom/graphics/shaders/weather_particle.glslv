#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec3 vertex_normal_in;

out float log_z;
out vec3 vertex_world_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;

uniform mat4 mat_world_to_weather_camera;

uniform sampler2D texture_depth;

bool is_position_occluded(vec4 world_position)
{
	vec4 camera_coord = (mat_world_to_weather_camera * world_position);
	camera_coord /= camera_coord.w;
	camera_coord = camera_coord * 0.5 + 0.5;

	float depth = texture(texture_depth, camera_coord.xy).r;
	
	return depth < camera_coord.z;
}

void main()
{
	vec4 world_pos = mat_world * vec4(vertex_position_in, 1.0);

	//No prev/next world matrices
	vertex_position_prev_out = mat_view_proj_prev * world_pos;
	vertex_position_next_out = mat_view_proj_next * world_pos;

	gl_Position = mat_view_proj * world_pos;

	vec4 particle_position = mat_world * vec4(vertex_normal_in, 1.0);
	bool is_rain_occluded = is_position_occluded(particle_position);

	if(is_rain_occluded)
	{
		gl_Position.y = -1000.0;
	}
	encode_depth(gl_Position, log_z);
}

#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec3 vertex_color_in;
in vec3 vertex_normal_in;
in vec3 vertex_velocity_in;

out float log_z;
out vec3 vertex_color_out;
out vec3 vertex_normal_out;
out vec3 vertex_world_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;
uniform mat4 mat_world_prev;
uniform mat4 mat_world_next;

uniform vec4 override_color;
uniform int is_preview;
uniform int is_force_color;

void main()
{
	vec3 preview_color_difference = vertex_color_in - vec3(1.0, 1.0, 1.0);
	if((is_preview == 1 && dot(preview_color_difference, preview_color_difference) < 0.01 ) || (is_force_color == 1))
	{
		vertex_color_out = override_color.rgb;
	}
	else
	{
		vertex_color_out = vertex_color_in;
	}

	vertex_normal_out = (mat_world * vec4(vertex_normal_in, 0.0)).xyz;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1.0);
	vertex_world_position_out = world_pos.xyz;

	vertex_position_prev_out = mat_view_proj_prev * (mat_world_prev * vec4(vertex_position_in - vertex_velocity_in, 1.0));
	vertex_position_next_out = mat_view_proj_next * (mat_world_next * vec4(vertex_position_in, 1.0));

	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}

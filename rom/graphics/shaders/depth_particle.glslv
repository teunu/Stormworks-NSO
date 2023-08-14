#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec3 vertex_normal_in;
in vec2 vertex_coord_in;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

out float log_z;
out vec2 vertex_coord_out;
out vec3 vertex_normal_out;

void main()
{
	vertex_normal_out = vertex_normal_in;
	vertex_coord_out = vertex_coord_in;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1.0);
	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}

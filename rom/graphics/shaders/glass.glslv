#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec4 vertex_color_in;
in vec3 vertex_normal_in;

out float log_z;
out vec3 vertex_world_position_out;
out vec4 vertex_color_out;
out vec3 normal_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

void main()
{
	vertex_color_out = vertex_color_in;
    vertex_color_out.r = pow(vertex_color_out.r, 2.2);
    vertex_color_out.g = pow(vertex_color_out.g, 2.2);
    vertex_color_out.b = pow(vertex_color_out.b, 2.2);

	normal_out = (mat_world * vec4(vertex_normal_in, 0.0)).xyz;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
	vertex_world_position_out = world_pos.xyz;
	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}

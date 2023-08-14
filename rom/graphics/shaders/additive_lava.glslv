#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec4 vertex_color_in;
in vec3 vertex_normal_in;

out float log_z;
out vec3 vertex_world_position_out;
out vec4 vertex_color_out;
out vec2 vertex_coord0_out;
out vec3 vertex_normal_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

void main()
{
	vertex_color_out = vertex_color_in * vec4(1.0, 0.1, 0.0, 1.0);
    vertex_normal_out = (mat_world * vec4(vertex_normal_in, 0.0)).xyz;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);

    vertex_coord0_out = vec2(world_pos.x, world_pos.z);

	vertex_world_position_out = world_pos.xyz;
	gl_Position = mat_view_proj * world_pos;
    encode_depth(gl_Position, log_z);
}

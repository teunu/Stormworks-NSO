#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec3 vertex_normal_in;

out float log_z;
out float normal_dot;
out vec4 screen_normal;

uniform mat4 mat_world;
uniform mat4 mat_view;
uniform mat4 mat_view_proj;

uniform vec3 camera_position;

void main()
{
	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
    screen_normal = mat_view_proj * vec4(vertex_normal_in, 0);

	gl_Position = mat_view_proj * world_pos;

    //Discard vertices in the middle of the sphere
    vec3 to_vertex = world_pos.xyz - camera_position;
    to_vertex /= length(to_vertex);
    normal_dot = dot(to_vertex, vertex_normal_in);
    if(abs(normal_dot) > 0.7)
	{
		gl_Position.w = -100.0;
	}

    encode_depth(gl_Position, log_z);
}

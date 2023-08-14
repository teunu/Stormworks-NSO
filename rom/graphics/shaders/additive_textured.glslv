#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec4 vertex_color_in;
in vec2 vertex_coord0_in;

out float log_z;
out vec4 vertex_color_out;
out vec2 vertex_coord0_out;
out float vertex_height_above_camera;

uniform vec3 camera_position;
uniform mat4 mat_world;
uniform mat4 mat_view_proj;
uniform vec3 override_color;

void main()
{
	vertex_color_out = vertex_color_in;
    vertex_color_out.r = pow(override_color.r, 2.2) * 4.0;
    vertex_color_out.g = pow(override_color.g, 2.2) * 4.0;
    vertex_color_out.b = pow(override_color.b, 2.2) * 4.0;

    vertex_coord0_out = vertex_coord0_in;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
    vertex_height_above_camera = world_pos.y - camera_position.y;
	gl_Position = mat_view_proj * world_pos;
    encode_depth(gl_Position, log_z);
}

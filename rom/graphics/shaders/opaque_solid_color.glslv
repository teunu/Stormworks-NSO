#include "depth_utils.glslh"

in vec3 vertexPosition_in;
in vec3 color_in;

out float log_z;
out vec3 vertex_world_position_out;
out vec4 vertex_color_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;
uniform vec4 object_color;

void main()
{
	vertex_world_position_out = (mat_world * vec4(vertexPosition_in, 1.0)).xyz;
	gl_Position =  mat_view_proj * vec4(vertex_world_position_out, 1.0);
	vertex_color_out = vec4(color_in, 1.0) * object_color;
	encode_depth(gl_Position, log_z);
}

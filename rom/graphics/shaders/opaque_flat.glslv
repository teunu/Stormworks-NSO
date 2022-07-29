#include "depth_utils.glslh"

in vec3 vertexPosition_in;
in vec3 color_in;
in vec3 normal_in;

out float log_z;
out vec3 normal_out;
out vec3 vertex_color_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertexPosition_in.x, vertexPosition_in.y, vertexPosition_in.z, 1);
	normal_out = (mat_world * vec4(normal_in, 0)).xyz;
	vertex_color_out = color_in;
	encode_depth(gl_Position, log_z);
}

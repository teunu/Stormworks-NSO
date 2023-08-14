#include "depth_utils.glslh"

in float log_z;
in vec3 normal_out;
in vec3 vertex_color_out;

out vec4 color_out;

uniform vec3 light_direction;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	float intensity = max(0, dot(-light_direction, normalize(normal_out)));

	color_out = vec4(vertex_color_out * intensity, 1.0);
}

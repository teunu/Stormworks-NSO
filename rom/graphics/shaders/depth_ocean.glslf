#include "depth_utils.glslh"

out vec4 color_out;

in float log_z;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	color_out = vec4(gl_FragDepth);
}
#include "depth_utils.glslh"

in float log_z;
in vec4 vertex_color_out;

out vec4 color_out;

uniform float additive_factor;

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

    if(vertex_color_out.a <= 0 && decode_depth_linear(gl_FragDepth) < 0.25)
	{
		discard;
	}
    
    color_out = vec4(vertex_color_out.rgb * additive_factor, 1.0);
}

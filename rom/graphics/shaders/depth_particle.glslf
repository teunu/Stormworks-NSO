#include "depth_utils.glslh"

in float log_z;
in vec2 vertex_coord_out;
in vec3 vertex_normal_out;

out vec4 color_out;

uniform sampler2D texture_noise0;

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);
    vec4 noise_color0 = texture(texture_noise0, vertex_coord_out + vertex_normal_out.xy);
    if(noise_color0.r > vertex_normal_out.z * 6.0 * (0.5 - length(vertex_coord_out)))
    {
    	discard;
    }

	color_out = vec4(gl_FragDepth);
}

#include "depth_utils.glslh"

in float log_z;
in vec4 vertex_color_out;
in vec2 vertex_coord0_out;
in float vertex_height_above_camera;

out vec4 color_out;

uniform float additive_factor;

uniform sampler2D texture_diffuse;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	float height_factor = vertex_height_above_camera / 200.0;
	height_factor = clamp(height_factor, 0.0, 1.0);

    color_out = vec4(texture(texture_diffuse, vertex_coord0_out).rgb * vertex_color_out.rgb * additive_factor * height_factor, 1.0);
}

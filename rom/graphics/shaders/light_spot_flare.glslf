#include "depth_utils.glslh"

in float log_z;
in vec2 vertex_coord0_out;

out vec4 color_out;

uniform vec3 color;

uniform float camera_distance_factor;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	vec2 center_to_fragment = vertex_coord0_out - vec2(0.5, 0.5);
	float center_to_fragment_factor = 1 - clamp(length(center_to_fragment) * 2.0, 0, 1);
	float flare_factor = (pow(center_to_fragment_factor, 2) / 512.0) / clamp(1.0 - center_to_fragment_factor, 0.0, 1.0);

    color_out = vec4(flare_factor * clamp(camera_distance_factor, 0.0, 1.0) * color * 5, 1);
}

#include "depth_utils.glslh"

in float log_z;
in vec2 vertex_coord0_out;
in float fog_factor;

out vec4 color_out;

uniform vec3 color;

void main()
{
	float sample_to_center_distance = length(vec2(0.5, 0.5) - vertex_coord0_out) + 0.001;
	sample_to_center_distance = min(1.0, sample_to_center_distance * 2.0);

	float magic_number = 0.002;
	vec3 color_sample = color * ((magic_number / sample_to_center_distance) - magic_number);
	color_sample *= fog_factor;

	gl_FragDepth = log_z_to_frag_depth(log_z);

	color_out = vec4(color_sample.rgb, 1.0);
}

#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_world_position_out;
in vec4 vertex_color_out;

out vec4 color_out;

uniform int is_full_alpha_override;

uniform float min_frag_dist;
uniform float max_frag_dist;

uniform vec3 camera_position;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	
	vec3 fragment_to_camera = camera_position - vertex_world_position_out;
	float fragment_to_camera_dist = length(fragment_to_camera);
	fragment_to_camera_dist = min(fragment_to_camera_dist, max_frag_dist);

	float frag_dist_factor = (fragment_to_camera_dist - min_frag_dist) / (max_frag_dist - min_frag_dist);
	frag_dist_factor = max(0.4, 1.0 - frag_dist_factor);

	float alpha = is_full_alpha_override == 1 ? 1.0 : frag_dist_factor;

	if(vertex_color_out.a < 0.9999)
	{
		alpha = vertex_color_out.a;
	}

	color_out = vec4(vertex_color_out.rgb, alpha);
}

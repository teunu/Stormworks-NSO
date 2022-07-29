#include "depth_utils.glslh"

in float log_z;
in vec3 world_position_out;

out vec4 color_out;

uniform float clip_height;
uniform vec3 camera_pos;
uniform mat4 mat_view_proj_frag;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	if(world_position_out.y > clip_height)
	{
		discard;
	}

	color_out = vec4(1.0);
}
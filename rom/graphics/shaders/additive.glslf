#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_world_position_out;
in vec4 vertex_color_out;

out vec4 color_out;

uniform float additive_factor;

#if CLIP_PLANE == 1
uniform vec4 clip_plane;
#endif

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);

	//Lift the additive signs slightly
	gl_FragDepth -= 0.00001;
	
#if CLIP_PLANE == 1
	if(dot(vertex_world_position_out, clip_plane.xyz) < clip_plane.w)
	{
		discard;
	}
#endif

    color_out = vec4(vertex_color_out.rgb * additive_factor, 1.0);
}

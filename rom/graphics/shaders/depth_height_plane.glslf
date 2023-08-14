#include "depth_utils.glslh"

in float log_z;
in vec3 world_position_out;

out vec4 color_out;

uniform float clip_height;
uniform vec3 camera_pos;
uniform mat4 mat_view_proj_frag;

void main()
{
	if(world_position_out.y > clip_height)
	{
		discard;
	}

	vec3 eye_to_fragment_dir = normalize(world_position_out - camera_pos);
	float eye_to_clip_surface_distance = clip_height - camera_pos.y;
	vec3 clip_surface_pos = camera_pos + (eye_to_fragment_dir * (eye_to_clip_surface_distance / eye_to_fragment_dir.y));

	vec4 projected_position = mat_view_proj_frag * vec4(clip_surface_pos, 1.0);

	float projected_log_z;
	encode_depth(projected_position, projected_log_z);
	gl_FragDepth = log_z_to_frag_depth(projected_log_z);

	color_out = vec4(gl_FragDepth);
}
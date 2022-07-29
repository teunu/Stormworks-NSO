#include "depth_utils.glslh"

in float log_z;
in vec3 world_position_out;

out vec4 color_out;

uniform mat4 mat_view_proj_frag;
uniform mat4 mat_world_to_water_camera;
uniform mat4 mat_world_to_water_camera_inverse;
uniform sampler2D texture_water_depth;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);

	vec4 camera_coord = (mat_world_to_water_camera * vec4(world_position_out, 1.0));
	camera_coord /= camera_coord.w;
	vec2 tex_coord = camera_coord.xy * 0.5 + 0.5;
	float water_texture_depth = texture(texture_water_depth, tex_coord).r;

	vec4 water_texture_view_position = vec4(tex_coord, water_texture_depth, 1.0);
	water_texture_view_position = mat_world_to_water_camera_inverse * ((water_texture_view_position * 2.0) - 1.0);
	water_texture_view_position = water_texture_view_position / water_texture_view_position.w;

	if(world_position_out.y > water_texture_view_position.y + 0.1)
	{
		discard;
	}
	
	color_out = vec4(gl_FragDepth);
}

#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec3 vertex_normal_in;

out float log_z;
out vec3 vertex_world_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;

uniform mat4 mat_world_to_splash_camera;
uniform mat4 mat_world_to_splash_camera_inverse;

uniform sampler2D texture_depth;

vec3 world_pos_from_depth(vec4 world_position)
{
	vec4 camera_coord = (mat_world_to_splash_camera * world_position);
	camera_coord /= camera_coord.w;
	vec2 tex_coord = camera_coord.xy * 0.5 + 0.5;

	float depth = texture(texture_depth, tex_coord).r;

	vec4 view_position = vec4(tex_coord, depth, 1.0);
	view_position = mat_world_to_splash_camera_inverse * ((view_position * 2.0) - 1.0);
	return view_position.xyz / view_position.w;
}

void main()
{
	vertex_world_position_out = (mat_world * vec4(vertex_position_in, 1.0)).xyz;

	vec4 particle_position = mat_world * vec4(vertex_normal_in, 1.0);

	// mat_world contains graphics offset in column 3, subtract this to
	// get correct world position
	vertex_world_position_out += world_pos_from_depth(particle_position) - mat_world[3].xyz;

	//No prev/next world matrices
	vertex_position_prev_out = mat_view_proj_prev * vec4(vertex_world_position_out, 1.0);
	vertex_position_next_out = mat_view_proj_next * vec4(vertex_world_position_out, 1.0);

	gl_Position = mat_view_proj * vec4(vertex_world_position_out, 1.0);
	encode_depth(gl_Position, log_z);
}

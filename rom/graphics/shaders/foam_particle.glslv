#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec2 vertex_uv_in;
in vec3 vertex_binormal_in;
in vec3 vertex_normal_in;

out float log_z;
out vec2 vertex_uv_out;
out vec3 world_position_out;
out float vertex_threshold_out;
flat out vec3 vertex_normal_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;
uniform mat4 mat_world_to_water_camera;
uniform mat4 mat_world_to_water_camera_inverse;

uniform sampler2D texture_water_depth;

uniform float ocean_spacing_texels;

uniform int is_underwater;
uniform int is_undersurface;

vec3 world_pos_from_depth(vec4 world_position, out vec3 out_normal)
{
	vec4 camera_coord = (mat_world_to_water_camera * world_position);
	camera_coord /= camera_coord.w;
	vec2 tex_coord = camera_coord.xy * 0.5 + 0.5;

	float depth = texture(texture_water_depth, tex_coord).r;

	float dzdx = (texture(texture_water_depth, tex_coord + vec2(ocean_spacing_texels, 0)).r - texture(texture_water_depth, tex_coord - vec2(ocean_spacing_texels, 0)).r) * 0.5;
	float dzdy = (texture(texture_water_depth, tex_coord + vec2(0, ocean_spacing_texels)).r - texture(texture_water_depth, tex_coord - vec2(0, ocean_spacing_texels)).r) * 0.5;
	out_normal = normalize(vec3(dzdx, 1.0, dzdy));

	vec4 view_position = vec4(tex_coord, depth, 1.0);
	view_position = mat_world_to_water_camera_inverse * ((view_position * 2.0) - 1.0);
	return view_position.xyz / view_position.w;
}

void main()
{
	vertex_uv_out = vertex_uv_in;
	vertex_threshold_out = vertex_binormal_in.x;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
	world_pos.xyz = world_pos_from_depth(world_pos, vertex_normal_out);
	world_pos.y += 0.02;
	world_position_out = world_pos.xyz;

	//No prev/next world matrices
	vertex_position_prev_out = mat_view_proj_prev * world_pos;
	vertex_position_next_out = mat_view_proj_next * world_pos;

	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}

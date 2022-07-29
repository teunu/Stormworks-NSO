#include "depth_utils.glslh"


in vec3 vertex_position_in;
in vec4 vertex_color_in;
in vec3 vertex_normal_in;
in vec4 vertex_bone_weights_in;

out float log_z;
out vec4 vertex_color_out;
out vec3 vertex_normal_out;
out vec3 vertex_world_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;
uniform mat4 mat_world_prev;
uniform mat4 mat_world_next;

uniform vec4 override_color;
uniform int is_preview;
uniform int is_override_color;
uniform mat4 bone_matrices[64];
uniform mat4 bone_matrices_prev[64];

uniform float blend_factor;

uniform int bone_clip_index;
uniform float bone_clip_weight;

void main()
{

	vec3 override_color_difference = vertex_color_in.rgb - vec3(1.0, 0.494, 0.0);
	vec3 preview_color_difference = vertex_color_in.rgb - vec3(1.0, 1.0, 1.0);
	if(dot(override_color_difference, override_color_difference) < 0.01 || ( is_preview == 1 && dot(preview_color_difference, preview_color_difference) < 0.01 ))
	{
		vertex_color_out = vec4(override_color.rgb, 1);
	}
	else if(is_override_color == 1)
	{
		vertex_color_out = vec4(override_color.rgb, 1);
	}
	else
	{
		vertex_color_out = vertex_color_in;
	}

	vec4 skinned_pos;
	vec4 skinned_pos_last_frame;
	vec4 skinned_normal;
	int bone_index;

	bone_index = int(vertex_bone_weights_in.x + 0.1);
	skinned_pos = (bone_matrices[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.z;
	skinned_pos_last_frame = (bone_matrices_prev[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.z;
	skinned_normal = (bone_matrices[bone_index] * vec4(vertex_normal_in, 0.0)) * vertex_bone_weights_in.z;

	if(bone_index == bone_clip_index && vertex_bone_weights_in.z > bone_clip_weight)
	{
		vertex_color_out.a = 0.0;
	}

	bone_index = int(vertex_bone_weights_in.y + 0.1);
	skinned_pos = (bone_matrices[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.w + skinned_pos;
	skinned_pos_last_frame = (bone_matrices_prev[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.w + skinned_pos_last_frame;
	skinned_normal = (bone_matrices[bone_index] * vec4(vertex_normal_in, 0.0)) * vertex_bone_weights_in.w + skinned_normal;

	if(bone_index == bone_clip_index && vertex_bone_weights_in.w > bone_clip_weight)
	{
		vertex_color_out.a = 0.0;
	}

	vertex_normal_out = normalize((mat_world * vec4(skinned_normal.xyz, 0.0)).xyz);

	vec3 blended_pos = mix(skinned_pos_last_frame.xyz, skinned_pos.xyz, blend_factor);
	vec4 world_pos = mat_world * vec4(blended_pos, 1.0);
	vertex_world_position_out = world_pos.xyz;

	vertex_position_prev_out = mat_view_proj_prev * (mat_world_prev * vec4(skinned_pos_last_frame.xyz, 1.0));
	vertex_position_next_out = mat_view_proj_next * (mat_world_next * vec4(skinned_pos.xyz, 1.0));

	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}

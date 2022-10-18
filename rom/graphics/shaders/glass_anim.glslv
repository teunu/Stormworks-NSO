#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec4 vertex_color_in;
in vec3 vertex_normal_in;
in vec4 vertex_bone_weights_in;

out float log_z;
out vec3 vertex_world_position_out;
out vec4 vertex_color_out;
out vec3 vertex_normal_out;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

uniform mat4 bone_matrices[64];
uniform mat4 bone_matrices_prev[64];
uniform float blend_factor;
uniform int bone_clip_index;
uniform float bone_clip_weight;

void main()
{
	vec4 skinned_pos;
	vec4 skinned_pos_last_frame;
	vec4 skinned_normal;
	int bone_index;

	bone_index = int(vertex_bone_weights_in.x + 0.1);
	skinned_pos = (bone_matrices[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.z;
	skinned_pos_last_frame = (bone_matrices_prev[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.z;
	skinned_normal = (bone_matrices[bone_index] * vec4(vertex_normal_in, 0.0)) * vertex_bone_weights_in.z;

	vertex_color_out = vertex_color_in;
    vertex_color_out.r = pow(vertex_color_out.r, 2.2);
    vertex_color_out.g = pow(vertex_color_out.g, 2.2);
    vertex_color_out.b = pow(vertex_color_out.b, 2.2);

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

	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);
}

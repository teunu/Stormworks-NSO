in vec3 vertex_position_in;
in vec4 vertex_bone_weights_in;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;
uniform mat4 bone_matrices[64];

void main()
{
	vec4 skinned_pos;
	int bone_index;

	bone_index = int(vertex_bone_weights_in.x + 0.1);
	skinned_pos = (bone_matrices[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.z;

	bone_index = int(vertex_bone_weights_in.y + 0.1);
	skinned_pos = (bone_matrices[bone_index] * vec4(vertex_position_in, 1)) * vertex_bone_weights_in.w + skinned_pos;

	vec4 world_pos = mat_world * vec4(skinned_pos.xyz, 1.0);

	gl_Position = mat_view_proj * world_pos;
}

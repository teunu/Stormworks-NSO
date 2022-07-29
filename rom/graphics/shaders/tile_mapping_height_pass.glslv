in vec3 vertexPosition_in;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

out float out_y_pos;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertexPosition_in.x, vertexPosition_in.y, vertexPosition_in.z, 1);
	
	vec4 world_pos = mat_world * vec4(vertexPosition_in.xyz, 1);
	out_y_pos = world_pos.y;
}

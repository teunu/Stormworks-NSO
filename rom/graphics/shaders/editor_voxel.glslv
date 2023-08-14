in vec3 vertex_position_in;
in vec3 normal_in;

out vec3 normal_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertex_position_in, 1);
	normal_out = (mat_world * vec4(normal_in, 0)).xyz;
}

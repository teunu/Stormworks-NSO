in vec3 vertex_position_in;
in vec3 normal_in;

out vec3 normal_out;
out vec3 camera_direction_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;
uniform vec3 camera_position;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertex_position_in.x, vertex_position_in.y, vertex_position_in.z, 1);
	normal_out = normalize((mat_world * vec4(normal_in, 0)).xyz);
	camera_direction_out = (mat_world * vec4(vertex_position_in, 1)).xyz - camera_position;
}

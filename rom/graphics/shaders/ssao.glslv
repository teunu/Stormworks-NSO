in vec3 vertex_position_in;
in vec2 vertex_coord0_in;

out vec2 vertex_coord0_out;
out vec3 view_ray_out; // For reconstructing view positions from depth

uniform mat4 mat_proj_inverse;
uniform mat4 mat_view_proj;

void main()
{
	vertex_coord0_out = vertex_coord0_in;
	gl_Position =  mat_view_proj * vec4(vertex_position_in, 1);

	view_ray_out = (mat_proj_inverse * vec4(vertex_position_in, 1.0)).xyz;
	view_ray_out = vec3(view_ray_out.xy / view_ray_out.z, 1.0);
}

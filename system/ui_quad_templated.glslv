in vec3 vertexPosition_in;

out vec4 vertexColor_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;
uniform vec4 quad_color;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertexPosition_in, 1);

	vertexColor_out = quad_color;
}


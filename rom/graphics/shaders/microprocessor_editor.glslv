in vec3 vertexPosition_in;
in vec2 vertexCoord0_in;
in vec4 vertexColor_in;

out vec4 vertexColor_out;
out vec2 vertexCoord0_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertexPosition_in, 1);
	vertexColor_out = vertexColor_in;
	vertexCoord0_out = vertexCoord0_in;
}

in vec3 vertexPosition_in;
in vec2 vertexCoord0_in;

out vec4 vertexColor_out;
out vec2 vertexCoord0_out;

uniform mat4 mat_view_proj;

void main()
{
	gl_Position =  mat_view_proj * vec4(vertexPosition_in, 1);
	vertexCoord0_out = vertexCoord0_in;
}

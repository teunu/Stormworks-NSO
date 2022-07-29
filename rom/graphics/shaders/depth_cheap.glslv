in vec3 vertexPosition_in;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

void main()
{
	vec4 vertexWorldPos = (mat_world * vec4(vertexPosition_in, 1));
	gl_Position =  mat_view_proj * vertexWorldPos;
}

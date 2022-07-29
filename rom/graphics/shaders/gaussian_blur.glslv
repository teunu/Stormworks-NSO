in vec3 vertexPosition_in;
in vec2 vertexCoord0_in;

out vec2 v_texCoord;

uniform mat4 mat_view_proj;

void main()
{
    gl_Position = mat_view_proj * vec4(vertexPosition_in, 1);
    v_texCoord = vertexCoord0_in;
}

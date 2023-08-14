in vec4 vertexColor_out;
in vec2 vertexCoord0_out;

out vec4 color_out;

uniform sampler2D textureDiffuse;

void main()
{
	color_out = texture(textureDiffuse, vertexCoord0_out) * vertexColor_out;
}

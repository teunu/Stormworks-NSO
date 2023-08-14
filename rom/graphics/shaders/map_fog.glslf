in vec2 vertexCoord0_out;

out vec4 color_out;

uniform sampler2D textureDiffuse;

void main()
{
	color_out = vec4(0.1, 0.1, 0.1, texture(textureDiffuse, vertexCoord0_out).r);
}

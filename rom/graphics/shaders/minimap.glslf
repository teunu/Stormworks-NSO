in vec4 vertexColor_out;
in vec2 vertexCoord0_out;

out vec4 color_out;

uniform sampler2D textureDiffuse;
uniform sampler2D textureMask;

void main()
{
	color_out = vec4(texture(textureDiffuse, vertexCoord0_out).rgb * vertexColor_out.rgb, texture(textureMask, vertexCoord0_out).a);
}

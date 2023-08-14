in vec4 vertexColor_out;

out vec4 color_out;

void main()
{
	color_out.rgb = vertexColor_out.rgb;
	color_out.a = 1.0;
}

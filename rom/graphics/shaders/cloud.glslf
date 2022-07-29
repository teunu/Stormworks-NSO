in vec3 surface_color;

out vec4 color_out;

void main()
{
	color_out = vec4(surface_color, 1);
}

in vec4 vertexColor_out;
in vec3 vertexNormal_out;

out vec4 color_out;

void main()
{
	vec3 light_dir = vec3(0.5, -1.0, 0.2);
	float light_amount = dot(vertexNormal_out, -light_dir) * 0.4 + 0.7;
	color_out = vertexColor_out * vec4(light_amount, light_amount, light_amount, 1.0);
}

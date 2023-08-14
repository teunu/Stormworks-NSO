in vec3 normal_out;

out vec4 color_out;

uniform vec3 light_direction;

void main()
{
	float intensity = max(0, dot(-light_direction, normalize(normal_out)));
	intensity = clamp(intensity, 0.3, 1.0);

	vec3 right = vec3(1, 0, 0);
	vec3 up = vec3(0, 1, 0);

	float right_dot = dot(right, normal_out);
	float up_dot = dot(up, normal_out);

	vec3 color = vec3(0.2, 0.2, 0.2);

	if(abs(right_dot) > 0.98)
	{
		// Left or right face
		color.r = 1;
	}
	else if(abs(up_dot) > 0.98)
	{
		// Top or bottom face
		color.g = 1;
	}
	else
	{
		// Front or back face
		color.b = 1;
	}

	color_out = vec4(color * intensity, 0.6);
}

in vec3 normal_out;
in vec3 camera_direction_out;

out vec4 color_out;

uniform vec4 color;

void main()
{
	vec3 lightDir = normalize(camera_direction_out);

	float intensity = max(0, dot(-lightDir, normal_out));

	vec4 ambient = color * vec4(0.3, 0.3, 0.3, 1);

	vec4 diffuse = color;
	diffuse.xyz *= intensity;

	color_out = ambient + diffuse;
}

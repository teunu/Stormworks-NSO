uniform sampler2D texture_height;
in vec2 out_uv_coord;

out vec4 color_out;

vec4 edge_detect()
{
	vec2 tex_size = textureSize(texture_height, 0);
	float pixel_width = 1.0 / tex_size.x;
	float pixel_height = 1.0 / tex_size.y;

	float radius = 2.0;
	float radius_border = 1.5;
	float threshold = 0.01;
	float avg = 0;
	int count = 0;
	float sample_depth = texture(texture_height, out_uv_coord).r;
	float output_value = 0;

	if (sample_depth > 0.99)
	{
		radius = 4.0;
	}

	for (int i = -4; i <= 4; i++)
	{
		for (int j = -4; j <= 4; j++)
		{
			float offset_sample_depth = texture(texture_height, out_uv_coord + vec2(i * pixel_width, j * pixel_height)).r;
			float offset_length = length(vec2(i, j));
			if (abs(sample_depth - offset_sample_depth) > threshold)
			{
				float offset_output_value = clamp((radius - offset_length) / radius_border, 0.0, 1.0);
				output_value = max(output_value, offset_output_value);
			}
		}
	}

	return vec4(output_value, output_value, output_value, 1.0);
}

void main()
{
	color_out = edge_detect();
}

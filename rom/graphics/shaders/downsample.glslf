in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_diffuse;

uniform vec2 inv_resolution;

uniform vec2 rand_offset;

// Box filter blur (2x2) downsample filter
void main()
{
	vec4 samples[4];

	samples[0] = texture(texture_diffuse, vertex_coord0_out + vec2(-1, -1) * inv_resolution);
	samples[1] = texture(texture_diffuse, vertex_coord0_out + vec2(1, -1) * inv_resolution);
	samples[2] = texture(texture_diffuse, vertex_coord0_out + vec2(-1, 1) * inv_resolution);
	samples[3] = texture(texture_diffuse, vertex_coord0_out + vec2(1, 1) * inv_resolution);

	vec4 combined_sample = (samples[0] + samples[1] + samples[2] + samples[3]) * 0.25;

	color_out = combined_sample;
}

in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_color;

void main()
{
	// vec2 inv_resolution = vec2(1.0) / textureSize(texture_color, 0);

	vec4 central_sample = texture(texture_color, vertex_coord0_out);

	color_out = vec4(central_sample.rgb, 1.0);

	// vec4 samples[4];
	// samples[0] = texture(texture_color, vertex_coord0_out + vec2(-1, -1) * inv_resolution);
	// samples[1] = texture(texture_color, vertex_coord0_out + vec2(1, -1) * inv_resolution);
	// samples[2] = texture(texture_color, vertex_coord0_out + vec2(-1, 1) * inv_resolution);
	// samples[3] = texture(texture_color, vertex_coord0_out + vec2(1, 1) * inv_resolution);
	//
	// float fDepthHiRes = texture(texture_depth, vertex_coord0_out).r;
	// float fDepthsCoarse[4];
	//
	// fDepthsCoarse[0] = textureLod(texture_depth, vertex_coord0_out + vec2(-1, -1) * inv_resolution, 1).r;
	// fDepthsCoarse[1] = textureLod(texture_depth, vertex_coord0_out + vec2(1, -1) * inv_resolution, 1).r;
	// fDepthsCoarse[2] = textureLod(texture_depth, vertex_coord0_out + vec2(-1, 1) * inv_resolution, 1).r;
	// fDepthsCoarse[3] = textureLod(texture_depth, vertex_coord0_out + vec2(1, 1) * inv_resolution, 1).r;
	//
	// float vDepthWeights[4];
	// for(int i = 0; i < 4; i++)
	// {
	// 	float fDepthDiff = abs(fDepthHiRes - fDepthsCoarse[i]);
	// 	// float fDepthDiff = fDepthsFine[i] - fDepthsCoarse[i];
	// 	vDepthWeights[i] = 1.0 / (0.0000001 + abs(fDepthDiff));
	// }
	//
	// float total_weight = 0.2;
	// vec4 upsampled = central_sample * total_weight;
	//
	// // for(int nTexel = 0; nTexel < 4; nTexel++)
	// // {
	// 	for(int nSample = 0; nSample < 4; nSample++)
	// 	{
	// 		float weight = vDepthWeights[nSample] * 0.2;// vBilinearWeights[nTexel][nSample];
	// 		total_weight += weight;
	// 		upsampled += samples[nSample] * weight;
	// 	}
	// // }
	// upsampled /= total_weight;
	//
	// color_out = upsampled;
}

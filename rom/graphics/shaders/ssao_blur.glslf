in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_diffuse;

// Size of noise texture
const int blur_size = 4;

#if defined(BLUR_HORIZONTAL)
const vec2  blurMultiplyVec = vec2(1.0f, 0.0f);
#elif defined(BLUR_VERTICAL)
const vec2  blurMultiplyVec = vec2(0.0f, 1.0f);
#endif

void main()
{
	vec2 texel_size = 1.0 / vec2(textureSize(texture_diffuse, 0));
	float result = 0.0;
	vec2 hlim = vec2(float(-blur_size) * 0.5 + 0.5);

	for (int x = 0; x < blur_size; ++x)
	{
		vec2 offset = (hlim + (blurMultiplyVec * x)) * texel_size;
		result += texture(texture_diffuse, vertex_coord0_out + offset).r;
	}

	result /= float(blur_size);

	color_out = vec4(result, 0.0, 0.0, 1.0);
}

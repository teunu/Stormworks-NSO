#include "depth_utils.glslh"

in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_diffuse;

uniform int previous_mip_level;

uniform mat4 mat_proj;

void main()
{
	if(previous_mip_level < 0)
	{
		float depth = texture(texture_diffuse, vertex_coord0_out).r;
		depth = decode_depth_linear(depth);
		color_out = vec4(-depth);
	}
	else
	{
		ivec2 frag_coord = ivec2(gl_FragCoord.xy);
		vec4 combined_sample = texelFetch(texture_diffuse, clamp(frag_coord * 2 + ivec2(frag_coord.y & 1, frag_coord.x & 1), ivec2(0), textureSize(texture_diffuse, previous_mip_level) - ivec2(1)), previous_mip_level);

		color_out = combined_sample;
	}
}

#include "depth_utils.glslh"
#include "lighting_common.glslh"

in vec4 screen_pos_out;
in vec3 vertex_world_position_out;

out vec4 color_out;

uniform vec4 light_pos_range;
uniform float light_intensity;

void main()
{
	vec3 position = vertex_world_position_out;

	//Normal xz + distance
	vec3 light_to_fragment = position - light_pos_range.xyz;

    float dist = length(light_to_fragment.xz);
	float intensity = 1.0 - clamp((dist / light_pos_range.w), 0.0, 1.0);
	intensity = intensity * light_pos_range.w * 0.01;
	color_out = vec4(light_to_fragment.x * intensity , light_pos_range.y * intensity, light_to_fragment.z * intensity, intensity);
}

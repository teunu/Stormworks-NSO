#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_world_position_out;
in vec4 vertex_color_out;
in vec2 vertex_coord0_out;
in vec3 vertex_normal_out;
out vec4 color_out;

uniform float additive_factor;
uniform float time;
uniform float ash_density;
uniform float fog_density;

float rand(vec2 co) // returns -1 -> +1
{
	return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 437.5453);
}

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);

	gl_FragDepth -= 0.00001;
	
	float heat_random = rand(vec2(gl_PrimitiveID, 0.0));
	float heat_phase = mod((time * additive_factor * 0.75) + (heat_random * 6.283185), 6.283185);
	float heat_angle = max((vertex_normal_out.y - 0.5) * 2.0, 0.25);

	color_out = vec4((vertex_color_out.rgb * 3.0 * heat_angle * additive_factor) * (1.0 + (sin(heat_phase) * 0.7)), 1.0);

	float fog = clamp(1.0 / exp(decode_depth_linear(gl_FragDepth) * fog_density * 0.5), 0.0, 1.0);
	color_out.a *= fog;

	float depth_factor_ash = 1.0 - (1.0 / exp(decode_depth_linear(gl_FragDepth) * 0.1));
	color_out.a = mix(color_out.a, 0.0, depth_factor_ash * ash_density);

}

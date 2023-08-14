#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_normal_out;
in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_diffuse;
uniform vec3 sky_color;
uniform float wind_factor;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	
	float alpha = vertex_normal_out.y;
	
	color_out = texture(texture_diffuse, vertex_coord0_out);
	// color_out.a = pow(color_out.a, 1.5);
	// color_out *= 4.0;

	float wind_alpha = max(0.0, (wind_factor - 0.2) / 0.8);

	float mult_alpha = color_out.a * alpha * min(wind_alpha, 1.0);
	mult_alpha = min(mult_alpha, 0.05);
	vec4 adjusted_sky_color = vec4(sky_color, mult_alpha);
	adjusted_sky_color = mix(adjusted_sky_color, vec4(1.0, 1.0, 1.0, mult_alpha), 0.03);
	
	color_out = adjusted_sky_color;
	
	// color_out = vec4(1.0, 0.0, 0.0, 1.0);
}

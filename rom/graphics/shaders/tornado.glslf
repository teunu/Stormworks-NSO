#include "depth_utils.glslh"

in float log_z;

in vec3 vertex_world_position_out;
in vec4 vertex_color_out;
in vec2 vertex_coord0_out;
in vec3 vertex_normal_out;

in float height_factor_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;

uniform sampler2D texture_noise;

uniform float tornado_active_factor;
uniform float tornado_base_radius;

uniform vec4 color;
uniform float time;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);

	vec2 sample_coord = vec2(vertex_coord0_out.x, vertex_coord0_out.y);
	sample_coord += vec2(time, -time * 0.5);

	vec4 noise_color0 = textureLod(texture_noise, sample_coord, 1.0);
	float alpha_threshold = mix(mix(1.0, 0.6, height_factor_out * tornado_active_factor), 0.6, tornado_active_factor);

	if((noise_color0.r * vertex_color_out.a) < alpha_threshold)
    {
    	discard;
    }
	
	gnormal_light_factor_out = vec4(normalize(vertex_normal_out), 0.0);
	
	gcolor_out = color;
    // Convert from srgb to linear space
    gcolor_out.r = pow(gcolor_out.r, 2.2);
    gcolor_out.g = pow(gcolor_out.g, 2.2);
    gcolor_out.b = pow(gcolor_out.b, 2.2);
}

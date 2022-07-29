#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_color_out;
in vec3 vertex_normal_out;
in vec3 vertex_world_position_out;
in float radius_factor_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;

uniform sampler2D texture_noise;

uniform float anim;

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

    gnormal_light_factor_out = vec4(normalize(vertex_normal_out), 1.0);

	float noise_sample_0 = texture(texture_noise, vec2(vertex_world_position_out.x, vertex_world_position_out.z) * 0.001).r;
    float noise_sample_1 = texture(texture_noise, vec2(vertex_world_position_out.x, vertex_world_position_out.z) * 0.007).r;
    float noise_sample_2 = texture(texture_noise, vec2(vertex_world_position_out.x, vertex_world_position_out.z) * 0.013).r;
    float noise_sample_3 = texture(texture_noise, vec2(vertex_world_position_out.x, vertex_world_position_out.z) * 0.053).r;
    float noise_sample = (noise_sample_0 * 0.5) + (noise_sample_1 * 0.25) + (noise_sample_2 * 0.125)+ (noise_sample_3 * 0.0625);

    float fade_anim = clamp((anim - 0.5) * 2.0, 0.0, 1.0);
    float threshold = clamp((((1.0 - radius_factor_out) * 0.2) + fade_anim), 0.0, 1.0);

    if(noise_sample < mix(0.0, 0.7, threshold))
    {
        discard;
    }

    

	gcolor_out = vec4(vertex_color_out, 1);
    // Convert from srgb to linear space
    //gcolor_out.r = pow(gcolor_out.r, 2.2);
    //gcolor_out.g = pow(gcolor_out.g, 2.2);
    //gcolor_out.b = pow(gcolor_out.b, 2.2);
}
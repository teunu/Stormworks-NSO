#include "depth_utils.glslh"

in float log_z;
in vec2 vertex_uv_out;
in vec3 world_position_out;
in float vertex_threshold_out;
flat in vec3 vertex_normal_out;
in vec4 vertex_position_next_out;
in vec4 vertex_position_prev_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

uniform sampler2D texture_falloff;
uniform sampler2D texture_noise0;
uniform sampler2D texture_noise1;

uniform vec3 underwater_color;

uniform float timer;

uniform float light_factor;

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

#if VELOCITY_ENABLED == 1
    // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

    vec2 noise_tex_coords0 = world_position_out.xz * 1.0 + vec2(timer, timer) * 0.3;
    vec2 noise_tex_coords1 = world_position_out.zx * 0.1 - vec2(timer, timer) * 0.1;

    vec4 falloff = texture(texture_falloff, vertex_uv_out);

    if(falloff.r < 0.000001)
    {
        discard;
    }
    else
    {
        falloff = vec4(1.0);
    }

    vec4 noise_color0 = texture(texture_noise0, noise_tex_coords0);
    vec4 noise_color1 = texture(texture_noise1, noise_tex_coords1);
    vec4 noise_color = noise_color0 * 0.3 + noise_color1 * 0.5;

    const float threshold_offset = 0.4;
    float threshold = vertex_threshold_out * (1.0 - threshold_offset);
    threshold *= threshold * threshold;
    threshold += threshold_offset;
    if(noise_color.r < threshold)
    {
        discard;
    }

    gcolor_out = vec4(mix(underwater_color, vec3(1.0), 0.4), 1.0);
    gnormal_light_factor_out = vec4(vertex_normal_out, 0.0);
}

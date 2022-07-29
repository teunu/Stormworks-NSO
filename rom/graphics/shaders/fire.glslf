#include "depth_utils.glslh"

in float log_z;
in vec2 vertex_uv_out;
in vec3 vertex_world_position_out;
in vec4 vertex_position_next_out;
in vec4 vertex_position_prev_out;
in vec3 vertex_normal_out;
in vec3 vertex_color_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

uniform sampler2D texture_noise0;
uniform float timer;

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);
    
#if VELOCITY_ENABLED == 1
    // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

    vec2 noise_tex_coords0 = (vertex_uv_out * 1.0) + (vec2(0, timer) * 0.5);
    vec2 noise_tex_coords1 = (vertex_uv_out * 1.4);

    float falloff = texture(texture_noise0, noise_tex_coords0 + vertex_normal_out.yz).r * texture(texture_noise0, noise_tex_coords1 + vertex_normal_out.yz).r;

    float distance_to_center_factor = clamp(1.0 - length(vertex_uv_out - vec2(0.5, 0.5)), 0.0, 1.0);

    if(falloff * distance_to_center_factor < 0.25 + ((1.0 - pow(clamp(vertex_normal_out.x, 0.0, 1.0), 0.1)) * 0.75))
    {
        discard;
    }

    gnormal_light_factor_out = vec4(0.0, 1.0, 0.0, 0.0);

	gcolor_out = vec4(vertex_color_out, 1.0);
}

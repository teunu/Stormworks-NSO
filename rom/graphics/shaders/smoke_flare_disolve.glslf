#include "depth_utils.glslh"

in float log_z;
in vec2 vertex_coord_out;
in vec3 vertex_color_out;
in vec3 vertex_normal_out;
in vec3 vertex_world_position_out;
in vec4 vertex_position_prev_out;
in vec4 vertex_position_next_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

uniform sampler2D texture_noise0;

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);
    
    vec4 noise_color0 = texture(texture_noise0, vertex_coord_out + vertex_normal_out.xy);
    if(noise_color0.r > vertex_normal_out.z * 6.0 * (0.5 - length(vertex_coord_out)))
    {
    	discard;
    }

#if VELOCITY_ENABLED == 1
    // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

    gnormal_light_factor_out = vec4(0.0, 1.0, 0.0, 0.0);

	gcolor_out = vec4(vertex_color_out, 1.0);
}

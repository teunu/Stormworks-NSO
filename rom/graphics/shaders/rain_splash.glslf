#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_world_position_out;
in vec4 vertex_position_next_out;
in vec4 vertex_position_prev_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

uniform vec3 color_particle;

vec2 encode_velocity(vec2 velocity)
{
    // velocity.x = pow(abs(velocity.x), 1.0 / 3.0) * sign(velocity.x) * 0.5 + 0.5;
    // velocity.y = pow(abs(velocity.y), 1.0 / 3.0) * sign(velocity.y) * 0.5 + 0.5;
    return velocity;
}

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

    gnormal_light_factor_out = vec4(0, 1, 0, 0);

    // Clamp color to avoid bloom
    gcolor_out = vec4(min(color_particle.r, 0.4), min(color_particle.g, 0.4), min(color_particle.b, 0.4), 1.0);

    // Velocity
#if VELOCITY_ENABLED == 1
   // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif
}

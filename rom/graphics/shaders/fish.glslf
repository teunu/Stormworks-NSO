#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_color_out;
in vec3 vertex_normal_out;
in vec3 vertex_world_position_out;
in vec4 vertex_position_prev_out;
in vec4 vertex_position_next_out;

in vec3 vertex_position_out;

#if IS_ADDITIVE == 1

out vec4 color_out;

#else

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

#endif

uniform float time_phase; //0.0 -> 2PI
uniform float time_phase_offset;
uniform float light_phase;
uniform float light_factor;

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

#if IS_ADDITIVE == 1

    float colour_intensity = 0.1 + (sin(light_phase + time_phase_offset - (vertex_position_out.x * 20.0) ) + 1.0) * 0.5;
    color_out = vec4(vec3(0.05, 0.20, 1.00) * colour_intensity, 1.0);

#else

#if VELOCITY_ENABLED == 1
    // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

    gnormal_light_factor_out = vec4(normalize(vertex_normal_out), light_factor);

	gcolor_out = vec4(vertex_color_out, 1);
    // Convert from srgb to linear space
    gcolor_out.r = pow(gcolor_out.r, 2.2);
    gcolor_out.g = pow(gcolor_out.g, 2.2);
    gcolor_out.b = pow(gcolor_out.b, 2.2);

#endif

}

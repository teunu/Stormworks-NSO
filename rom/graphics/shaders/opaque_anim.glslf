#include "depth_utils.glslh"

in float log_z;
in vec4 vertex_color_out;
in vec3 vertex_normal_out;
in vec3 vertex_world_position_out;
in vec4 vertex_position_prev_out;
in vec4 vertex_position_next_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

uniform float light_factor;

vec2 encode_velocity(vec2 velocity)
{
    return velocity;
}

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

    if(vertex_color_out.a <= 0 && decode_depth_linear(gl_FragDepth) < 0.25)
	{
		discard;
	}
    
#if VELOCITY_ENABLED == 1
    // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

    gnormal_light_factor_out = vec4(normalize(vertex_normal_out), light_factor);

	gcolor_out = vertex_color_out;
    // Convert from srgb to linear space
    gcolor_out.r = pow(gcolor_out.r, 2.2);
    gcolor_out.g = pow(gcolor_out.g, 2.2);
    gcolor_out.b = pow(gcolor_out.b, 2.2);
}

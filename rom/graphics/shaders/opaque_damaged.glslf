#include "depth_utils.glslh"

in float log_z;
in vec3 vertex_color_out;
in vec3 vertex_normal_out;
in vec3 vertex_world_position_out;
in vec3 vertex_normal_local_out;
in vec3 vertex_position_local_out;

in vec4 vertex_position_prev_out;
in vec4 vertex_position_next_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

uniform float light_factor;
uniform sampler2D texture_noise;

uniform int is_motion_blur_affected;

#if CLIP_PLANE == 1
uniform vec4 clip_plane;
#endif

vec2 encode_velocity(vec2 velocity)
{
    return velocity;
}

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

#if CLIP_PLANE == 1
	if(dot(vertex_world_position_out, clip_plane.xyz) < clip_plane.w)
	{
		discard;
	}
#endif

#if VELOCITY_ENABLED == 1
    // Velocity
    vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;

    vec2 velocity = (screen_pos_next - screen_pos_prev);
    gvelocity_out = velocity;
#endif

    gnormal_light_factor_out = vec4(normalize(vertex_normal_out), light_factor);

    float damage_value = vertex_color_out.r;
    damage_value = 0.4 + clamp(damage_value * 10.0, 0.0, 0.2);

    vec3 blending = abs(vertex_normal_local_out);
    blending = max(blending, 0.00001); // Force weights to sum to 1.0
    float b = (blending.x + blending.y + blending.z);
    blending /= vec3(b, b, b);

    vec4 xaxis = texture(texture_noise, vertex_position_local_out.yz * vec2(1.0, 0.1));
    vec4 yaxis = texture(texture_noise, vertex_position_local_out.xz * vec2(1.0, 0.1));
    vec4 zaxis = texture(texture_noise, vertex_position_local_out.xy * vec2(0.1, 1.0));
    // blend the results of the 3 planar projections.
    vec4 tex = xaxis * blending.x + yaxis * blending.y + zaxis * blending.z;

    if(tex.r > damage_value)
    {
        discard;
    }

    if(tex.r < damage_value - 0.05)
    {
        gcolor_out = vec4(vec3(0.2), 1.0);
        // discard;
    }
    else
    {
        gcolor_out = vec4(vec3(0.5), 1.0);
    }
}

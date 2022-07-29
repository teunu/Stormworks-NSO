#include "depth_utils.glslh"

in float log_z;
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

uniform float light_factor;

uniform int is_motion_blur_affected;

#if CLIP_PLANE == 1
uniform vec4 clip_plane;
#endif

mat4 thresholdMatrix = mat4
(
1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0,
13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0,
4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0,
16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0
);


void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

#ifdef LOD_TEST
    int pix_x = int(gl_FragCoord.x);
    int pix_y = int(gl_FragCoord.y);
    float clip_threshold = thresholdMatrix[pix_x % 4][pix_y % 4];

    float fade =  clamp((decode_depth_linear(gl_FragDepth) - 50.0) / (300.0 - 50.0), 0.0, 1.0);

    if(1.0 - fade - clip_threshold < 0.0)
    {
        discard;
    }
#endif
    
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
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

    gnormal_light_factor_out = vec4(normalize(vertex_normal_out), light_factor);

	gcolor_out = vec4(vertex_color_out, 1);
	//gcolor_out = vec4(alpha, alpha, alpha, 1);

    // Convert from srgb to linear space
    gcolor_out.r = pow(gcolor_out.r, 2.2);
    gcolor_out.g = pow(gcolor_out.g, 2.2);
    gcolor_out.b = pow(gcolor_out.b, 2.2);
}

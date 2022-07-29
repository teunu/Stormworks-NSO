in vec3 vertex_normal_out;
in vec4 vertex_position_prev_out;
in vec4 vertex_position_next_out;

out vec4 gnormal_light_factor_out;
out vec4 gcolor_out;
#if VELOCITY_ENABLED == 1
out vec2 gvelocity_out;
#endif

uniform vec3 sky_color_up;
uniform vec3 sky_color_down;
uniform vec2 rand_offset;

float rand(vec2 co) // returns -1 -> +1
{
	return (fract(sin(dot(co.xy + rand_offset, vec2(12.9898,78.233))) * 43758.5453) * 2.0) - 1.0;
}

vec2 encode_velocity(vec2 velocity)
{
    return velocity;
}

vec3 sky_color(vec3 normal)
{
    float angle_factor = dot(normal, vec3(0, 1, 0)) * 0.5 + 0.5 + (rand(gl_FragCoord.xy) * 0.01);
    vec3 res = mix(sky_color_down, sky_color_up, angle_factor).rgb;

	return res;
}

void main()
{
#if VELOCITY_ENABLED == 1
	vec2 screen_pos_next = (vertex_position_next_out.xy / vertex_position_next_out.w) * 0.5 + 0.5;
    vec2 screen_pos_prev = (vertex_position_prev_out.xy / vertex_position_prev_out.w) * 0.5 + 0.5;
    gvelocity_out = (screen_pos_next - screen_pos_prev);
#endif

	vec3 normal_unit = normalize(vertex_normal_out);

	gnormal_light_factor_out = vec4(normal_unit, 0.0);

	gcolor_out = vec4(sky_color(-normal_unit) * 0.1, 1);
}

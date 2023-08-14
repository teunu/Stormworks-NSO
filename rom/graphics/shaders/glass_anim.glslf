#include "depth_utils.glslh"
#include "lighting_common.glslh"

in float log_z;
in vec3 vertex_world_position_out;
in vec4 vertex_color_out;
in vec3 vertex_normal_out;

out vec4 color_out;

uniform vec3 camera_position;
uniform vec4 override_color;
uniform vec3 sky_color_up;
uniform vec3 sky_color_down;

uniform float fog_density;
uniform vec2 rand_offset;
uniform vec2 screen_size;
uniform int is_underwater;
uniform mat4 mat_view_proj_inverse;

uniform sampler2D texture_water_depth;

#if CLIP_PLANE == 1
uniform vec4 clip_plane;
#endif

float rand(vec2 co) // returns -1 -> +1
{
	return (fract(sin(dot(co.xy + rand_offset, vec2(12.9898,78.233))) * 43758.5453) * 2.0) - 1.0;
}

vec3 sky_color(vec3 normal)
{
    float angle_factor = dot(normal, vec3(0, 1, 0)) * 0.5 + 0.5;
    return mix(sky_color_down, sky_color_up, angle_factor).rgb;
}

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);

    if(vertex_color_out.a <= 0 && decode_depth_linear(gl_FragDepth) < 0.25)
	{
		discard;
	}
    
#if CLIP_PLANE == 1
    if(dot(vertex_world_position_out, clip_plane.xyz) < clip_plane.w)
    {
        discard;
    }
#endif

    vec3 camera_to_fragment = vertex_world_position_out - camera_position;
	float distance_to_fragment = length(camera_to_fragment);
    camera_to_fragment = camera_to_fragment / distance_to_fragment;
    vec3 normal_vector = normalize(vertex_normal_out);
    vec3 reflected_dir = reflect(camera_to_fragment, normal_vector);

	float reflection_factor = max(0.0, -dot(normal_vector, camera_to_fragment));
	reflection_factor = pow(1.0 - reflection_factor, 5.0);
	reflection_factor = clamp(reflection_factor, 0.0, 1.0);
    float light_amount = dot(reflected_dir, vec3(0, 1, 0)) * 0.5 + 0.5;
    
    vec4 surface_color = vec4(vertex_color_out.rgb * (sky_color(reflected_dir) * reflection_factor), vertex_color_out.a);

    float water_depth = decode_depth_delinear(texture(texture_water_depth, gl_FragCoord.xy / screen_size).r);
    vec3 water_position = world_pos_from_depth(mat_view_proj_inverse, gl_FragCoord.xy / screen_size, water_depth);
    float distance_to_water = length(water_position - camera_position);
    float fog_contribution = get_fog_contribution(fog_density, distance_to_fragment, distance_to_water, water_depth, rand(gl_FragCoord.xy), is_underwater, 50.0);

    color_out = vec4(surface_color.rgb * (fog_contribution * 0.9), 0.0);
}

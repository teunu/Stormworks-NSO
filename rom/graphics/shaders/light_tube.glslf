#include "depth_utils.glslh"
#include "lighting_common.glslh"

in float log_z;
in vec4 screen_pos_out;
in vec3 world_position_out;

out vec4 color_out;

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform mat4 mat_view_proj_inverse;

uniform vec3 light_point0;
uniform vec3 light_point1;
uniform float light_range;
uniform vec3 light_color;

uniform vec3 camera_position;

vec3 get_nearest_point(vec3 point)
{
	vec3 line_dir = light_point1 - light_point0;
    float line_length = length(line_dir);
    line_dir /= line_length;
	vec3 line_start_to_point = point - light_point0;
	float nearest_factor = dot(line_start_to_point, line_dir) / line_length;

	// Snap to end of the line
    nearest_factor = clamp(nearest_factor, 0.0, 1.0);
	return light_point0 + ((light_point1 - light_point0) * nearest_factor);
}

void main()
{
    gl_FragDepth = log_z_to_frag_depth(log_z);
    vec2 tex_coord = (screen_pos_out.xy / screen_pos_out.w) * 0.5 + 0.5;

    float depth = decode_depth_delinear(texture(gdepth, tex_coord).r);
    vec3 position = world_pos_from_depth(mat_view_proj_inverse, tex_coord, depth);
    vec3 diffuse_color = texture(gcolor, tex_coord).rgb;
    vec4 normal_light_factor = texture(gnormal, tex_coord);
    vec3 normal = normal_light_factor.xyz;
    float light_factor = normal_light_factor.w;

    vec3 light_to_fragment = position - get_nearest_point(position);
    float dist = length(light_to_fragment);

    vec3 camera_to_fragment = position - camera_position;
    vec3 eye = normalize(camera_to_fragment);
    vec3 refl = reflect(eye, normal);

    // Irradiance (falloff)
    vec3 fragment_to_light0 = light_point0 - position;
    vec3 fragment_to_light1 = light_point1 - position;
    float fragment_to_light_length0 = length(fragment_to_light0);
    float fragment_to_light_length1 = length(fragment_to_light1);

    // float light_intensity_numerator = 2.0 * clamp((dot(normal, fragment_to_light0) / (2 * fragment_to_light_length0)) + (dot(normal, fragment_to_light1) / (2 * fragment_to_light_length1)), 0.0, 1.0);
    // float light_intensity_denominator = (fragment_to_light_length0 * fragment_to_light_length1) + dot(fragment_to_light0, fragment_to_light1) + 2;
    // float light_intensity = light_intensity_numerator / light_intensity_denominator;
	vec3 to_light = get_nearest_point(position) - position;
	float light_dist = length(to_light);
	float light_intensity = max(0, dot(normal, to_light / light_dist));

	float distance_factor = clamp(1.0 - pow(light_dist / light_range, 4.0), 0.0, 1.0);
	distance_factor *= distance_factor;
	distance_factor /= light_dist * light_dist + 1;
	distance_factor = clamp(distance_factor, 0.0, 1.0);

	light_intensity *= distance_factor;

    // Specular
    vec3 ld = fragment_to_light1 - fragment_to_light0;

    float r_dot_ld = dot(refl, ld);

    float spec_dist_numerator = (dot(refl, fragment_to_light0) * r_dot_ld) - dot(fragment_to_light0, ld);
    float spec_dist_denominator = dot(ld, ld) - (r_dot_ld * r_dot_ld);
    float spec_dist = spec_dist_numerator / spec_dist_denominator;

    vec3 light_direction = normalize(fragment_to_light0 + clamp(spec_dist, 0.0, 1.0) * ld);

    if(light_factor < 0.25)
    {
        light_intensity = 0.0;
    }

    float roughness = 0.6;

    // // Specular normalisation factor
    // float a_prime = light_range / (2.0 * )

    vec3 surface_color = brdf(light_color, -light_direction, diffuse_color, vec3(0.02), normal, eye, roughness, light_factor) * light_intensity;

    surface_color = max(vec3(0), surface_color);

    color_out = vec4(surface_color, 1);
}

#include "depth_utils.glslh"
#include "lighting_common.glslh"
#include "shadow_common.glslh"

in float log_z;
in vec4 screen_pos_out;
in vec3 world_position_out;

out vec4 color_out;

uniform sampler2D gcolor;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D water_depth;

uniform sampler2D texture_ies;

uniform sampler2DShadow texture_shadow;
uniform mat4 mat_world_to_shadow;

uniform mat4 mat_view_proj_inverse;

uniform vec4 light_pos_range;
uniform vec3 light_direction;
uniform float light_fov;
uniform vec3 light_color;
uniform int is_underwater;
uniform vec3 underwater_color;
uniform float fog_density;

uniform vec3 camera_position;

float PCF_Filter(sampler2DShadow shadow_map, vec2 uv, float z, vec2 filterRadiusUV)
{
    return PCF_Filter7x7(shadow_map, uv, z, filterRadiusUV.x);

    // float sum = 0;
    // vec2 stepUV = filterRadiusUV;
    //
    // for(int i = 0; i < 12; ++i)
    // {
    //     vec2 offset = poisson_disc[i];
    //     offset *= stepUV;
    //
    //     sum += texture2DCompare(shadow_map, uv + offset, z);
    // }
    //
    // return sum / 12.0;
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
    position += normal * 0.1;
    float light_factor = normal_light_factor.w;

    vec3 light_position = light_pos_range.xyz;
    vec3 light_to_fragment = position - light_position;

    float light_range = light_pos_range.w;

	float light_dist = length(light_to_fragment);

	float distance_factor = clamp(1.0 - pow(light_dist / light_range, 4.0), 0.0, 1.0);
	distance_factor *= distance_factor;
	distance_factor /= light_dist * light_dist + 1;
    distance_factor = clamp(distance_factor, 0.0, 1.0);

    float normal_factor = clamp(-dot(light_to_fragment, normal), 0.0, 1.0);

	const float intensity_scale = 100.0;
    float spot_intensity = distance_factor * normal_factor * intensity_scale;

    if(light_factor < 0.25)
    {
        spot_intensity = distance_factor * intensity_scale;
    }

    vec4 shadow_coord = mat_world_to_shadow * vec4(position, 1.0);
    shadow_coord /= shadow_coord.w;
    shadow_coord = shadow_coord * 0.5 + 0.5;

    vec3 surface_color = vec3(0.0);
    if(shadow_coord.x > 0 && shadow_coord.x < 1 && shadow_coord.y > 0 && shadow_coord.y < 1 && shadow_coord.z > 0 && shadow_coord.z < 1)
    {
        vec3 shadow_value = vec3(1.0);
        vec2 filter_width = vec2(0.0018, 0.0018);
        shadow_value *= PCF_Filter(texture_shadow, shadow_coord.xy, shadow_coord.z, filter_width);
        shadow_value *= texture(texture_ies, shadow_coord.xy).r;

    	vec3 eye_to_fragment = position - camera_position;
	    float eye_to_fragment_dist = length(eye_to_fragment);

        float roughness = 0.8;
	    vec3 color = brdf(light_color, light_to_fragment / light_dist, diffuse_color, vec3(0.02), normal, normalize(eye_to_fragment), roughness, light_factor) * spot_intensity * shadow_value;
	    surface_color = max(vec3(0), color);

        float water_depth = decode_depth_delinear(texture(water_depth, tex_coord).r);
        vec3 water_position = world_pos_from_depth(mat_view_proj_inverse, tex_coord, water_depth);

        vec3 eye_to_water = water_position - camera_position;
        float eye_to_water_dist = length(eye_to_water);

        float underwater_tint_factor = 0;

        if(is_underwater == 1)
        {
           	underwater_tint_factor = clamp(min(eye_to_fragment_dist, eye_to_water_dist) * 0.05, 0.0, 1.0);
        }
        else
        {
            underwater_tint_factor = clamp((eye_to_fragment_dist - eye_to_water_dist) * 0.05, 0.0, 1.0);
        }

        surface_color = mix(surface_color, surface_color * normalize(underwater_color) * 16, underwater_tint_factor);
        surface_color *= get_fog_contribution(fog_density, eye_to_fragment_dist, eye_to_water_dist, water_depth, 1.0, is_underwater, 50.0);
    }

    color_out = vec4(surface_color, 1);
}

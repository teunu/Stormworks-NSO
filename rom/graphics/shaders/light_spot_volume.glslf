#include "depth_utils.glslh"

in vec4 screen_pos_out;
in vec3 world_position_out;

out vec4 color_out;

uniform sampler2D texture_depth;
uniform sampler2D texture_ies;

uniform sampler2D texture_noise;

uniform sampler2DShadow texture_shadow;
uniform mat4 mat_world_to_shadow;

uniform sampler2D texture_water_depth;
uniform mat4 mat_world_to_water_camera;

uniform mat4 mat_proj;
uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_inverse;

uniform vec4 light_pos_range;
uniform vec3 light_direction;
uniform float light_fov;
uniform vec3 light_color;

uniform vec3 camera_position;
uniform vec3 camera_direction;
uniform float fog_density;

uniform vec3 underwater_color;

uniform vec2 rand_offset;
uniform float rand_timer;

uniform int is_camera_inside_volume;

uniform int num_sample_steps;

const float pi = 3.14159265;

float linear_eye_depth(float depth)
{
	float z = depth * 2.0 - 1.0;
	return -(mat_proj[3][2] / (z + mat_proj[2][2]));
}

float Noise(vec2 n,float x)
{
    n+=x;
    return fract(sin(dot(n.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise_step1(vec2 uv,float n){
    float a = 1.0;
    float b = 2.0;
    float c = -12.0;
    float t = 1.0;
    return (1.0/(a*4.0+b*4.0-c))*(
        Noise(uv + vec2(-1.0, -1.0) * t, n) * a +
        Noise(uv + vec2( 0.0, -1.0) * t, n) * b +
        Noise(uv + vec2( 1.0, -1.0) * t, n) * a +
        Noise(uv + vec2(-1.0,  0.0) * t, n) * b +
        Noise(uv + vec2( 0.0,  0.0) * t, n) * c +
        Noise(uv + vec2( 1.0,  0.0) * t, n) * b +
        Noise(uv + vec2(-1.0,  1.0) * t, n) * a +
        Noise(uv + vec2( 0.0,  1.0) * t, n) * b +
        Noise(uv + vec2( 1.0,  1.0) * t, n) * a +
        0.0);
}

float rand(vec2 uv) // returns 0 -> +1
{
    float n = 0.07 * (fract(rand_offset.x) + 1.0);

    float a = 1.0;
    float b = 2.0;
    float c = -2.0;
    float t = 1.0;
    return (4.0/(a*4.0+b*4.0-c))*(
        noise_step1(uv + vec2(-1.0, -1.0) * t, n) * a +
        noise_step1(uv + vec2( 0.0, -1.0) * t, n) * b +
        noise_step1(uv + vec2( 1.0, -1.0) * t, n) * a +
        noise_step1(uv + vec2(-1.0,  0.0) * t, n) * b +
        noise_step1(uv + vec2( 0.0,  0.0) * t, n) * c +
        noise_step1(uv + vec2( 1.0,  0.0) * t, n) * b +
        noise_step1(uv + vec2(-1.0,  1.0) * t, n) * a +
        noise_step1(uv + vec2( 0.0,  1.0) * t, n) * b +
        noise_step1(uv + vec2( 1.0,  1.0) * t, n) * a +
        0.0);
}

float texture2DCompare(sampler2DShadow depths, vec2 uv, float compare){
    return texture(depths, vec3(uv, compare));
}

vec3 world_pos_from_depth(vec2 coords, float depth)
{
	vec4 view_position = vec4(coords, depth, 1.0);

	// transform into [-1, 1] range, and unproject
	view_position = mat_view_proj_inverse * ((view_position * 2.0) - 1.0);

	// scale so w == 1
	view_position /= view_position.w;

	return view_position.xyz;
}

bool ray_cone_intersect(vec3 ray_start, vec3 ray_dir, out vec2 out_intersect_factors)
{
    const float inf = 10000;
	ray_start -= light_pos_range.xyz - (light_direction * 0.5);
	float a = dot(ray_dir, light_direction);
	float b = dot(ray_dir, ray_dir);
	float c = dot(ray_start, light_direction);
	float d = dot(ray_start, ray_dir);
	float e = dot(ray_start, ray_start);

    float cos_fov = cos(light_fov);
	cos_fov *= cos_fov;
	float A = a*a - b*cos_fov;
	float B = 2 * (c*a - d*cos_fov);
	float C = c*c - e*cos_fov;
	float D = B*B - 4 * A*C;

	if (D > 0)
	{
		D = sqrt(D);
		vec2 t = (-B + sign(A)*vec2(-D, +D)) / (2 * A);
		bvec2 b2IsCorrect;
        b2IsCorrect.x = c + a * t.x > 0 && t.x > 0;
        b2IsCorrect.y = c + a * t.y > 0 && t.y > 0;
		t.x = t.x * (b2IsCorrect.x ? 1 : 0) + (!b2IsCorrect.x ? 1 : 0) * (inf);
		t.y = t.y * (b2IsCorrect.y ? 1 : 0) + (!b2IsCorrect.y ? 1 : 0) * (inf);
        out_intersect_factors = t;
		return true;
	}
	else // no ray_position
    {
        out_intersect_factors = vec2(inf, inf);
		return false;
    }
}

bool ray_plane_intersect(vec3 ray_start, vec3 ray_dir, out float out_intersect_factor)
{
    const float inf = 10000;
    vec3 plane_origin = light_pos_range.xyz + light_direction * light_pos_range.w;
    vec3 plane_normal = -light_direction;
    float plane_origin_distance = dot(plane_origin, plane_normal);

    float NdotD = dot(plane_normal, ray_dir);
	float NdotO = dot(plane_normal, ray_start);

	if (NdotD < -0.00000001)
    {
		out_intersect_factor = (plane_origin_distance - NdotO) / NdotD;
        return true;
    }
    else
    {
        out_intersect_factor = inf;
        return false;
    }
}

void main()
{
    vec2 tex_coord = (screen_pos_out.xy / screen_pos_out.w) * 0.5 + 0.5;

    float depth = -textureLod(texture_depth, tex_coord, 1).r;

    vec3 light_position = light_pos_range.xyz;
    float light_range = light_pos_range.w;

    vec3 ray_start = camera_position;
    vec3 ray_end = world_position_out;

    vec3 ray_dir = (ray_end - ray_start);
    float camera_cone_dist = length(ray_dir);

    ray_dir /= camera_cone_dist;

    vec3 intersection_start, intersection_end;
    float ray_length;

	// Linearize depth
	float projected_depth = depth / dot(camera_direction, ray_dir);

    if(is_camera_inside_volume == 1)
    {
		ray_length = min(camera_cone_dist, projected_depth);
        ray_length = min(ray_length, light_range * mix(1.0, 0.25, clamp(dot(ray_dir, light_direction), 0, 1)));

        intersection_start = ray_start;
        intersection_end = intersection_start + ray_dir * ray_length;
    }
    else
    {
        // Start ray inside cone
        vec3 r1 = ray_end + ray_dir * 0.001;

        vec2 cone_intersection_factors;
        float plane_intersection_factor;

        bool is_hit_cone = ray_cone_intersect(r1, ray_dir, cone_intersection_factors);
        bool is_hit_plane = ray_plane_intersect(r1, ray_dir, plane_intersection_factor);

		// Get difference between projected depth and distance from camera to outside of cone
		float z = (projected_depth - camera_cone_dist);
		ray_length = min(plane_intersection_factor, min(cone_intersection_factors.x, cone_intersection_factors.y));
		ray_length = min(ray_length, z);
        ray_length = min(ray_length, light_range * mix(1.0, 0.25, clamp(dot(ray_dir, light_direction), 0, 1)));

        // Start ray at outside of cone
        intersection_start = r1;
        intersection_end = intersection_start + ray_dir * ray_length;
    }
    ////////////////

    int num_steps = num_sample_steps;

    float step_size = ray_length / num_steps;
    vec3 step_vec = ray_dir * step_size;

    vec3 ray_offset = rand(tex_coord) * step_vec;
    // vec3 ray_offset = step_vec;
    vec3 ray_position = intersection_start + ray_offset;

    vec3 volume_contribution = vec3(0.0);

    for(int i = 0; i < num_steps; i++)
    {
        vec4 ray_clip_space = mat_view_proj * vec4(ray_position, 1.0);
        if(linear_eye_depth((ray_clip_space.z / ray_clip_space.w) * 0.5 + 0.5) < depth)
        {
            vec3 to_light = ray_position - light_position;

	    	const float g = 0.3;
            float cos_angle = -dot(ray_dir, light_direction);
            float scattering_factor = pow(1.0 - g, 2.0) / (4.0 * pi * pow(1.0 + g * g - 2.0 * g * cos_angle, 1.5));
            scattering_factor *= 40.0;
            scattering_factor = 1;

            float light_dist = length(to_light);
			float distance_factor = clamp(1.0 - pow(light_dist / light_range, 4.0), 0.0, 1.0);
			distance_factor *= distance_factor;
			distance_factor /= pow(light_dist, 2) + 1;
            distance_factor = clamp(1.0 - light_dist / light_range, 0.0, 1.0);

			const float intensity_scale = 0.1;
            float volume_intensity = intensity_scale * pow(distance_factor, 8.0);

            vec4 shadow_coord = mat_world_to_shadow * vec4(ray_position, 1.0);
            shadow_coord /= shadow_coord.w;
            shadow_coord.xyz = shadow_coord.xyz * 0.5 + 0.5;

			vec3 volume_color = light_color;

            if(shadow_coord.z > 0 && shadow_coord.z < 1 && dot(normalize(to_light), light_direction) > cos(light_fov))
            {
                float shadow_value = texture2DCompare(texture_shadow, shadow_coord.xy, shadow_coord.z);

                volume_intensity *= shadow_value;
                volume_intensity *= texture(texture_ies, shadow_coord.xy).r;

                // Apply more fog when samples are underwater
				vec4 water_relative_position = mat_world_to_water_camera * vec4(ray_position, 1.0);
		        water_relative_position.xyz /= water_relative_position.w;
		        water_relative_position.xyz = water_relative_position.xyz * 0.5 + 0.5;
		        bool is_position_below_water = decode_depth_delinear(texture(texture_water_depth, water_relative_position.xy).r) < water_relative_position.z;

				if(is_position_below_water)
				{
					volume_intensity *= 10.0;
					volume_color = light_color * normalize(underwater_color);
				}
            }
            else
            {
                volume_intensity = 0;
            }

            volume_contribution += volume_color * volume_intensity * scattering_factor;
        }

        ray_position += step_vec;
    }

    volume_contribution /= num_steps;

    float fog_factor = 1.0 / exp(ray_length * fog_density * 10.f);
    fog_factor = clamp(fog_factor, 0.0, 1.0);
    volume_contribution = mix(volume_contribution, vec3(0.0), fog_factor);

    color_out = vec4(volume_contribution, 1.0);
}

#include "depth_utils.glslh"

in vec2 vertex_coord0_out;
in vec3 view_ray_out;

out vec4 color_out;

//NOTE: This is the mipmapped depth texture, which has already been decoded into linear depth
uniform sampler2D gdepth;

uniform sampler2D gnormal_light_factor;
uniform sampler2D texture_noise;

uniform mat4 mat_view;
uniform mat4 mat_proj;

uniform vec3 sample_kernel[15];
uniform int kernel_size;

uniform vec2 screen_size;

uniform vec2 rand_offset;

const float radius = 0.8;
const int occlusion_power = 2;

vec3 view_pos_from_depth(vec2 coords, float linearDepth)
{
	// View position is the linear camera depth scaled along the view ray

	// We need to calculate the interpolated view ray at coords, as view_ray_out
	// is only interpolated for this pixel. To do this, calculate change in
	// x and y for the view ray, multiply by the pixel offset and add to view_ray_out.
	vec3 dx = dFdx(view_ray_out);
	vec3 dy = dFdy(view_ray_out);

	vec2 offset = coords - vertex_coord0_out;
	offset *= screen_size;

	vec3 view_ray = view_ray_out + dx * offset.x + dy * offset.y;

	return view_ray * linearDepth;
}

float sample_mip(vec3 sample_offset, vec2 uv)
{
	float sample_distance = length(sample_offset.xy);
	const float mip_threshold = 0.3;
	int mip_level = int(clamp(sample_distance / mip_threshold, 1.0, 2.0));

	return textureLod(gdepth, uv, mip_level).r;
}

void main()
{
	float depth = textureLod(gdepth, vertex_coord0_out, 1).r;
    vec3 view_position = view_pos_from_depth(vertex_coord0_out, depth);
	vec4 normal_light_factor = texture(gnormal_light_factor, vertex_coord0_out);

	float scale = radius * 5.0;

	float light_factor = normal_light_factor.a;
	if(light_factor > 0.00000001)
	{
		vec3 surface_normal = normal_light_factor.xyz;
	    vec3 view_normal = normalize((mat_view * vec4(surface_normal, 0.0)).xyz);

	    vec4 noise = texture(texture_noise, vertex_coord0_out * (screen_size / 4.0));
		vec3 noise_direction = noise.xyz;

		// Compute occlusion factor
		float occlusion = 1.0;

		for(int i = 0; i < kernel_size; ++i)
		{
		    // Get sample position
			vec3 this_sample = sample_kernel[i];
			vec3 sample_offset = reflect(this_sample, noise_direction);

			int flip = dot(sample_offset, view_normal) < 0.0 ? -1 : 1;
			sample_offset *= flip;

			// Scale offset by view normal to prevent acne
			sample_offset += view_normal * 0.3;

			sample_offset *= scale;

		    vec3 kernel_sample = view_position + sample_offset;

			vec4 offset = vec4(kernel_sample, 1.0);
			offset = mat_proj * offset; // from view to clip-space
			offset.xy /= offset.w;
			offset.xy = offset.xy * 0.5 + 0.5;

			float sample_depth = sample_mip(sample_offset, offset.xy) * 1.001;

			vec3 sample_view_position = view_pos_from_depth(offset.xy, sample_depth);

			vec3 point_to_sample = sample_view_position - view_position;
			float sample_extrusion = dot(view_normal, point_to_sample);

			float sample_distance_sq = dot(point_to_sample, point_to_sample);

			float rangeCheck = smoothstep(0.0, 1.0, radius / abs(depth - sample_depth));
			occlusion -= clamp(((sample_extrusion * 0.02) / (0.02 + sample_distance_sq)), 0.0, 1.0);
		}

		occlusion = pow(occlusion, occlusion_power * 4);

	    color_out = vec4(occlusion, 0.0, 0.0, 1.0);
	}
	else
	{
		color_out = vec4(1.0, 0, 0, 1);
	}
}

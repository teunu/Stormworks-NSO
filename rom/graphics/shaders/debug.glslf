#include "depth_utils.glslh"

in float log_z;
in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D gdepth;
uniform sampler2D gnormal;
uniform sampler2D gcolor;
uniform sampler2D texture_ssao;
uniform sampler2D texture_velocity;
uniform sampler2D texture_water_depth;

uniform vec3 color_override;

uniform int texture_index;

#define VELOCITY_SCALE 0.1

vec2 decode_velocity(vec2 velocity)
{
	// velocity.x = pow(velocity.x*2-1, 3.0);
	// velocity.y = pow(velocity.y*2-1, 3.0);
	return velocity;
}

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	
	switch (texture_index)
	{
		case 0: // Depth
		{
			float depth = texture(gdepth, vertex_coord0_out).r;
			const float depth_min = 0.96;
			depth = clamp(depth - depth_min, 0.0, 1.0) / (1.0 - depth_min);
			color_out = vec4(vec3(depth), 1.0);
		}
		break;
		case 1: // Normals
		{
			color_out = vec4(texture(gnormal, vertex_coord0_out).xyz * 0.5 + 0.5, 1.0);
		}
		break;
		case 2: // Color
		{
			color_out = vec4(texture(gcolor, vertex_coord0_out).xyz, 1.0);
			// Apply gamma correction
			float gamma_correction_factor = 1.0 / 2.2;
			color_out.r = pow(color_out.r, gamma_correction_factor);
			color_out.g = pow(color_out.g, gamma_correction_factor);
			color_out.b = pow(color_out.b, gamma_correction_factor);
		}
		break;
		case 3: // SSAO
		{
			color_out = vec4(vec3(texture(texture_ssao, vertex_coord0_out).r), 1.0);
		}
		break;
		case 4: // Velocity
		{
			vec2 velocity = VELOCITY_SCALE * decode_velocity(texture(texture_velocity, vertex_coord0_out).xy);
			color_out = vec4((velocity * 100) + 0.5, 0.5, 1.0);
		}
		break;
		case 5: // Water depth
		{
			float depth = texture(texture_water_depth, vertex_coord0_out).r;
			const float depth_min = 0.96;
			depth = clamp(depth - depth_min, 0.0, 1.0) / (1.0 - depth_min);
			color_out = vec4(vec3(depth), 1.0);
		}
		break;
		case 6: // Stencil
		{
			color_out = vec4(color_override, 1.0);
		}
		break;
		default:
		{
			color_out = vec4(1.0, 0.0, 0.0, 1.0);
		}
		break;
	}
}

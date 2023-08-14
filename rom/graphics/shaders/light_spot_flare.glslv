#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec2 vertex_coord0_in;

out float log_z;
out vec2 vertex_coord0_out;

uniform sampler2D texture_depth;

uniform mat4 mat_world;
uniform mat4 mat_view_proj;

uniform vec3 flare_world_point;

void main()
{
	vec4 world_pos = mat_world * vec4(vertex_position_in, 1);
	vertex_coord0_out = vertex_coord0_in;
	gl_Position = mat_view_proj * world_pos;

	// Get scene depth at flare viewspace UV
	vec4 flare_view_pos = mat_view_proj * vec4(flare_world_point, 1);
	vec2 flare_uv = ((flare_view_pos.xy / flare_view_pos.w) + 1.0) * 0.5;
    float linear_depth = decode_depth_linear(texture(texture_depth, flare_uv).r);
	if(flare_view_pos.z > linear_depth + 0.25f)
	{
		gl_Position.w = -100.0;
	}

	encode_depth(gl_Position, log_z);
}

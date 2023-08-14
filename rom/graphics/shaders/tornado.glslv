#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec4 vertex_color_in;
in vec2 vertex_coord0_in;
in vec3 vertex_normal_in;

out float log_z;

out vec3 vertex_world_position_out;
out vec4 vertex_color_out;
out vec2 vertex_coord0_out;
out vec3 vertex_normal_out;

out float height_factor_out;

uniform sampler2D texture_noise;

uniform mat4 mat_view_proj;

//Pack into vec4 later
uniform vec3 tornado_base_pos;
uniform vec3 tornado_top_pos;
uniform float tornado_base_radius;

uniform float time;

float rand(vec2 co) // returns -1 -> +1
{
	return (fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453) * 2.0) - 1.0;
}

float get_vertex_distortion(vec2 co)
{
	vec4 noise_color0 = texture(texture_noise, vec2(co.x + (time * 0.1), co.y + (time * 0.1)));
	return noise_color0.x;
}

float get_blended_radius(float height_factor)
{
	float radius_factor = 10.0 / ((100.0 * height_factor) + 10.0);
	radius_factor += pow(height_factor, 3) * 12.0;
	return tornado_base_radius * radius_factor;
}

vec3 get_blended_center_position(float height_factor)
{
	//Smoothstep on XZ, linear on Y
	vec3 blended_position;
	blended_position.xz = mix(tornado_base_pos.xz, tornado_top_pos.xz, height_factor * height_factor * (3.0 - 2.0 * height_factor));
	blended_position.y = mix(tornado_base_pos.y, tornado_top_pos.y, height_factor);
	return blended_position;
}

void get_transformed_vertex(vec3 vertex_position_in, vec2 coord_in, out vec3 vertex_position_out, out vec2 coord_out)
{
	float height_factor = vertex_position_in.y;
	height_factor_out = height_factor;

	vec3 center = get_blended_center_position(height_factor);
	float radius = get_blended_radius(height_factor);

	vertex_position_out = center + vec3(vertex_position_in.x * radius, 0.0, vertex_position_in.z * radius);

	coord_out = vec2(-coord_in.x, coord_in.y) * vec2(radius * 0.05, (tornado_top_pos.y - tornado_base_pos.y) * (1.0 + (height_factor * 0.5)) * 0.02);

	vertex_position_out += vertex_normal_in * get_vertex_distortion(coord_out) * 10.0;
}

void main()
{
	get_transformed_vertex(vertex_position_in, vertex_coord0_in, vertex_world_position_out, vertex_coord0_out);

	gl_Position =  mat_view_proj * vec4(vertex_world_position_out, 1.0);

	vertex_color_out = vertex_color_in;
	vertex_normal_out = vertex_normal_in;

	encode_depth(gl_Position, log_z);
}

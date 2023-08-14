#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec3 vertex_color_in;
in vec3 vertex_normal_in;

out float log_z;
out vec3 vertex_color_out;
out vec3 vertex_normal_out;
out vec3 vertex_world_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;

uniform vec4 instance_offset_world;

uniform vec4 override_color;
uniform int is_preview;
uniform int is_force_color;
uniform int is_disable_color_replace;

uniform float time_phase; //0.0 -> 2PI
uniform float wind_intensity;
uniform vec2 wind_normal_a;
uniform vec2 wind_normal_b;
uniform float wind_blend_factor;

layout(std140) uniform instance_data
{
	mat4 instance_world[1000];
};

float rand(vec2 co) // returns -1 -> +1
{
	return (fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453) * 2.0) - 1.0;
}

float get_wind_distortion(vec2 wind_normal, float vertex_phase, vec4 world_pos)
{
	const float wavelength = 50.0;

	float wind_distance = dot(wind_normal, world_pos.xz);
	float wind_phase = mod(wind_distance, wavelength) / wavelength;
	wind_phase *= -2.0 * 3.14159265;
	return (cos(wind_phase + (time_phase * 15.0) + vertex_phase) + 1.0) * 0.05;
}

void main()
{
	vec3 override_color_difference = vertex_color_in - vec3(1.0, 0.494, 0.0);
	vec3 preview_color_difference = vertex_color_in - vec3(1.0, 1.0, 1.0);
	if((is_disable_color_replace == 0 && (dot(override_color_difference, override_color_difference) < 0.01 || ( is_preview == 1 && dot(preview_color_difference, preview_color_difference) < 0.01 ))) || (is_force_color == 1))
	{
		vertex_color_out = override_color.rgb;
	}
	else
	{
		vertex_color_out = vertex_color_in;
	}

	vertex_normal_out = (instance_world[gl_InstanceID] * vec4(vertex_normal_in, 0.0)).xyz;

	vec4 world_pos = (instance_world[gl_InstanceID] * vec4(vertex_position_in, 1.0)) + instance_offset_world;
	
#if WIND_ANIMATION == 1
	float vertex_phase = rand(world_pos.xz);
	float wind_offset_a = get_wind_distortion(wind_normal_a, vertex_phase, world_pos);
	float wind_offset_b = get_wind_distortion(wind_normal_b, vertex_phase, world_pos);
	float vertex_softness = clamp(length(vertex_position_in.xz) - 1.0, 0.0, 1.0)*0.1;
	vertex_softness += vertex_position_in.y * vertex_position_in.y * 0.01;

	world_pos.xz += mix(wind_normal_a * wind_offset_a, wind_normal_b * wind_offset_b, wind_blend_factor) * vertex_softness * wind_intensity * wind_intensity * 15.0;
#endif

	vertex_world_position_out = world_pos.xyz;
	vertex_position_prev_out = mat_view_proj_prev * world_pos;
	vertex_position_next_out = mat_view_proj_next * world_pos;

	gl_Position = mat_view_proj * world_pos;

#ifdef LOD_TEST
	//AW_TODO: Use this to clip out trees using an inappropriate LOD for a given distance from the camera
	if(gl_Position.w > 200.0)
	{
		gl_Position.w = -100.0;
	}
#endif

	encode_depth(gl_Position, log_z);
}

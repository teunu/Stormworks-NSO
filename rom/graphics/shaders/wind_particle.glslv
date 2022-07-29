#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec2 vertex_coord0_in;
in vec3 vertex_normal_in;
in vec3 vertex_binormal_in;

out float log_z;
out vec3 vertex_normal_out;
out vec2 vertex_coord0_out;

uniform mat4 mat_view_proj;
uniform float wind_factor;
uniform int max_tick;
uniform vec3 graphics_offset;

void main()
{
	float tick = max_tick * vertex_normal_in.x;

	vec3 pos = vertex_position_in + graphics_offset;
	vec3 local_pos = vertex_binormal_in;

	float y_speed = mix(20.0, 10.0, wind_factor);
	float y_wavelength = mix(10.0, 3.0, wind_factor);
	float y_scale = mix(5.0, 1.0, wind_factor);

	float z_speed = mix(20.0, 10.0, wind_factor);
	float z_wavelength = mix(5.0, 5.0, wind_factor);
	float z_scale = mix(5.0, 5.0, wind_factor);

	pos.y += sin((tick / y_speed) + local_pos.x * y_wavelength) / y_scale;
	pos.z += sin((tick / z_speed) + local_pos.x * z_wavelength) / z_scale;
	pos.x += sin((tick / z_speed) + local_pos.x * z_wavelength) / z_scale;
	
	gl_Position =  mat_view_proj * vec4(pos, 1);
	encode_depth(gl_Position, log_z);
	
	vertex_normal_out = vertex_normal_in;
	vertex_coord0_out = vertex_coord0_in;
}

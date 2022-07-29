in vec3 vertex_position_in;

out vec3 surface_color;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;
uniform vec3 camera_position;

void main()
{
	vec4 world_position = mat_world * vec4(vertex_position_in.xyz, 1);
	gl_Position =  mat_view_proj * world_position;

	vec3 camera_to_fragment = world_position.xyz - camera_position;
	float distance_to_fragment = length(camera_to_fragment);
	float depth_factor = 1 - (distance_to_fragment / 1024);
	depth_factor *= depth_factor * depth_factor;

	vec3 fog_color = vec3(0.3, 0.34, 0.4);
	vec3 water_color = vec3(0.02, 0.04, 0.09);

	surface_color = mix(fog_color, water_color, depth_factor);
}
in vec4 screen_pos_out;
in vec3 vertex_world_position_out;
in vec4 vertex_color_out;
in vec3 vertex_normal_out;

out vec4 color_out;

uniform float additive_intensity;

void main()
{
	vec3 position = vertex_world_position_out;

	vec3 light_to_fragment = vertex_normal_out * additive_intensity * 50.0;

	float intensity = additive_intensity;

	color_out = vec4(light_to_fragment.x * intensity, vertex_world_position_out.y * intensity, light_to_fragment.z * intensity, intensity);
}

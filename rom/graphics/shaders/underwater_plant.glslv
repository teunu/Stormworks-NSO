in vec3 vertex_position_in;
in vec3 vertex_color_in;
in vec3 vertex_normal_in;

out vec3 vertex_color_out;
out vec3 vertex_normal_out;
out vec3 vertex_world_position_out;
out vec4 vertex_position_prev_out;
out vec4 vertex_position_next_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_view_proj_prev;
uniform mat4 mat_view_proj_next;
uniform mat4 mat_world;
uniform mat4 mat_world_prev;
uniform mat4 mat_world_next;

uniform float animation_tick;
uniform vec3 camera_position;

void main()
{
	vertex_color_out = vertex_color_in;
	vertex_normal_out = (mat_world * vec4(vertex_normal_in, 0.0)).xyz;

	vec4 world_pos = mat_world * vec4(vertex_position_in, 1.0);
	float camera_to_vertex_length = length(world_pos.xyz - camera_position);
	world_pos.y -= camera_to_vertex_length / 30.0;

	vec3 plant_pos = (mat_world * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float vertex_height_factor = vertex_position_in.y * 0.2;
	vertex_height_factor = mix(0.0, 1.0, clamp(vertex_height_factor / 0.5, 0.0, 1.0));
	float xz_factor = (plant_pos.x + plant_pos.z) * 0.1;

	float animation_scale = 0.15;
	float animation_speed_factor = 0.015;
	float wave_factor = 60.0;
	float x_animation = cos((xz_factor + animation_tick + (vertex_position_in.y * wave_factor)) * animation_speed_factor) * vertex_height_factor * animation_scale;
	float z_animation = sin((xz_factor + animation_tick + (vertex_position_in.y * wave_factor)) * animation_speed_factor * 0.75) * vertex_height_factor * animation_scale;
	vec3 vertex_offset = vec3(x_animation, 0.0, z_animation);
	world_pos.xyz = world_pos.xyz + vertex_offset;

	vec4 world_pos_prev = mat_world_prev * vec4(vertex_position_in, 1.0);
	world_pos_prev.xyz = world_pos_prev.xyz + vertex_offset;
	world_pos_prev.y -= camera_to_vertex_length / 30.0;

	vertex_world_position_out = world_pos.xyz;

	vertex_position_prev_out = mat_view_proj_prev * world_pos_prev;
	vertex_position_next_out = mat_view_proj_next * (mat_world_next * vec4(vertex_position_in, 1.0));

	gl_Position = mat_view_proj * world_pos;
}

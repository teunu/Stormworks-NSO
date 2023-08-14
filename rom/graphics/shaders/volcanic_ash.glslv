#include "depth_utils.glslh"

in vec3 vertex_position_in;
in vec3 vertex_color_in;
in vec3 vertex_normal_in;

out float log_z;
out vec3 vertex_color_out;
out vec3 vertex_normal_out;
out vec3 vertex_world_position_out;
out float radius_factor_out;

uniform sampler2D texture_heightmap;
uniform sampler2D texture_noise;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

uniform float anim;
uniform vec3 heightmap_min;
uniform vec3 heightmap_max;
uniform float volcano_height;
uniform float eruption_radius;

void main()
{
	float radius_start = 10.0;

	vec2 xz_norm = normalize(vertex_position_in.xz);
	float noise_sample = texture(texture_noise, vec2(atan(xz_norm.x, xz_norm.y) / 3.14159265, 0.001953125)).r;
	float anim_noise = anim - (noise_sample * min(anim*4.0, 1.0) * 0.2);
	anim_noise = clamp(anim_noise, 0.0, 1.0);

	float radius = mix(radius_start, eruption_radius, anim_noise);

	vec3 vertex_modified = vertex_position_in * vec3(radius, 1.0, radius);

	vertex_color_out = vec3(0.1, 0.1, 0.1);
	vertex_normal_out = (mat_world * vec4(vertex_normal_in, 0.0)).xyz;

	vec4 world_pos = mat_world * vec4(vertex_modified, 1.0);

	vec2 heightmap_uv = vec2((world_pos.x - heightmap_min.x) / (heightmap_max.x - heightmap_min.x), (world_pos.z - heightmap_min.z) / (heightmap_max.z - heightmap_min.z));
	heightmap_uv = clamp(heightmap_uv, vec2(0.0, 0.0), vec2(1.0, 1.0));
	float texture_sample = texture(texture_heightmap, heightmap_uv).r;

	float d = radius - length(vertex_modified.xz);
	float height_factor = clamp((1.0 - (d/2500.0)) * (1.0 - anim), 0.2, 1.0);

	radius_factor_out = length(vertex_modified.xz) / radius;

	world_pos.y = mix(heightmap_min.y, heightmap_max.y, (vertex_position_in.y * texture_sample)) + (vertex_position_in.y * ((volcano_height + 100.0) * 0.25)) - 10.0;
	
	vertex_world_position_out = world_pos.xyz;

	gl_Position = mat_view_proj * world_pos;
	encode_depth(gl_Position, log_z);

}

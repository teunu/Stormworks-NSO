in vec3 vertexPosition_in;

uniform mat4 mat_view_proj;
uniform vec4 instance_offset_world;

layout(std140) uniform instance_data
{
	mat4 instance_world[1000];
};

void main()
{
	vec4 vertexWorldPos = (instance_world[gl_InstanceID] * vec4(vertexPosition_in, 1)) + instance_offset_world;
	gl_Position =  mat_view_proj * vertexWorldPos;
}

in vec3 vertexPosition_in;
in vec2 vertexCoord0_in;

out vec4 vertexColor_out;
out vec2 vertexCoord0_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

uniform vec4 quad_color;
uniform vec4 uv_coords;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertexPosition_in, 1);

	vertexColor_out = quad_color;
	vertexCoord0_out = vec2(mix(uv_coords.x, uv_coords.y, vertexCoord0_in.x), mix(uv_coords.z, uv_coords.w, vertexCoord0_in.y));
}
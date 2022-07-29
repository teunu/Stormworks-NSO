in vec3 vertexPosition_in;
in vec4 vertexColor_in;
in vec3 vertexNormal_in;

out vec4 vertexColor_out;
out vec3 vertexNormal_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;
uniform vec4 override_color_1;
uniform vec4 override_color_2;
uniform vec4 override_color_3;
uniform int is_preview;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertexPosition_in, 1);

	vec3 override_color_1_difference = vertexColor_in.rgb - vec3(1.0, 0.494, 0.0);
	vec3 override_color_2_difference = vertexColor_in.rgb - vec3(0.608, 0.494, 0.0);
	vec3 override_color_3_difference = vertexColor_in.rgb - vec3(0.216, 0.494, 0.0);

	vec3 surface_color_difference = vertexColor_in.rgb - vec3(1.0, 1.0, 1.0);
	
	if(is_preview == 1 && (dot(override_color_1_difference, override_color_1_difference) < 0.01 || dot(surface_color_difference, surface_color_difference) < 0.01))
	{
		vertexColor_out = override_color_1;
	}
	else if(is_preview == 1 && (dot(override_color_2_difference, override_color_2_difference) < 0.01 || dot(surface_color_difference, surface_color_difference) < 0.01))
	{
		vertexColor_out = override_color_2;
	}
	else if(is_preview == 1 && (dot(override_color_3_difference, override_color_3_difference) < 0.01 || dot(surface_color_difference, surface_color_difference) < 0.01))
	{
		vertexColor_out = override_color_3;
	}
	else
	{
		vertexColor_out = vertexColor_in;
	}

	vertexNormal_out = (mat_world * vec4(vertexNormal_in, 0)).xyz;
}

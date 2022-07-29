in float out_y_pos;

out vec4 color_out;

uniform float max_height;

void main()
{
	float normalised_y_pos = (out_y_pos / max_height) + 0.5;

	color_out = vec4(normalised_y_pos, normalised_y_pos, normalised_y_pos, 1.0);
}

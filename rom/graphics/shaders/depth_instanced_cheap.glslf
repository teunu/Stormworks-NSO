out vec4 color_out;

void main()
{
	float depth = gl_FragCoord.z;
	color_out = vec4(depth);
}

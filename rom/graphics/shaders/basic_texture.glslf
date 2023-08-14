#include "depth_utils.glslh"

in float log_z;
in vec4 vertexColor_out;
in vec2 vertexCoord0_out;

out vec4 color_out;

uniform sampler2D textureDiffuse;
uniform float alpha;
uniform vec4 multiply_color;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);
	
	color_out = texture(textureDiffuse, vertexCoord0_out) * vertexColor_out * multiply_color;
	color_out.a *= alpha;
}

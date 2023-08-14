#define USE_LOG2
#define DEPTH_LOG_IN_FRAGMENT

const float near = 0.025;
const float far = 20100.0;
const float C = 0.01f;
const float Inv_C = 1.0 / C;
const float E = 2.718281828459045;
#ifdef USE_LOG2
    const float FC = log2(far*C + 1.0);
    const float Inv_FC = 1.0 / FC;
#else
    const float FC = log(far*C + 1.0);
    const float Inv_FC = 1.0 / FC;
#endif


float log_z_to_frag_depth(float log_z)
{
#ifdef DEPTH_LOG_IN_FRAGMENT
    #ifdef USE_LOG2
        return log2(log_z) * Inv_FC;
    #else
        return log(log_z) * Inv_FC;
    #endif
#else
    return log_z;
#endif
}

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

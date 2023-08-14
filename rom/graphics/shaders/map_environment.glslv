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


void encode_depth(vec4 pos, out float log_z_out)
{
#ifdef DEPTH_LOG_IN_FRAGMENT
        log_z_out = pos.w*C + 1.0;
#else
    #ifdef USE_LOG2
        log_z_out = log2(pos.w*C + 1.0) * Inv_FC;
    #else
        log_z_out = log(max(1e-6, pos.w)*C + 1.0) * Inv_FC;
    #endif
#endif
}


in vec3 vertexPosition_in;
in vec2 vertexCoord0_in;
in vec4 vertexColor_in;

out float log_z;
out vec4 vertexColor_out;
out vec2 vertexCoord0_out;

uniform mat4 mat_view_proj;
uniform mat4 mat_world;

void main()
{
	gl_Position =  mat_view_proj * mat_world * vec4(vertexPosition_in, 1);
	encode_depth(gl_Position, log_z);
	vertexColor_out = vertexColor_in;
	vertexCoord0_out = vertexCoord0_in;
}

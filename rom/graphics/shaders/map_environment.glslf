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

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

in float log_z;
in vec4 vertexColor_out;
in vec2 vertexCoord0_out;

out vec4 color_out;

uniform sampler2D textureDiffuse;

uniform int render_mode;

uniform float time_factor;
uniform float season_factor = 0.5;
uniform float daytime_factor = 1;
uniform vec2 sample_pos;

float floor_step(float value, float step)
{
	return floor(value / step) * step;
}

void main()
{
    float alpha = 0.4;

	gl_FragDepth = log_z_to_frag_depth(log_z);

    vec2 coords0 = (vertexCoord0_out * 4.0) + vec2(time_factor * -1000, time_factor * 100);
    vec2 coords1 = (vertexCoord0_out * 4.0) + vec2(time_factor * -100, time_factor * 10);

    if(render_mode == 1)
    {
        float temperature = texture(textureDiffuse, coords0).x * texture(textureDiffuse, coords1).x;
        temperature = clamp(temperature - (vertexCoord0_out.y * 16) + 8.35 + (0.05 * daytime_factor) + (0.3 * season_factor), 0.0, 1.0);

        float hue = mix(0.7, 0.0, temperature);

        color_out = vec4(hsv2rgb(vec3(hue, 1.0, 1.0)), alpha);
    }
    else if(render_mode == 2)
    {
        float rain = (texture(textureDiffuse, coords0).y * texture(textureDiffuse, coords1).y) - 0.15;
        rain = rain * 5.0;

        rain = clamp(rain, 0.0, 1.0);

        rain = floor_step(rain, 0.2);

        float hue = mix(0.7, 0.4, rain);

        color_out = vec4(hsv2rgb(vec3(hue, rain, rain)), alpha);
    }
    else if(render_mode == 3)
    {
        float fog = texture(textureDiffuse, coords0).z * texture(textureDiffuse, coords1).z;
        fog = fog * 3.0;

        fog = clamp(fog, 0.0, 1.0);
       
        float hue = mix(0.5, 0.2, fog);

        color_out = vec4(hsv2rgb(vec3(hue, 1.0 - fog, fog)), alpha);
    }
    else if(render_mode == 4)
    {
        float wind = texture(textureDiffuse, coords0).y * texture(textureDiffuse, coords1).y;
        wind = wind * 4.0;

        wind = clamp(wind, 0.0, 1.0);

        float hue = mix(0.7, 0.0, wind);

        color_out = vec4(hsv2rgb(vec3(hue, 1.0, 1.0)), alpha);
    }
    else
    {
        color_out = vec4(1.0, 1.0, 1.0, 1.0);
    }
}

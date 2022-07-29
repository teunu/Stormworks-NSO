in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_diffuse;
uniform sampler2D textures_bloom[5];

uniform int color_mode;
uniform float color_mode_factor;
uniform int has_film_grain;
uniform int vignette_mode;
uniform float vignette_distance_threshold;
uniform float vignette_strength;
uniform float grain_strength;
uniform float contrast;
uniform int is_bloom_enabled;
uniform vec4 vignette_color;
uniform vec2 noise_offset;
uniform float screen_aspect;

uniform float exposure;

const float A = 0.22; // Shoulder Strength
const float B = 0.10; // Linear Strength
const float C = 0.10; // Linear Angle
const float D = 0.50; // Toe Strength
const float E = 0.01; // Toe Numerator
const float F = 0.30; // Toe Denominator
const float W = 11.2; // Linear White Point Value

vec3 uncharted_2_tonemap(vec3 x)
{
    x *= exposure;
    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

vec3 exp_tonemap(vec3 x)
{
    return vec3(1.0) - exp(-x * exposure);
}

float rand(vec2 co) // returns 0 -> +1
{
    return (fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453));
}

vec4 get_black_and_white(vec4 color_in)
{
    vec4 bw;
    bw.rgb = mix(vec3(color_in.a), color_in.rgb, 0.0);
    bw.a = color_in.a;

    return bw;
}

vec4 get_sepia(vec4 color_in)
{
    vec4 sepia;
    sepia.r = dot(color_in.rgb, vec3(0.393, 0.769, 0.189));
    sepia.g = dot(color_in.rgb, vec3(0.349, 0.686, 0.168));
    sepia.b = dot(color_in.rgb, vec3(0.272, 0.534, 0.131));
    sepia.a = color_in.a;

    return sepia;
}

vec4 get_grey_green(vec4 color_in)
{
    vec4 bw =  get_black_and_white(color_in);

    vec4 gg;
    gg.r = mix(color_in.r, bw.r, 0.05);
    gg.g = mix(color_in.g, bw.g, 0.05);
    gg.b = mix(color_in.b, bw.b, 1.0);
    gg.a = color_in.a;

    return gg;
}

vec4 get_cyan_filter(vec4 color_in)
{
    vec4 cyan;
    cyan.r = max(color_in.r - 0.16, 0.0);
    cyan.g = min(color_in.g + 0.07, 1.0);
    cyan.b = min(color_in.b + 0.07, 1.0);
    cyan.a = color_in.a;
    return cyan;
}

vec4 get_red_filter(vec4 color_in)
{
    vec4 red;
    red.r = min(color_in.r + 0.14, 1.0);
    red.g = max(color_in.g - 0.07, 0.0);
    red.b = max(color_in.b - 0.07, 0.0);
    red.a = color_in.a;
    return red;
}

vec4 get_cross_process_1(vec4 color_in)
{
    vec4 cross_processed;
    cross_processed.r = 0.02 + 1 / (1 + exp((0.6-color_in.r)*9));
    cross_processed.g = 1 / (1 + exp((0.6-color_in.g)*4));
    cross_processed.b = 1 / (1 + exp((0.5-color_in.b)*8));
    cross_processed.a = color_in.a;
    return cross_processed;
}

vec4 get_cross_process_2(vec4 color_in)
{
    vec4 cross_processed;
    cross_processed.r = 1 / (1 + exp((0.5-color_in.r)*8));
    cross_processed.g = 0.02 + 1 / (1 + exp((0.6-color_in.g)*9));
    cross_processed.b = 1 / (1 + exp((0.6-color_in.b)*4));
    cross_processed.a = color_in.a;
    return cross_processed;
}

vec4 get_cross_process_3(vec4 color_in)
{
    vec4 cross_processed;

    cross_processed.r = 1 / (1 + exp((0.6-color_in.r)*4));
    cross_processed.g = 1 / (1 + exp((0.5-color_in.g)*8));
    cross_processed.b = 0.04 + 1 / (1 + exp((0.7-color_in.b)*16));

    cross_processed.a = color_in.a;
    return cross_processed;
}

void main()
{
    vec3 tex_color = texture(texture_diffuse, vertex_coord0_out).rgb;

    if(is_bloom_enabled == 1)
    {
        vec4 bloom_colors[5];
        bloom_colors[0] = texture(textures_bloom[0], vertex_coord0_out);
        bloom_colors[1] = texture(textures_bloom[1], vertex_coord0_out);
        bloom_colors[2] = texture(textures_bloom[2], vertex_coord0_out);
        bloom_colors[3] = texture(textures_bloom[3], vertex_coord0_out);
        bloom_colors[4] = texture(textures_bloom[4], vertex_coord0_out);

        vec3 color_bloom =
            (bloom_colors[0].rgb
            + bloom_colors[1].rgb
            + bloom_colors[2].rgb
            + bloom_colors[3].rgb
            + bloom_colors[4].rgb) * 0.2;

        tex_color += color_bloom;
    }

    // Adjust exposure before tonemapping
    vec3 tonemapped = uncharted_2_tonemap(tex_color);
    vec3 white = uncharted_2_tonemap(vec3(W));

	color_out = vec4(tonemapped / white, 1.0);

    // Apply gamma correction
	float gamma_correction_factor = 1.0 / 2.2;
	color_out.r = pow(color_out.r, gamma_correction_factor);
	color_out.g = pow(color_out.g, gamma_correction_factor);
	color_out.b = pow(color_out.b, gamma_correction_factor);

    // Calculate luma of this pixel and store in alpha channel (for use in FXAA)
    const vec3 luma_weights = vec3(0.299, 0.587, 0.114);
    color_out.a = dot(color_out.rgb, luma_weights);

    // Contrast
    color_out.rgb = ((color_out.rgb - 0.5f) * max(contrast, 0)) + 0.5f;

    vec4 orig_color = color_out;

    if(color_mode == 1)
    {
        // Black and White
        color_out = mix(orig_color, get_black_and_white(color_out), color_mode_factor);
    }
    else if(color_mode == 2)
    {
        // Sepia
        color_out = mix(orig_color, get_sepia(color_out), color_mode_factor);
    }
    else if(color_mode == 3)
    {
        // grey/green
        color_out = mix(orig_color, get_grey_green(color_out), color_mode_factor);
    }
    else if(color_mode == 4)
    {
        // cyan
        color_out = mix(orig_color, get_cyan_filter(color_out), color_mode_factor);
    }
    else if(color_mode == 5)
    {
        // red
        color_out = mix(orig_color, get_red_filter(color_out), color_mode_factor);
    }
    else if(color_mode == 6)
    {
        // cross process 1
        color_out = mix(orig_color, get_cross_process_1(color_out), color_mode_factor);
    }
    else if(color_mode == 7)
    {
        // cross process 2
        color_out = mix(orig_color, get_cross_process_2(color_out), color_mode_factor);
    }
    else if(color_mode == 8)
    {
        // cross process 3
        color_out = mix(orig_color, get_cross_process_3(color_out), color_mode_factor);
    }

    if(has_film_grain == 1)
    {
        // Grain
        color_out.rgb *= rand(gl_FragCoord.xy + noise_offset) * grain_strength + (1.0 - grain_strength);
    }

    if(vignette_mode > 0)
    {
        // Vignette
        vec2 center_to_fragment = (vertex_coord0_out - vec2(0.5)) * 2.0 * vec2(screen_aspect, 1.0);
        float dist_from_centre = dot(center_to_fragment, center_to_fragment);
        float vignette_amount = clamp(dist_from_centre - vignette_distance_threshold, 0.0, 1.0);
        float vignette_clarity_factor = clamp(1.0 - (vignette_amount * vignette_strength), 0.0, 1.0);

        if(vignette_mode == 1)
        {
            //black
            color_out.rgb *= vignette_clarity_factor;
        }
        else if(vignette_mode == 2)
        {
            //white
            color_out.rgb = mix(vec3(1,1,1), color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 3)
        {
            // original color
            color_out.rgb = mix(orig_color.rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 4)
        {
            //black and white
            color_out.rgb = mix(get_black_and_white(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 5)
        {
            //sepia
            color_out.rgb = mix(get_sepia(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 6)
        {
            // grey/green
            color_out.rgb = mix(get_grey_green(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 7)
        {
            // cyan
            color_out.rgb = mix(get_cyan_filter(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 8)
        {
            // red
            color_out.rgb = mix(get_red_filter(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 9)
        {
            // cross process 1
            color_out.rgb = mix(get_cross_process_1(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 10)
        {
            // cross process 2
            color_out.rgb = mix(get_cross_process_2(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 11)
        {
            // cross process 3
            color_out.rgb = mix(get_cross_process_3(orig_color).rgb, color_out.rgb, vignette_clarity_factor);
        }
        else if(vignette_mode == 12)
        {
            color_out.rgb = mix(vignette_color.rgb, color_out.rgb, vignette_clarity_factor * vignette_color.a);
        }
    }
} 

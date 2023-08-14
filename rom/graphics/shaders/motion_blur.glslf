in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_color;
uniform sampler2D texture_velocity;
uniform sampler2D texture_velocity_neighbormax;
uniform sampler2D texture_depth;

uniform vec2 rand_offset;

uniform vec2 screen_size;

#define MAX_VELOCITY_TEXELS 30
#define MAX_BLUR_SAMPLES 4
#define VELOCITY_SCALE 0.1

#define USE_NEIGHBORMAX 0

float rand_noise()
{
    return fract(sin(dot(gl_FragCoord.xy + rand_offset, vec2(12.9898, 78.233))) * 43758.5453);
}

float rand()
{
    const float scale = 0.25;
    vec2 position_mod = vec2(ivec2(gl_FragCoord.xy) & 1);
    return (-scale + 2.0 * scale * position_mod.x) * (-1.0 + 2.0 * position_mod.y) +
        0.5 * scale * (-1.0 + 2.0 * rand_offset.x);
}

vec2 decode_velocity(vec2 velocity)
{
    return velocity;
}

float linearize_depth(float depth)
{
    const float NEAR = 0.1; // Projection matrix's near plane distance
    const float FAR = 4100.0; // Projection matrix's far plane distance

    float z = depth * 2.0 - 1.0;
    return (2.0 * NEAR * FAR) / (FAR + NEAR - z * (FAR - NEAR));
}

vec2 depth_compare(float center_z, float sample_z, float z_scale)
{
    return clamp(0.5 + vec2(z_scale, -z_scale) * (sample_z - center_z), 0.0, 1.0);
}

vec2 spread_compare(float offset_length, vec2 spread_length, float pixel_to_sample_units_scale)
{
    return clamp(pixel_to_sample_units_scale * spread_length - offset_length + 1.0, 0.0, 1.0);
}

float sample_total_weight(float center_z, float sample_z, float offset_length, float center_spread_length, float sample_spread_length, float pixel_to_sample_units_scale, float z_scale)
{
    vec2 depth_comp = depth_compare(center_z, sample_z, z_scale);
    vec2 spread_comp = spread_compare(offset_length, vec2(center_spread_length, sample_spread_length), pixel_to_sample_units_scale);
    return dot(depth_comp, spread_comp);
}

float soft_depth_compare(float za, float zb)
{
    const float SOFT_Z_EXTENT = 0.01;

    za = linearize_depth(za);
    zb = linearize_depth(zb);
    return clamp(1.0 - (za - zb) / SOFT_Z_EXTENT, 0.0, 1.0);
}

float cone(vec2 X, vec2 Y, float v_mag)
{
    return clamp(1.0 - length(X - Y) / v_mag, 0.0, 1.0);
}

float cylinder(vec2 X, vec2 Y, float v_mag)
{
    return 1.0 - smoothstep(0.95 * v_mag, 1.05 * v_mag, length(X - Y));
}

float round(float f32_value, float f32_precision)
{
    return floor((f32_value * (1.0 / f32_precision)) + 0.5) * f32_precision;
}

vec4 sample_color_motion(sampler2D tex, vec2 uv, vec2 vmax)
{
    vmax *= screen_size;
    vec2 wn = normalize(vmax);
    vec2 vc = texture(texture_velocity, vertex_coord0_out).xy * screen_size * VELOCITY_SCALE;
    vc = min(vc, vec2(MAX_VELOCITY_TEXELS));
    vec2 wp = vec2(-wn.y, wn.x);
    if(dot(wp, vc) < 0)
    {
        wp = -wp;
    }
    const float velocity_threshold = 1.5;
    float vc_length = length(vc);
    vec2 wc = normalize(mix(wp, vc / vc_length, (vc_length - 0.5) / velocity_threshold));

    vec2 X = uv;
    float mag_x = length(vmax);
    float depth_x = -texture(texture_depth, X).r;

    const float K = 40;
    // float total_weight = MAX_BLUR_SAMPLES / (K * vc_length + 0.0001);
    float total_weight = 1.0 / mag_x;
    vec4 sum = texture(tex, X) * total_weight;

    float j = rand() - 0.5;

    float pixel_to_sample_units_scale = MAX_BLUR_SAMPLES / mag_x;

    for(int i = 0; i < MAX_BLUR_SAMPLES; i++)
    {
        //if(i != (MAX_BLUR_SAMPLES - 1) / 2)
        {
            // Choose evenly placed filter taps along ±vel,
            // but jitter the whole filter to prevent ghosting
            float t = mix(-1.0, 1.0, (float(i) + j + 1.0) / (MAX_BLUR_SAMPLES + 1.0));
            // vec2 Y = vec2(X + vmax * t);

            vec2 d = i % 2 == 1 ? vc : vmax;
            // float T = t * mag_x;
            vec2 Y = (t * d / screen_size) + X;

            // Fore- vs. background classification of Y relative to X
            float depth_y = -texture(texture_depth, Y).r;

            vec2 vel_y = decode_velocity(texture(texture_velocity, Y).xy) * screen_size * VELOCITY_SCALE;
            vel_y = min(vel_y, vec2(MAX_VELOCITY_TEXELS));

            float mag_y = length(vel_y);

            float offset_length = float(i) + j + 1.0;

            float weight = sample_total_weight(depth_x, depth_y, offset_length, vc_length, mag_y, pixel_to_sample_units_scale, 1.0);
            // Accumulate
            total_weight += weight;

            sum += weight * texture(tex, Y);
        }
    }

    return sum / total_weight;
}

float round_correct(float x)
{
    return floor(x + 0.5f);
}

vec4 motion_blur()
{
#if USE_NEIGHBORMAX
    float rand1 = rand_noise();
    float rand2 = rand();
    if(sign(rand1) == sign(rand2) || sign(rand1) == -sign(rand2))
    {
        rand2 = 0.0;
    }
	vec2 tile_jitter = vec2( round_correct(rand1 * 2.0 - 1.0), round_correct(rand2) );
	vec2 tile_uv = vertex_coord0_out + tile_jitter / textureSize(texture_velocity_neighbormax, 0);

    vec2 velocity = decode_velocity(texture(texture_velocity_neighbormax, tile_uv).xy);
#else
    vec2 velocity = decode_velocity(texture(texture_velocity, vertex_coord0_out).xy);
#endif
    velocity *= VELOCITY_SCALE;

    vec2 texel_size = vec2(1.0) / screen_size;
    vec2 vel_texels = velocity / texel_size;
    const float max_velocity_texels = MAX_VELOCITY_TEXELS;
    vel_texels = clamp(vel_texels, vec2(-max_velocity_texels), vec2(max_velocity_texels));

    velocity = vel_texels * texel_size;

    if(dot(velocity, velocity) > 0.00001)
    {
    	return sample_color_motion(texture_color, vertex_coord0_out, velocity);
    }
    else
    {
        return texture(texture_color, vertex_coord0_out);
    }
}

void main()
{
    color_out = motion_blur();
}

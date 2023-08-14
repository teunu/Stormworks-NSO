in vec2 vertex_coord0_out;

out vec4 color_out;

// #define USE_YCOCG

uniform sampler2D texture_color;
uniform sampler2D texture_velocity;
uniform sampler2D texture_noise;
uniform sampler2D texture_color_last_frame;
uniform sampler2D texture_depth;

uniform vec2 screen_size;
uniform vec2 noise_texture_size;

uniform vec2 rand_offset;

float linear_eye_depth(float depth)
{
    const float NEAR = 0.1; // Projection matrix's near plane distance
    const float FAR = 4100.0; // Projection matrix's far plane distance

    float z = depth * 2.0 - 1.0;
    return (2.0 * NEAR * FAR) / (FAR + NEAR - z * (FAR - NEAR));
}

vec4 rand(vec2 co) // returns 0 -> +1
{
    co *= screen_size / noise_texture_size;
    return texture(texture_noise, co + rand_offset);
}

vec2 decode_velocity(vec2 velocity)
{
    return velocity;
}

vec3 find_closest_fragment(vec2 uv)
{
    vec2 dd = screen_size;
    vec2 k = vec2(1.0) / dd;

    vec4 neighborhood = vec4(
				texture(texture_depth, uv - k).r,
				texture(texture_depth, uv + vec2(k.x, -k.y)).r,
				texture(texture_depth, uv + vec2(-k.x, k.y)).r,
				texture(texture_depth, uv + k).r);

	vec3 result = vec3(0, 0, texture(texture_depth, uv).r);

	if (neighborhood.x < result.z)
		result = vec3(-1, -1, neighborhood.x);

	if (neighborhood.y < result.z)
		result = vec3(1, -1, neighborhood.y);

	if (neighborhood.z < result.z)
		result = vec3(-1, 1, neighborhood.z);

	if (neighborhood.w < result.z)
		result = vec3(1, 1, neighborhood.w);

    return vec3(uv + result.xy * k, result.z);
}

// Intersect ray with AABB, knowing there is an intersection.
//   Dir = Ray direction.
//   Org = Start of the ray.
//   Box = Box is at {0,0,0} with this size.
// Returns distance on line segment.
float IntersectAABB(vec3 Dir, vec3 Org, vec3 Box)
{
	vec3 RcpDir = vec3(1.0) / Dir;
	vec3 TNeg = (  Box  - Org) * RcpDir;
	vec3 TPos = ((-Box) - Org) * RcpDir;
	return max(max(min(TNeg.x, TPos.x), min(TNeg.y, TPos.y)), min(TNeg.z, TPos.z));
}

float HistoryClamp(vec3 History, vec3 Filtered, vec3 neighborMin, vec3 neighborMax)
{
	vec3 Min = min(Filtered, min(neighborMin, neighborMax));
	vec3 Max = max(Filtered, max(neighborMin, neighborMax));
	vec3 Avg2 = (Max + Min) * 0.5;
	vec3 Dir = (Filtered - History);
	vec3 Org = History - Avg2;
	vec3 Scale = Max - Avg2;
	return clamp(IntersectAABB(Dir, Org, Scale), 0.0, 1.0);
}

vec3 RGB_YCoCg(vec3 c)
{
    // Y = R/4 + G/2 + B/4
    // Co = R/2 - B/2
    // Cg = -R/4 + G/2 - B/4
    return vec3(
         c.x/4.0 + c.y/2.0 + c.z/4.0,
         c.x/2.0 - c.z/2.0,
        -c.x/4.0 + c.y/2.0 - c.z/4.0
    );
}

vec3 YCoCg_RGB(vec3 c)
{
    // R = Y + Co - Cg
    // G = Y + Cg
    // B = Y - Co - Cg
    return clamp(vec3(
        c.x + c.y - c.z,
        c.x + c.z,
        c.x - c.y - c.z),
        0.0, 1.0
    );
}

vec4 sample_color(sampler2D tex, vec2 uv)
{
    vec4 c = clamp(texture(tex, uv), vec4(0.0), vec4(100.0));
    if(isinf(c.x) || isnan(c.x)) c.x = 0.0;
    if(isinf(c.y) || isnan(c.y)) c.y = 0.0;
    if(isinf(c.z) || isnan(c.z)) c.z = 0.0;
    if(isinf(c.w) || isnan(c.w)) c.w = 0.0;
#if defined(USE_YCOCG)
    return vec4(RGB_YCoCg(c.rgb), c.a);
#else
    return c;
#endif
}

vec4 resolve_color(vec4 c)
{
#if defined(USE_YCOCG)
    return vec4(YCoCg_RGB(c.rgb).rgb, c.a);
#else
    return c;
#endif
}

float sample_luma(vec4 color)
{
#if defined(USE_YCOCG)
    return color.r;
#else
    return dot(color.rgb, vec3(0.299, 0.587, 0.114));
#endif
}

vec4 temporal_aa()
{
    vec2 target_size = screen_size;
    vec2 texel_size = vec2(1.0) / target_size;

    vec2 uv = vertex_coord0_out;

    vec3 closest_fragment = find_closest_fragment(uv);
    vec2 velocity = decode_velocity(texture(texture_velocity, closest_fragment.xy).xy);

    vec4 color_result = sample_color(texture_color, uv);

    vec4 color_last_frame = sample_color(texture_color_last_frame, vertex_coord0_out - velocity);

    vec4 noise = rand(vertex_coord0_out) / 800.0;
    // Remove noise added in the last frame to reduce flickering
    color_last_frame -= noise;

    /////////////////////////////////////////
    vec4 cmin = vec4(1000);
    vec4 cmax = vec4(0);

    vec4 lowpass_filtered_color = vec4(0.0);
    float total_lowpass_weights = 0.0;

    for(int x = -1; x <= 1; x++)
    {
        for(int y = -1; y <= 1; y++)
        {
            vec4 neighbor_color = sample_color(texture_color, uv + texel_size * vec2(x, y));
            cmin = min(cmin, neighbor_color);
            cmax = max(cmax, neighbor_color);

            // I know this looks bad, but it's actually more efficient than calculating the weights
            // offline and passing them in! (Thanks GLSL compiler)
            float p_x = float(x) * 0.375; // 0.25 * 1.5 = 0.375
            float p_y = float(y) * 0.375;
            float weight = exp( -2.29f * ( p_x * p_x + p_y * p_y ) );
            total_lowpass_weights += weight;
            lowpass_filtered_color += neighbor_color * weight;
        }
    }

    lowpass_filtered_color /= total_lowpass_weights;

	float luma_min = sample_luma(cmin);
	float luma_max = sample_luma(cmax);
	float luma_history = sample_luma(color_last_frame);
    float luma_contrast = luma_max - luma_min;
    /////////////////////////////////////////

    float clip_factor = HistoryClamp(color_last_frame.rgb, lowpass_filtered_color.rgb, cmin.rgb, cmax.rgb);
    vec3 clipped_history_color = mix(color_last_frame.rgb, lowpass_filtered_color.rgb, clip_factor);

    color_last_frame.rgb = clipped_history_color;

    // Compute history blend factor - adapted from UE4's implementation
    // ----------------------------
    // Get minimum local contrast between this frame and history (which equals how much clamping has been done)
    float dist_to_clamp = min(abs(luma_min-luma_history), abs(luma_max-luma_history));

	float history_blur_scale = 100.0;
    // Blur factor is the distance the history is from this frame, scaled by history_blur_scale
	float history_blur_factor = clamp(abs(velocity.x) * history_blur_scale + abs(velocity.y) * history_blur_scale, 0.0, 1.0);

    float history_factor = dist_to_clamp * (history_blur_factor + 0.175);

	float smoothing_factor = clamp(history_factor / (dist_to_clamp + luma_contrast), 0.0, 1.0);

	// If the history pixel is offscreen, don't blend it
	bool is_history_offscreen = max(abs(vertex_coord0_out.x - velocity.x), abs(vertex_coord0_out.y - velocity.y)) >= 1.0;
	if(is_history_offscreen)
	{
        smoothing_factor = 1.0;
	}

    // Smoothing notes: ~0.85 is the minimum value that will stop fading.
    //                  ~0.2 is the maximum value that stops visible flickering on most surfaces.

    vec4 color_temporal = vec4(0, 0, 0, 1);
    color_temporal.rgb = mix(color_last_frame.rgb, color_result.rgb, smoothing_factor);

    color_result = resolve_color(color_temporal);

    // Add noise to reduce banding
    color_result.rgb += noise.rgb;

    return color_result;
}

void main()
{
    color_out = temporal_aa();
}

in vec2 v_texCoord;

out vec4 color_out;

uniform sampler2D texture_color;  // Texture that will be blurred by this shader
uniform sampler2D texture_depth;
uniform float blur_radius;
uniform float blur_size;

const float pi = 3.14159265;

const float numBlurPixelsPerSide = 3.0f;
#if defined(HORIZONTAL_BLUR)
const vec2  blurMultiplyVec      = vec2(1.0f, 0.0f);
#elif defined(VERTICAL_BLUR)
const vec2  blurMultiplyVec      = vec2(0.0f, 1.0f);
#endif

#ifndef DEPTH_AWARE
    #define DEPTH_AWARE 0
#endif

// Calculate distance from coord0 to sample to get correct blur weight
// using linear sampling
float blur_offset(float coord0_offset, float coord0_weight, float coord1_offset, float coord1_weight)
{
    float numerator = coord0_offset * coord0_weight + coord1_offset * coord1_weight;
    return numerator / (coord0_weight + coord1_weight);
}

vec4 blur(float blur_amount) {
    // Incremental Gaussian Coefficent Calculation (See GPU Gems 3 pp. 877 - 889)
    vec3 incrementalGaussian;
    incrementalGaussian.x = 1.0f / (sqrt(2.0f * pi) * blur_amount);
    incrementalGaussian.y = exp(-0.5f / (blur_amount * blur_amount));
    incrementalGaussian.z = incrementalGaussian.y * incrementalGaussian.y;

    vec4 avgValue = vec4(0.0f, 0.0f, 0.0f, 0.0f);
    float coefficientSum = 0.00000001f;

    // Take the central sample first...
    avgValue += texture(texture_color, v_texCoord.xy) * incrementalGaussian.x;
    coefficientSum += incrementalGaussian.x;
    incrementalGaussian.xy *= incrementalGaussian.yz;

#if DEPTH_AWARE
    float central_depth = texture(texture_depth, v_texCoord).r;
#endif

    // Go through the remaining samples
    for (float i = 1.0f; i < numBlurPixelsPerSide; i++) {
        vec2 next_gaussian = incrementalGaussian.xy * incrementalGaussian.yz;

        float offset = blur_offset(i, incrementalGaussian.x, i + 1, next_gaussian.x);
        vec2 coord0 = v_texCoord.xy - offset * blur_size * blurMultiplyVec;
        vec2 coord1 = v_texCoord.xy + offset * blur_size * blurMultiplyVec;
        vec4 sample0 = texture(texture_color, coord0);
        vec4 sample1 = texture(texture_color, coord1);

#if DEPTH_AWARE
        float depth_diff0 = central_depth - texture(texture_depth, coord0).r;
        float depth_diff1 = central_depth - texture(texture_depth, coord1).r;

        const float depth_diff_threshold = 10.0;
        float weight0 = mix(incrementalGaussian.x, 0.0, step(depth_diff_threshold, depth_diff0));
        float weight1 = mix(incrementalGaussian.x, 0.0, step(depth_diff_threshold, depth_diff1));
#else
        float weight0 = incrementalGaussian.x;
        float weight1 = incrementalGaussian.x;
#endif

        avgValue += (weight0 * sample0) + (weight1 * sample1);

        coefficientSum += weight0 + weight1;

        // avgValue += (sample0 + sample1) * incrementalGaussian.x;
        //
        // coefficientSum += 2.0 * incrementalGaussian.x;

        incrementalGaussian.xy = next_gaussian;
    }

    return vec4(avgValue / coefficientSum);
}

void main() {
    color_out = blur(blur_radius);
}

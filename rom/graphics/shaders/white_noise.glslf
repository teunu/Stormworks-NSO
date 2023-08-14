in vec2 vertexCoord0_out;

out vec4 color_out;

uniform sampler2D texture_noise;
uniform sampler2D texture_noise_perlin;
uniform vec2 rand_xy_0;
uniform vec2 rand_xy_1;
uniform float time_offset;
uniform float time;
uniform float noise_amount;

void main()
{
	float noise_color = texture(texture_noise, ((gl_FragCoord.xy + rand_xy_0) / vec2(128.0, 128.0)) + vec2(0.5, 0.5)).r;
	float noise_alpha = texture(texture_noise, ((gl_FragCoord.xy + rand_xy_1) / vec2(128.0, 128.0)) + vec2(0.5, 0.5)).r + 0.4;
	float noise_banding = texture(texture_noise_perlin, vec2(0.5, (gl_FragCoord.y / 256.0) + time + time_offset)).r;
	noise_banding = clamp((noise_banding * 8.0) - 5.6 + (noise_amount * 1.6), 0.0, 8.0);

	float noise_additive = clamp((noise_amount * 10.0) - 9.0, 0.0, 1.0);

	color_out = vec4(noise_color, noise_color, noise_color, clamp((noise_alpha * noise_banding * noise_amount) + noise_additive, 0.0, 1.0));
}

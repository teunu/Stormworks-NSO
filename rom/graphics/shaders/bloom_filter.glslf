in vec2 vertex_coord0_out;

out vec4 color_out;

uniform sampler2D texture_diffuse;

#define BRIGHTNESS_THRESHOLD 0.75

void main()
{
    vec3 texture_color = texture(texture_diffuse, vertex_coord0_out).rgb;

    vec3 luma_weights = vec3(0.299, 0.587, 0.114);
	float luma = dot(texture_color, luma_weights);

    if(luma > BRIGHTNESS_THRESHOLD)
    {
        luma = clamp(luma, 0.0, 1.5);
    	color_out = vec4(texture_color * (luma - BRIGHTNESS_THRESHOLD), 1.0);
    }
    else
    {
        color_out = vec4(0, 0, 0, 1);
    }
}

#include "depth_utils.glslh"

in float log_z;
in vec4 vertexColor_out;
in vec2 vertexCoord0_out;

out vec4 color_out;

uniform sampler2D texture_video;
uniform sampler2D texture_overlay;
uniform float alpha_video;
uniform float alpha;
uniform vec4 multiply_color;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);

    vec4 video_sample = texture(texture_video, vertexCoord0_out);
    vec4 overlay_sample = texture(texture_overlay, vertexCoord0_out);

    vec3 mix_sample = mix(video_sample.rgb * video_sample.a * alpha_video, overlay_sample.rgb, overlay_sample.a).rgb;
	
	color_out = vec4(mix_sample, 1.0) * vertexColor_out * multiply_color;
	color_out.a *= alpha;
}

#include "depth_utils.glslh"

in float log_z;
in float normal_dot;
in vec4 screen_normal;

out vec4 color_out;

uniform float intensity;

void main()
{
	gl_FragDepth = log_z_to_frag_depth(log_z);

    //Quickly ramp up distortion based on dot(camera->vertex, normal)

    float distortion = ((1.0-abs(normal_dot)) - 0.5) * 2.0;
    distortion = clamp(distortion, 0.0, 1.0);
    distortion = distortion * distortion;

    distortion *= intensity * intensity * 0.05;

    color_out = vec4(distortion, distortion, distortion, 1.0);
}

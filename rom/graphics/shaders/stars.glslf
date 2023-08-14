in vec3 vertex_position_out;
in vec4 vertex_color_out;

out vec4 color_out;

uniform float additive_factor;
uniform int animation_tick;

void main()
{
    if(vertex_position_out.y < 0.0)
    {
        discard;
    }

    color_out = vec4(vec3(1.0) * additive_factor * vertex_color_out.g * vertex_color_out.g * vertex_color_out.g, 0.2);
    float blink_factor = abs(sin(animation_tick * 0.01 + vertex_color_out.r * 6.28318530718));
    color_out.a *= 0.2 + 0.8 * blink_factor;
}

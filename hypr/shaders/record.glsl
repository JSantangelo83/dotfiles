#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);

    float darkness = 0.30;

    // From here
    float x = 501.0;
    float y = 454.0;
    float width = 690.0;
    float height = 382.0;
    // To here

    vec2 screen_size = vec2(2560.0, 1440.0);

    vec2 screen_coords = v_texcoord * screen_size;
    vec2 exclusion_max = vec2(x + width, y + height);

    if (screen_coords.x < x ||
        screen_coords.x > exclusion_max.x ||
        screen_coords.y < y ||
        screen_coords.y > exclusion_max.y) {
        fragColor = vec4(pixColor.rgb * (1.0 - darkness), pixColor.a);
    } else {
        fragColor = pixColor;
    }
}

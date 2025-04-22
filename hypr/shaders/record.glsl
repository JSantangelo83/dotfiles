precision highp float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    float darkness = 0.30;
    
    // From here
    float x = 501.0;
    float y = 454.0;        
    float width = 690.0;    
    float height = 382.0;   
    // To here

    vec4 pixColor = texture2D(tex, v_texcoord);

    vec2 screen_size = vec2(1920.0, 1080.0); 

    vec2 screen_coords = v_texcoord * screen_size;

    vec2 exclusion_max = vec2(x + width, y + height);
    
    if (screen_coords.x < x || 
        screen_coords.x > exclusion_max.x || 
        screen_coords.y < y || 
        screen_coords.y > exclusion_max.y) {
        
        vec3 darkenedColor = pixColor.rgb * (1.0 - darkness);
        gl_FragColor = vec4(darkenedColor, pixColor.a);
    } else {
        
        gl_FragColor = pixColor;
    }
}


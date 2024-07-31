shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec3 player_position;
uniform vec3 camera_position;
uniform float cylinder_radius = 5.0;
uniform vec4 fog_color : source_color;
uniform float fog_density = 0.1;

varying mat4 CAMERA;

void vertex() {
    POSITION = vec4(VERTEX, 1.0);
    CAMERA = INV_PROJECTION_MATRIX * INV_VIEW_MATRIX;
}

void fragment() {
    // Get depth and reconstruct world position
    float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 world = CAMERA * vec4(ndc, 1.0);
    vec3 world_position = world.xyz / world.w;

    // Calculate distance to cylinder axis
    vec3 player_to_camera = camera_position - player_position;
    vec3 player_to_point = world_position - player_position;
    float projection = dot(player_to_point, normalize(player_to_camera));
    vec3 closest_point = player_position + normalize(player_to_camera) * clamp(projection, 0.0, length(player_to_camera));
    float distance_to_axis = length(world_position - closest_point);

    // Calculate fog
    float fog_amount = 1.0 - exp(-distance(world_position, camera_position) * fog_density);
    
    // Clear fog in cylinder
    float clear_amount = smoothstep(cylinder_radius, cylinder_radius * 1.2, distance_to_axis);
    fog_amount *= clear_amount;

    // Mix fog with original color
    vec3 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
    vec3 final_color = mix(screen_color, fog_color.rgb, fog_amount);

    ALBEDO = final_color;
}
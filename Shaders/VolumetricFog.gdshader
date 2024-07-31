shader_type spatial;
render_mode blend_sub, depth_draw_never, cull_back, unshaded;

uniform vec4 fog_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform float cylinder_radius : hint_range(0.1, 20.0) = 5.0;
uniform vec3 player_position;
uniform vec3 camera_position;
uniform float edge_sharpness : hint_range(0.01, 1.0) = 0.1;
uniform float fog_intensity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    vec3 world_vertex = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    vec3 player_to_camera = camera_position - player_position;
    float cylinder_length = length(player_to_camera);
    vec3 cylinder_direction = normalize(player_to_camera);
    
    vec3 to_fragment = world_vertex - player_position;
    float projection = dot(to_fragment, cylinder_direction);
    
    vec3 closest_point_on_axis = player_position + cylinder_direction * clamp(projection, 0.0, cylinder_length);
    float distance_to_axis = length(world_vertex - closest_point_on_axis);
    
    float radial_alpha = smoothstep(cylinder_radius, cylinder_radius - edge_sharpness, distance_to_axis);
    
    float end_fade_length = cylinder_radius;
    float end_alpha = smoothstep(0.0, end_fade_length, projection) * smoothstep(cylinder_length, cylinder_length - end_fade_length, projection);
    
    float alpha = radial_alpha * end_alpha * fog_intensity;
    
    ALBEDO = fog_color.rgb;
    ALPHA = alpha;
}
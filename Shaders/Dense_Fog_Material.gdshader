shader_type spatial;

uniform vec3 camera_position;
uniform vec3 player_position;
uniform float fog_density = 0.05;
uniform float fog_start = 1.0;
uniform float fog_end = 20.0;
uniform float clear_radius = 5.0;

void fragment() {
    vec3 fog_color = vec3(0.7, 0.7, 0.7); // Adjust fog color here

    vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float distance_to_camera = distance(world_position, camera_position);
    float distance_to_player = distance(world_position, player_position);

    // Linear fog factor
    float fog_factor = clamp((distance_to_camera - fog_start) / (fog_end - fog_start), 0.0, 1.0);
    fog_factor *= fog_density;

    // Clear path between camera and player
    float clear_factor = smoothstep(0.0, clear_radius, distance_to_player);

    // Apply fog
    ALBEDO = mix(vec3(1.0), fog_color, fog_factor * (1.0 - clear_factor));
}

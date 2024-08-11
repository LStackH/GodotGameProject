shader_type spatial;

render_mode cull_front;

uniform vec3 sand_color : source_color = vec3(0.9, 0.75, 0.45);
uniform vec3 wet_sand_color : source_color = vec3(0.6, 0.5, 0.3);
uniform vec3 stone_tint : source_color = vec3(0.5, 0.5, 0.5); // Tint color for the stone

uniform float grain_size : hint_range(0.01, 0.1) = 0.05;
uniform float wave_scale : hint_range(0.1, 5.0) = 1.0;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.5;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.5;

uniform float elevation_threshold : hint_range(0.0, 10.0) = 5.0; // Height where the transition to stone happens
uniform float wet_sand_threshold : hint_range(0.0, 10.0) = 1.0; // Height where the wet sand starts
uniform float blend_sharpness : hint_range(0.01, 1.0) = 0.1; // Controls the smoothness of the blend

uniform sampler2D grain_noise;
uniform sampler2D wave_noise;
uniform sampler2D stone_texture; // The stone texture
uniform sampler2D stone_normal_map; // The normal map for the stone texture
uniform sampler2D stone_roughness_map; // The roughness texture for the stone

uniform sampler2D elevation_noise; // Noise texture for elevation variation

uniform float stone_scale : hint_range(0.1, 5.0) = 1.0; // Scale of the stone texture
uniform float elevation_noise_scale : hint_range(0.1, 5.0) = 1.0; // Scale of the elevation noise

uniform float pixelation_amount : hint_range(0.0, 512.0) = 16.0; // Controls the level of pixelation

varying vec2 uv_coords;
varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    uv_coords = UV;
}

void fragment() {
    // Apply pixelation to UV coordinates
    vec2 pixelated_uv = floor(uv_coords * pixelation_amount) / pixelation_amount;

    // Grainy sand effect
    vec2 grain_uv = pixelated_uv / grain_size;
    float grain_factor = texture(grain_noise, grain_uv).r;
    
    // Simulating waves in the sand
    vec2 wave_uv = pixelated_uv * wave_scale + vec2(TIME * wave_speed, 0.0);
    float wave_height = texture(wave_noise, wave_uv).r * 0.1;

    // Adding noise to the elevation threshold for variation
    float noise_value = texture(elevation_noise, pixelated_uv * elevation_noise_scale).r;
    float varied_elevation_threshold = elevation_threshold + noise_value * 0.5; // Adjust the 0.5 factor to control noise influence

    // Blend between sand and stone based on varied elevation
    float elevation_blend = smoothstep(varied_elevation_threshold - blend_sharpness, varied_elevation_threshold + blend_sharpness, world_pos.y);

    // Blend for wet sand based on elevation
    float wet_sand_blend = 1.0 - smoothstep(wet_sand_threshold - blend_sharpness, wet_sand_threshold + blend_sharpness, world_pos.y);

    // Sample the stone texture and normal map
    vec2 stone_uv = pixelated_uv * stone_scale;
    vec3 stone_color = texture(stone_texture, stone_uv).rgb * stone_tint;
    vec3 stone_normal_vec = texture(stone_normal_map, stone_uv).rgb * 2.0 - 1.0;
    float stone_roughness = texture(stone_roughness_map, stone_uv).r; // Sample the roughness texture

    // Blend stone color with sand color and wet sand
    vec3 blended_color = mix(sand_color, stone_color, elevation_blend);
    vec3 final_color = mix(blended_color, wet_sand_color, wet_sand_blend);

    // Combine grain and wave height to modulate sand/rock color
    vec3 color = mix(final_color, wet_sand_color, wave_height + grain_factor * 0.5);

    // Surface normal, blending between sand and stone normal maps
    vec3 normal_map = texture(wave_noise, wave_uv).rgb * 2.0 - 1.0;
    NORMAL = mix(NORMAL, mix(normal_map, stone_normal_vec, elevation_blend), normal_strength);

    // Roughness blending based on elevation and wet sand blend
    float roughness = mix(0.8, stone_roughness, elevation_blend);

    ROUGHNESS = roughness;

    ALBEDO = color;
    METALLIC = 0.0;
}

shader_type canvas_item;
render_mode blend_mix;

//## Parámetros de la Base del Agua
uniform vec3 water_tint = vec3(1.0, 1.0, 1.0);
uniform float caustics_speed : hint_range(0.1, 5.0) = 1.0;
uniform float caustics_strength : hint_range(0.0, 0.5) = 0.15;
uniform float caustics_scale : hint_range(1.0, 20.0) = 8.0;

//## DEFORMACIÓN FÍSICA (Ahora aplicada a la geometría)
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.01;
uniform float distortion_speed : hint_range(0.1, 3.0) = 1.0;

//## Parámetros viento (polvo)
uniform float wind_strength : hint_range(0.0, 2.0) = 0.4;
uniform float wind_speed : hint_range(0.1, 5.0) = 1.2;
uniform vec2 wind_direction  = vec2(1.0, 0.0);

//## Partículas
uniform float particle_density : hint_range(0.1, 10.0) = 3.0;
uniform float particle_size : hint_range(0.001, 0.01) = 0.004;
uniform float particle_opacity : hint_range(0.0, 1.0) = 0.2;

//## Ráfagas / Reflejos
uniform float gust_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float gust_scale : hint_range(0.5, 5.0) = 3.0;
uniform float gust_sharpness : hint_range(0.5, 10.0) = 6.0;

float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));
	vec2 u = f*f*(3.0-2.0*f);
	return mix(a, b, u.x) + (c-a)*u.y*(1.0-u.x) + (d-b)*u.x*u.y;
}

// Calcula cuánto se mueven los vértices físicamente
vec2 get_distortion(vec2 pos, float t) {
	vec2 d_pos = pos * 5.0 + t * distortion_speed;
	float nx = noise(d_pos);
	float ny = noise(d_pos + vec2(123.4, 321.1));
	return vec2(nx, ny) * distortion_strength * wind_strength;
}

void vertex() {
	// MAGIA AQUÍ: Movemos las 4 esquinas del Tile físicamente.
	// VERTEX contiene la posición local. Al multiplicarla por un número pequeño (0.002), 
	// logramos que el ruido sea amplio y cruce varios tiles de forma continua.
	vec2 dist = get_distortion(VERTEX * 0.002, TIME);
	
	// Multiplicamos por 500 para convertir ese decimal en desplazamiento de píxeles reales.
	// Como los tiles vecinos calculan la misma posición, se mueven exactamente igual y quedan pegados.
	VERTEX += dist * 500.0; 
}

float water_caustics(vec2 uv, float t) {
	vec2 wave_uv = uv * caustics_scale;
	float n1 = noise(wave_uv + vec2(t * 0.2, t * 0.1));
	float n2 = noise(wave_uv * 1.5 - vec2(t * 0.15, t * 0.25));
	float combined = mix(n1, n2, 0.5);
	return pow(combined * 1.5, 2.0);
}

float wind_particles(vec2 uv, float t) {
	vec2 moving_uv = uv + wind_direction * t * wind_speed;
	float particles = 0.0;
	for(int i=0;i<3;i++){
		float layer = float(i)+1.0;
		vec2 layer_uv = moving_uv * particle_density * layer;
		float n = noise(layer_uv);
		float th = 1.0 - particle_size*layer;
		particles += smoothstep(th, th+0.1, n) / layer;
	}
	return particles;
}

float wind_gusts(vec2 uv, float t) {
	float angle = atan(wind_direction.y, wind_direction.x);
	vec2 dir = vec2(cos(angle), sin(angle));
	vec2 moved = uv*gust_scale + dir*t*wind_speed;
	float n = noise(moved);
	return pow(sin(n*3.14159), gust_sharpness);
}

void fragment(){
	vec2 global_uv = SCREEN_UV;
	float t = TIME;

	// Ya no deformamos el dibujo por dentro, así que NUNCA leerá el borde invisible del atlas.
	vec4 base_color = texture(TEXTURE, UV);
	
	// Cáusticas (cambios de color internos)
	float caustic_waves = water_caustics(global_uv, t * caustics_speed);
	vec3 water_light_color = base_color.rgb * water_tint * 1.3;
	vec3 water_dark_color = base_color.rgb * water_tint * 0.8; 
	vec3 final_rgb = mix(water_dark_color, water_light_color, caustic_waves * caustics_strength);

	// Polvo y ráfagas superficiales
	float p = wind_particles(global_uv, t);
	vec3 dust_color = vec3(0.9, 0.9, 0.85);
	final_rgb = mix(final_rgb, dust_color, p * particle_opacity * wind_strength);

	float g = wind_gusts(global_uv, t);
	vec3 gust_color = vec3(0.85, 0.95, 1.0);
	final_rgb += gust_color * g * gust_opacity;

	// Salida transparente normal
	COLOR = vec4(final_rgb, base_color.a);
}
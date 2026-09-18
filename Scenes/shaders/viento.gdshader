shader_type canvas_item;
render_mode blend_mix;

//## Acceso a la textura de la pantalla
uniform sampler2D screen_texture : hint_screen_texture;

//## Parámetros viento
uniform float wind_strength : hint_range(0.0, 2.0) = 0.6;
uniform float wind_speed : hint_range(0.1, 5.0) = 1.5;
uniform vec2 wind_direction  = vec2(1.0, 0.0);

//## Partículas flotando
uniform float particle_density : hint_range(0.1, 10.0) = 2.0;
uniform float particle_size : hint_range(0.001, 0.01) = 0.003;
uniform float particle_opacity : hint_range(0.0, 1.0) = 0.15;

//## Distorsión muy leve (para no deformar sprites)
uniform float distortion_strength : hint_range(0.0, 0.05) = 0.01;
uniform float distortion_speed : hint_range(0.1, 3.0) = 1.0;

//## Parámetros de ráfagas
uniform float gust_opacity : hint_range(0.0, 1.0) = 0.35;
uniform float gust_scale : hint_range(0.5, 5.0) = 2.0;
uniform float gust_sharpness : hint_range(0.5, 10.0) = 4.0;

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

//## Partículas
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

//## Distorsión leve
vec2 wind_distortion(vec2 uv, float t) {
	vec2 d_uv = uv*5.0 + t*distortion_speed;
	float nx = noise(d_uv);
	float ny = noise(d_uv+vec2(123.4,321.1));
	return vec2(nx, ny) * distortion_strength * wind_strength;
}

//## Ráfagas visibles
float wind_gusts(vec2 uv, float t) {
	//# Se generan franjas curvas que cruzan la pantalla
	float angle = atan(wind_direction.y, wind_direction.x);
	vec2 dir = vec2(cos(angle), sin(angle));
	vec2 moved = uv*gust_scale + dir*t*wind_speed;

	float n = noise(moved);
	//# franjas definidas con curva suave
	float gust = pow(sin(n*3.14159), gust_sharpness);

	return gust;
}

void fragment(){
	vec2 uv = SCREEN_UV;
	float t = TIME;

	//# Color original con distorsión suave
	vec2 d_uv = uv + wind_distortion(uv, t);
	vec4 screen_color = texture(screen_texture, d_uv);

	//# Partículas
	float p = wind_particles(uv, t);
	vec3 dust_color = vec3(0.9,0.9,0.85);
	screen_color.rgb = mix(screen_color.rgb, dust_color, p * particle_opacity * wind_strength);

	//# Ráfagas visibles (overlay)
	float g = wind_gusts(uv, t);
	vec3 gust_color = vec3(0.8,0.9,1.0); //# azul-blanco leve
	screen_color.rgb = mix(screen_color.rgb, gust_color, g * gust_opacity);

	COLOR = screen_color;
}
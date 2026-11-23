shader_type spatial;
// Material del mundo: color plano + rejilla sutil en coordenadas de mundo (triplanar barato).
// La rejilla de 1 m ayuda a leer distancias, alturas y velocidad. Barato en móvil.

uniform vec4 albedo : source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float grid_size = 1.0;
uniform float line_strength = 0.13;
uniform float top_tint = 0.06;
uniform float roughness_value = 0.85;

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(wnorm);
	vec2 uv = n.y > 0.6 ? wpos.xz : (n.x > n.z ? wpos.zy : wpos.xy);
	vec2 g = uv / grid_size;
	vec2 fw = max(fwidth(g), vec2(0.0001));
	vec2 d = abs(fract(g - 0.5) - 0.5) / fw;
	float line = 1.0 - min(min(d.x, d.y), 1.0);
	vec3 c = albedo.rgb * (1.0 - line * line_strength);
	c += top_tint * step(0.6, wnorm.y);
	ALBEDO = c;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.25;
}

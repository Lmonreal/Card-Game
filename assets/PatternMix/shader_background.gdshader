shader_type canvas_item;

uniform bool pixelated = true;
uniform vec2 pattern_speed = vec2(0.0);
uniform vec2 pattern_size = vec2(1.0);

group_uniforms rotation;
uniform float rotation: hint_range(-3.14, 3.14,0.01) = 0.0;
uniform float rotation_speed: hint_range(-4.0, 4.0,0.01) = 0.0;
uniform vec2 rotation_center = vec2(0.0);

group_uniforms wave;
uniform vec2 wave_intensity = vec2(0,0);
uniform vec2 wave_speed = vec2(1,1);
uniform vec2 wave_size = vec2(5,5);
group_uniforms scanline;
uniform vec4 scanline_color:source_color = vec4(1.0,1.0,1.0,0.0);
uniform float scanline_size: hint_range(0.4, 5.0,0.01) = 1.0;
uniform float scanline_speed: hint_range(-1.0, 1.0,0.01) = 0.0;
group_uniforms gradient;
uniform float gradient_amount: hint_range(0.0, 1.0,0.01) = 0.0;
uniform sampler2D gradient;
uniform float gradient_speed: hint_range(-0.0, 1.0,0.01) = 0.0;

varying vec4 modulate;


vec2 rotate(vec2 uv, vec2 pivot, float angle)
{
	mat2 rotat = mat2(vec2(sin(angle), -cos(angle)),vec2(cos(angle), sin(angle)));
    uv -= pivot;
    uv = uv * rotat;
    uv += pivot;
    return uv;
}

void vertex() {
	modulate = COLOR;
}

void fragment(){
	vec2 uv = UV;
	
	// --- SCALE ---
	uv /= pattern_size;
	
	// --- PIXELATED ---
	if (pixelated){
		uv = round(uv/(TEXTURE_PIXEL_SIZE))*(TEXTURE_PIXEL_SIZE);
	}
	
	// --- ROTATION ---
	float rotation_value = rotation+(TIME*rotation_speed);
	if (abs(rotation_value) > 0.0){
		uv = rotate(uv,rotation_center/pattern_size,rotation_value);
	}
	
	// --- PATTERN SPEED ---
	uv += (pattern_speed*0.5)*TIME;
	
	
	// --- WAVE ---
	uv.x += sin((uv.y*wave_size.x)+(TIME*wave_speed.x))*wave_intensity.x;
	uv.y += sin((uv.x*wave_size.y)+(TIME*wave_speed.y))*wave_intensity.y;
	
	vec4 base_color = texture(TEXTURE, uv);
	
	// --- GRADIENT ---
	base_color *= modulate;
	vec4 color = base_color;
	float grey = (base_color.r + base_color.g + base_color.b) / 3.0;
	grey += sin(TIME*gradient_speed*5.0)*0.1;
	vec4 gradient_color = texture(gradient, vec2(grey, 0.5));
	color.rgb = mix(color.rgb,gradient_color.rgb,gradient_amount);
	color.a *= gradient_color.a;
	
	// --- SCAN LINE ---
	float scan_speed = scanline_speed*scanline_size*pattern_size.y;
	float pixel_y = round(((UV.y+(scan_speed*TIME))/(scanline_size*pattern_size.y)) / TEXTURE_PIXEL_SIZE.y);
	float line = mod(pixel_y, 2.0);
	color.rgb = mix(color.rgb,scanline_color.rgb,line*scanline_color.a);
	
	// --- APPLY ---
	COLOR = color;
}
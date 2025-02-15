shader_type canvas_item;
uniform sampler2D noise;
uniform vec4 main_color : source_color;
uniform vec4 accent_color : source_color;
uniform float alpha : hint_range(1.0, 15.0, 0.01) = 5.5;


void fragment() {
	vec2 new_uv = vec2(UV.x -TIME/10.0, UV.y);
	COLOR.a = texture(TEXTURE, new_uv).a;
	new_uv.x -= TIME;
	new_uv.x = mod(new_uv.x, 1.0);
	COLOR.rgb = mix(main_color.rgb, accent_color.rgb, new_uv.x);
	//COLOR.a = min(COLOR.a, alpha);
	//new_uv.x += TIME *0.01;
	//new_uv.x = mod(new_uv.x, 1.0);
	COLOR.a *= (new_uv.x*alpha) - 3.5;
}


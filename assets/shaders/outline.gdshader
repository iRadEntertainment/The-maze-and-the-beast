shader_type canvas_item;

uniform float width = 2.0;
uniform vec4 color: source_color;

varying flat vec4 modulate; void vertex() { modulate = COLOR; }

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec2 ps = TEXTURE_PIXEL_SIZE;
	float a;
	float maxa = col.a;
	float mina = col.a;

	a = texture(TEXTURE, UV + vec2(0.0, -width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(TEXTURE, UV + vec2(0.0, width) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(TEXTURE, UV + vec2(-width, 0.0) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);

	a = texture(TEXTURE, UV + vec2(width, 0.0) * ps).a;
	maxa = max(a, maxa);
	mina = min(a, mina);
	
	if (col.a < 0.2){
		COLOR = mix(col, color, maxa - mina);
	}
	//COLOR = mix(col, color, maxa - mina);
	COLOR = vec4(mix(col, color, maxa - mina).rgb, COLOR.a);
}
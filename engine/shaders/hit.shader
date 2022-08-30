shader_type canvas_item;
render_mode unshaded;

uniform vec4 color : hint_color;

void fragment()
{
	vec4 pixel = texture(TEXTURE, UV);
	if(pixel.a > 0.0) {
		COLOR = color;
	} else {
		COLOR.a = 0.0;
	}
}
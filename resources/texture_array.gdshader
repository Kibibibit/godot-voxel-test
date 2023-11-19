shader_type spatial;
uniform sampler2DArray texture_array : filter_nearest, repeat_enable;
uniform int material_count;
varying float texture_index;


void vertex() {
	texture_index = CUSTOM0.x * float(material_count);
}

void fragment() {
	ALBEDO.rgb = texture(texture_array, vec3(UV, texture_index)).rgb;
}
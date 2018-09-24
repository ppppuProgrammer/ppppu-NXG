shader_type canvas_item;

//Shader used to fill solid colors of a texture. Unlike the gradient shaders,
//this shader can change multiple color sections within 1 texture.

//The reference texture that's used to know what section the color used 
//in the texture belongs to.
uniform sampler2D sectionReferenceTex;

//Below are (gradient) textures that determine how a particular color section
//should look. Expects a gradient texture and always uses UV(0,0.5) for reading the color.
uniform sampler2D section1;
uniform sampler2D section2;
uniform sampler2D section3;
uniform sampler2D section4;
uniform sampler2D section5;
uniform sampler2D section6;
uniform sampler2D section7;
uniform sampler2D section8;

vec4 get_color_from_section(in int sectionNum){
	if(sectionNum == 1){
		return texture(section1, vec2(0.0,0.5));
	} else if(sectionNum == 2){
		return texture(section2, vec2(0.0,0.5));
	} else if(sectionNum == 3){
		return texture(section3, vec2(0.0,0.5));
	} else if(sectionNum == 4){
		return texture(section4, vec2(0.0,0.5));
	} else if(sectionNum == 5){
		return texture(section5, vec2(0.0,0.5));
	} else if(sectionNum == 6){
		return texture(section6, vec2(0.0,0.5));
	} else if(sectionNum == 7){
		return texture(section7, vec2(0.0,0.5));
	} else if(sectionNum == 8){
		return texture(section8, vec2(0.0,0.5));
	} else {
		return vec4(-1.0,-1.0,-1.0,-1.0);
	}
}

void fragment(){
	vec4 texColor = texture(TEXTURE, UV);
	COLOR = texColor;
	for(int i = 1; i <= 8; i++){
		vec4 refColor = texture(sectionReferenceTex, vec2((float(i)-0.5) / 8.0, 0.5));
		vec4 sectColor = get_color_from_section(i);
		if(refColor.rgb == texColor.rgb){
			COLOR.rgb = sectColor.rgb;
			//Preserve the alpha of the original texture (at least if sectColor.a is 1.0)
			COLOR.a *= sectColor.a;
			break;
		}
	}
}

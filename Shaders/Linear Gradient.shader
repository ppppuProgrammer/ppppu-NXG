shader_type canvas_item;

//Shader used
uniform sampler2D sectionReferenceTex;
uniform vec2 s1_start_UV;
uniform vec2 s1_end_UV;
uniform sampler2D section1;

uniform vec2 s2_start_UV;
uniform vec2 s2_end_UV;
uniform sampler2D section2;

uniform vec2 s3_start_UV;
uniform vec2 s3_end_UV;
uniform sampler2D section3;

uniform vec2 s4_start_UV;
uniform vec2 s4_end_UV;
uniform sampler2D section4;

uniform vec2 s5_start_UV;
uniform vec2 s5_end_UV;
uniform sampler2D section5;

uniform vec2 s6_start_UV;
uniform vec2 s6_end_UV;
uniform sampler2D section6;

uniform vec2 s7_start_UV;
uniform vec2 s7_end_UV;
uniform sampler2D section7;

uniform vec2 s8_start_UV;
uniform vec2 s8_end_UV;
uniform sampler2D section8;

vec4 get_color_from_section(in int sectionNum, in vec2 sectUV){
	if(sectionNum == 1){
		return texture(section1, sectUV);
	} else if(sectionNum == 2){
		return texture(section2, sectUV);
	} else if(sectionNum == 3){
		return texture(section3, sectUV);
	} else if(sectionNum == 4){
		return texture(section4, sectUV);
	} else if(sectionNum == 5){
		return texture(section5, sectUV);
	} else if(sectionNum == 6){
		return texture(section6, sectUV);
	} else if(sectionNum == 7){
		return texture(section7, sectUV);
	} else if(sectionNum == 8){
		return texture(section8, sectUV);
	} else {
		return vec4(-1.0,-1.0,-1.0,-1.0);
	}
}

vec2 get_gradient_start(in int sectionNum){
	if(sectionNum == 1){
		return s1_start_UV;
	} else if(sectionNum == 2){
		return s2_start_UV;
	} else if(sectionNum == 3){
		return s3_start_UV;
	} else if(sectionNum == 4){
		return s4_start_UV;
	} else if(sectionNum == 5){
		return s5_start_UV;
	} else if(sectionNum == 6){
		return s6_start_UV;
	} else if(sectionNum == 7){
		return s7_start_UV;
	} else if(sectionNum == 8){
		return s8_start_UV;
	} else {
		return vec2(-1.0,-1.0);
	}
}

vec2 get_gradient_end(in int sectionNum){
	if(sectionNum == 1){
		return s1_end_UV;
	} else if(sectionNum == 2){
		return s2_end_UV;
	} else if(sectionNum == 3){
		return s3_end_UV;
	} else if(sectionNum == 4){
		return s4_end_UV;
	} else if(sectionNum == 5){
		return s5_end_UV;
	} else if(sectionNum == 6){
		return s6_end_UV;
	} else if(sectionNum == 7){
		return s7_end_UV;
	} else if(sectionNum == 8){
		return s8_end_UV;
	} else {
		return vec2(-1.0,-1.0);
	}
}

float find_intersection_point(in vec2 startUV, in vec2 endUV, in vec2 pixelUV, in vec2 texSize){
	//Get the slope intercept form for the gradient line
	//Done like this in case a conversion from normalized to pixel position is desired.
	vec2 startPoint = startUV * texSize;
	vec2 endPoint = endUV * texSize;
	vec2 pixelPos = pixelUV * texSize;
	if (abs(startPoint.x - endPoint.x) < 0.0001){
		//Handle vertical line
		float distance_to_pixel = abs(pixelPos.x - startPoint.x);
		float distance_for_gradient = abs(startPoint.x - endPoint.x);
		return distance_to_pixel / distance_for_gradient;
	} else {
		float grad_slope = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
		float grad_y_int = startPoint.y - (grad_slope * startPoint.x);
		//Get the line perpendicular to the gradient line in slope intercept form.
		//The perpendicular line's slope is -1/slope of the gradient line
		float perpend_slope = -1.0 / grad_slope;
		//plug in the pixel's position to y - mx = c to get the y intercept.
		float perpend_y_int = pixelPos.y - (perpend_slope * pixelPos.x);
		//Do substitution to get the intersection point.
		//sx + c = mx + b (s and c being the 'm' and 'b' variable-equilvant
		//for the other line) and that's boiled down to c - b = mx - sx
		//grad will be y = mx + b, perpend will be y = sx + c
		float intercept_x = (perpend_y_int - grad_y_int) / (grad_slope - perpend_slope);
		float intercept_y = (grad_slope * intercept_x) + grad_y_int;
		//Run distance() on the intersection point and the gradient start, another on
		//gradient start and gradient end then  divide to get the offset.
		float distance_to_intercept = distance(startPoint, vec2(intercept_x, intercept_y));
		float gradient_distance = distance(startPoint, endPoint);
		return (distance_to_intercept / gradient_distance);
	}
}

void fragment(){
	vec4 texColor = texture(TEXTURE, UV);
	if(texColor.a == 0.0){discard;}
	int section = 0;
	for(int i = 1; i <= 8; i++){
		vec4 refColor = texture(sectionReferenceTex, vec2((float(i)-0.5) / 8.0, 0.5));
		if(refColor.rgb == texColor.rgb){
			section = i;
			break;
		}
	}
	if(section > 0){
		//vec2 pixelPos = UV * (1.0 / TEXTURE_PIXEL_SIZE);
		float gradValue = find_intersection_point(get_gradient_start(section), get_gradient_end(section), UV, 1.0 / TEXTURE_PIXEL_SIZE);
		if(gradValue == -1.0){discard;}
		gradValue = clamp(gradValue, 0.0, 1.0);
		//Do a distance calculation between the gradient origin and the current UV
		vec2 lookupUV = vec2(gradValue, 0.5);
		vec4 gradientColor = get_color_from_section(section, lookupUV);
		//COLOR = vec4(0.0,0.0,0.0,1.0);
		//COLOR.r = gradValue;
		COLOR = gradientColor;
		COLOR.a *= texColor.a;
	}else{COLOR = texColor;}
}
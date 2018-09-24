shader_type canvas_item;

uniform sampler2D sectionReferenceTex;

//Section 1
uniform vec2 s1_centerUV;
//Normalized value (0.0 to 1.0)
uniform float s1_radius;
uniform bool s1_use_focal_point;
uniform vec2 s1_focal_pointUV;
uniform sampler2D section1;

//Section 2
uniform vec2 s2_centerUV;
uniform float s2_radius;
uniform bool s2_use_focal_point;
uniform vec2 s2_focal_pointUV;
uniform sampler2D section2;

//Section 3
uniform vec2 s3_centerUV;
uniform float s3_radius;
uniform bool s3_use_focal_point;
uniform vec2 s3_focal_pointUV;
uniform sampler2D section3;

//Section 4
uniform vec2 s4_centerUV;
uniform float s4_radius;
uniform bool s4_use_focal_point;
uniform vec2 s4_focal_pointUV;
uniform sampler2D section4;

//Section 5
uniform vec2 s5_centerUV;
uniform float s5_radius;
uniform bool s5_use_focal_point;
uniform vec2 s5_focal_pointUV;
uniform sampler2D section5;

//Section 6
uniform vec2 s6_centerUV;
uniform float s6_radius;
uniform bool s6_use_focal_point;
uniform vec2 s6_focal_pointUV;
uniform sampler2D section6;

//Section 7
uniform vec2 s7_centerUV;
uniform float s7_radius;
uniform bool s7_use_focal_point;
uniform vec2 s7_focal_pointUV;
uniform sampler2D section7;

//Section 8
uniform vec2 s8_centerUV;
uniform float s8_radius;
uniform bool s8_use_focal_point;
uniform vec2 s8_focal_pointUV;
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

bool get_use_focus_point(in int sectionNum){
	if(sectionNum == 1){
		return s1_use_focal_point;
	} else if(sectionNum == 2){
		return s2_use_focal_point;
	} else if(sectionNum == 3){
		return s3_use_focal_point;
	} else if(sectionNum == 4){
		return s4_use_focal_point;
	} else if(sectionNum == 5){
		return s5_use_focal_point;
	} else if(sectionNum == 6){
		return s6_use_focal_point;
	} else if(sectionNum == 7){
		return s7_use_focal_point;
	} else if(sectionNum == 8){
		return s8_use_focal_point;
	}
}

vec2 get_focus_pointUV(in int sectionNum){
	if(sectionNum == 1){
		return s1_focal_pointUV;
	} else if(sectionNum == 2){
		return s2_focal_pointUV;
	} else if(sectionNum == 3){
		return s3_focal_pointUV;
	} else if(sectionNum == 4){
		return s4_focal_pointUV;
	} else if(sectionNum == 5){
		return s5_focal_pointUV;
	} else if(sectionNum == 6){
		return s6_focal_pointUV;
	} else if(sectionNum == 7){
		return s7_focal_pointUV;
	} else if(sectionNum == 8){
		return s8_focal_pointUV;
	}
}

vec2 get_circle_center_UV(in int sectionNum){
	if(sectionNum == 1){
		return s1_centerUV;
	} else if(sectionNum == 2){
		return s2_centerUV;
	} else if(sectionNum == 3){
		return s3_centerUV;
	} else if(sectionNum == 4){
		return s4_centerUV;
	} else if(sectionNum == 5){
		return s5_centerUV;
	} else if(sectionNum == 6){
		return s6_centerUV;
	} else if(sectionNum == 7){
		return s7_centerUV;
	} else if(sectionNum == 8){
		return s8_centerUV;
	}
}

float get_circle_radius(in int sectionNum){
	if(sectionNum == 1){
		return s1_radius;
	} else if(sectionNum == 2){
		return s2_radius;
	} else if(sectionNum == 3){
		return s3_radius;
	} else if(sectionNum == 4){
		return s4_radius;
	} else if(sectionNum == 5){
		return s5_radius;
	} else if(sectionNum == 6){
		return s6_radius;
	} else if(sectionNum == 7){
		return s7_radius;
	} else if(sectionNum == 8){
		return s8_radius;
	}
}

vec2 solve_quadratic_equation(in float a, in float b, in float c){
	//-b +- sqrt(b^2 - 4ac) / 2a
	float sq = sqrt(pow(b, 2) - (4.0 * a * c));
	float div = 2.0 * a;
	float res1 = (-b + sq) / div;
	float res2 = (-b - sq) / div;
	return vec2(res1, res2);
} 

float get_distance_from_circle(in vec2 circleCenterUV, in float radius, in vec2 gradientCenterUV, in vec2 texSize, in vec2 pixelUV){
	vec2 circlePos = circleCenterUV * texSize;
	vec2 pixelPos = pixelUV * texSize;
	vec2 focusPos = gradientCenterUV * texSize;
	
	//Test if current pixel is outside circle
	float radiusSize = radius * min(texSize.x, texSize.y);
	if(pow(pixelPos.x - circlePos.x, 2.0) + pow(pixelPos.y - circlePos.y, 2.0) > pow(radiusSize, 2.0)){
		return -1.0;
	}
	
	//Need to test if the focus is outside the circle
	float focusDistance = distance(focusPos, circlePos);
	//float focusDistance = sqrt(pow(focusPos.x - circlePos.x, 2.0) + pow(focusPos.y - circlePos.y, 2.0)) - radius;
	if (focusDistance > radiusSize){
		focusPos = circlePos + (normalize(focusPos - circlePos) * radiusSize);
	}
	//Find out distance needed for the line from the focus point to the current pixel 
	//will intersect the gradient circle.
	//y = m x + c
	//(x - px)^2 + (y - py)^2 = r^2
	vec2 endPoint = 1.0 * texSize;
	if(abs(gradientCenterUV.x - pixelUV.x) < 0.0001){
		//return 1.0;
		endPoint.x = pixelPos.x;
		//Line is a constant (x = c), so just plug in for x
		//(pixelPos.x - circlePos.x)^2 + (y - circlePos.y)^2 = radius^2
		float p1 = pow((pixelPos.x - circlePos.x), 2);
		float b = circlePos.y + circlePos.y;
		float c = pow(circlePos.y, 2);
		c += p1 - pow(radiusSize, 2); 
		//Get the y values for points where the gradient intersection happens
		vec2 results = solve_quadratic_equation(1.0, b, c);
		if( pixelPos.y <= focusPos.y){
			//Use the lower of the 2 results
			endPoint.y = max(results.x, results.y);
		} else {
			//Use the higher of the 2 results
			endPoint.y = min(results.x, results.y);
		}
	}
	else{
		//return (focusPos.x - pixelPos.x);
		//y = m x + c
		//return 1.0;
		float m = (focusPos.y - pixelPos.y) / (focusPos.x - pixelPos.x);
		//y - mx = c
		float lc = focusPos.y - (m * focusPos.x);
		float h = circlePos.x;
		float k = circlePos.y;
		//h = circlePos.x, k = circlePos.y
		//(x - h)^2 + (y - k)^2 = r^2
		//After sub: (x-h)^2 + (mx+c - k)^2 = r^2
		//Expanded: (m^2+1)x^2 + 2(mc-mk-h)x + (k^2 - r^2 + h^2 - 2ck + c^2) = 0
		float a = pow(m,2.0) + 1.0;
		float b = 2.0 * ((m*lc)-(m*k) - h);
		float c = pow(k, 2.0) - pow(radiusSize, 2.0) + pow(h, 2.0) - (2.0*lc*k) + pow(lc, 2.0);
		vec2 results = solve_quadratic_equation(a, b, c);
		vec2 intersect1 = vec2(results.x, m*results.x + lc);
		vec2 intersect2 = vec2(results.y, m*results.y + lc);
		
		if(pixelPos.x <= focusPos.x){
			if(intersect1.x <= pixelPos.x){
				endPoint = intersect1;
			} else {
				endPoint = intersect2;
			}
		} else {
			if(intersect1.x > pixelPos.x){
				endPoint = intersect1;
			} else {
				endPoint = intersect2;
			}
		}
//		if(normalize(focusPos - intersect1) == normalize(focusPos - pixelPos)){
//			endPoint = intersect1;
//		} else if(normalize(focusPos - intersect2) == normalize(focusPos - pixelPos)) {
//			endPoint = intersect2;
//		}
//		else{
//			endPoint = intersect2;
//		}
	}
	float totalDistance = distance(endPoint, focusPos);
	float distanceFromFocus = distance(pixelPos, focusPos);
	return distanceFromFocus / totalDistance;
	//pointDistance = sqrt(pow(pixelPos.x - circlePos.x, 2.0) + pow(pixelPos.y - circlePos.y, 2.0)) - radius;
	
	//Need to use pixel screen position to accurately get distance of pixel from circle
}

void fragment() {
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
		vec2 gradientOrigin;
		bool use_focal_point = get_use_focus_point(section);
		vec2 centerUV = get_circle_center_UV(section);
		float radius = get_circle_radius(section);
		if (!use_focal_point){
			gradientOrigin = centerUV;
		} else {
			gradientOrigin = get_focus_pointUV(section);
		}
		//Use 0 to 1 to represent the distance from the circle
		float gradValue = get_distance_from_circle(centerUV, radius, gradientOrigin, 1.0 /  TEXTURE_PIXEL_SIZE, UV);
		if(gradValue == -1.0){discard;}
		gradValue = clamp(gradValue, 0.0, 1.0);
		//Do a distance calculation between the gradient origin and the current UV
		vec2 lookupUV = vec2(gradValue, 0.5);
		vec4 gradientColor = get_color_from_section(section, lookupUV);
		COLOR = gradientColor;
		COLOR.a *= texColor.a;
	}else{COLOR = texColor;}
}

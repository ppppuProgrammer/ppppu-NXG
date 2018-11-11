shader_type canvas_item;

//Shader for applying replacing a given color of the current
//texture with another color using one of 3 different coloring
//methods; solid, linear, and radial

uniform bool debug;

//Tex uses as a reference for what section the texture's pixel belongs to.
uniform sampler2D sectionReferenceTex;

//Can't use until Godot's issues with large textures are fixed. Key one being
//that they can't be read by samplers
//uniform sampler2D color_group_texture;

//0 is solid, 1 is linear, 2 is radial
uniform int color_method;


//Section 1
//Linear: Used for start point; Radial: Used for center point
uniform vec2 s1_UV1;
//Linear: Used for end point; Radial: Used for focal point
uniform vec2 s1_UV2;
uniform float s1_radius;
uniform bool s1_use_focus_point;
uniform sampler2D section1;
uniform mat3 s1_gradient_transform;

//Section 2
uniform vec2 s2_UV1;
uniform vec2 s2_UV2;
uniform float s2_radius;
uniform bool s2_use_focus_point;
uniform sampler2D section2;
uniform mat3 s2_gradient_transform;

//Section 3
uniform vec2 s3_UV1;
uniform vec2 s3_UV2;
uniform float s3_radius;
uniform bool s3_use_focus_point;
uniform sampler2D section3;
uniform mat3 s3_gradient_transform;

//Section 4
uniform vec2 s4_UV1;
uniform vec2 s4_UV2;
uniform float s4_radius;
uniform bool s4_use_focus_point;
uniform sampler2D section4;
uniform mat3 s4_gradient_transform;

//Section 5
uniform vec2 s5_UV1;
uniform vec2 s5_UV2;
uniform float s5_radius;
uniform bool s5_use_focus_point;
uniform sampler2D section5;
uniform mat3 s5_gradient_transform;

//Section 6
uniform vec2 s6_UV1;
uniform vec2 s6_UV2;
uniform float s6_radius;
uniform bool s6_use_focus_point;
uniform sampler2D section6;
uniform mat3 s6_gradient_transform;

//Section 7
uniform vec2 s7_UV1;
uniform vec2 s7_UV2;
uniform float s7_radius;
uniform bool s7_use_focus_point;
uniform sampler2D section7;
uniform mat3 s7_gradient_transform;

//Section 8
uniform vec2 s8_UV1;
uniform vec2 s8_UV2;
uniform float s8_radius;
uniform bool s8_use_focus_point;
uniform sampler2D section8;
uniform mat3 s8_gradient_transform;

vec2 get_transformed_point(in vec2 vec, in mat3 mat){
	vec3 point = vec3(vec, 1.0);
	//float dotx = dot(point, mat[0]);
	//float doty = dot(point, mat[1]);
	//float dotx = (mat[0][0] * vec.x + mat[1][0] * vec.y) + mat[0][2];
	//float doty = (mat[0][1] * vec.x + mat[1][1] * vec.y) + mat[1][2];
	//return vec2(dotx, doty);
	return vec2(dot(point, mat[0]), dot(point, mat[1]));
}
/////////////////// Algebraic functions ///////////////////
vec2 solve_quadratic_equation(in float a, in float b, in float c){
	//-b +- sqrt(b^2 - 4ac) / 2a
	float sq = sqrt(pow(b, 2) - (4.0 * a * c));
	float div = 2.0 * a;
	float res1 = (-b + sq) / div;
	float res2 = (-b - sq) / div;
	return vec2(res1, res2);
} 

float get_distance_from_circle(in vec2 circlePos, in float radiusSize, in vec2 focusPos, in vec2 pixelPos, in mat3 gradientTransform){
	//vec2 circlePos = circleCenterUV * texSize;
	//vec2 pixelPos = pixelUV * texSize;
	//vec2 focusPos = gradientCenterUV * texSize;
	//mat3 transposedMat = transpose(gradientTransform);
	//Test if current pixel is outside circle
	//float radiusSize = radius * min(texSize.x, texSize.y);
	//if(pow(pixelPos.x - circlePos.x, 2.0) + pow(pixelPos.y - circlePos.y, 2.0) > pow(radiusSize, 2.0)){
	//	return -1.0;
	//}
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
	vec2 endPoint = vec2(1.0);
	if(abs(focusPos.x - pixelPos.x) < 0.0001){
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
	//gradientTransform = transpose(gradientTransform);
	float totalDistance = distance(endPoint, focusPos);
	float distanceFromFocus = distance(pixelPos, focusPos);
	return distanceFromFocus / totalDistance;
	//TODO: Fix gradient transform usage
	//vec2 finalEndPoint = get_transformed_point(endPoint, gradientTransform);
	//vec2 finalFocusPoint = focusPos;//get_transformed_point(focusPos, gradientTransform);
	//float totalDistance = distance(finalEndPoint, finalFocusPoint);
	//float distanceFromFocus = distance(pixelPos, finalFocusPoint);
	//return distanceFromFocus / totalDistance;
}

float find_intersection_point(in vec2 startPoint, in vec2 endPoint, in vec2 pixelPos, in mat3 gradientTransform){
	//Get the slope intercept form for the gradient line
	//Done like this in case a conversion from normalized to pixel position is desired.
	//vec2 startPoint = startUV;
	//vec2 endPoint = endUV;
	//vec2 pixelPos = pixelUV * texSize;
	mat3 transposedTransform = transpose(gradientTransform);
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
/////////////////// End Algebraic functions ///////////////////

//////////////////// Radial Functions ////////////////////
float get_radius(in int sectionNum){
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

bool get_use_focus(in int sectionNum){
	if(sectionNum == 1){
		return s1_use_focus_point;
	} else if(sectionNum == 2){
		return s2_use_focus_point;
	} else if(sectionNum == 3){
		return s3_use_focus_point;
	} else if(sectionNum == 4){
		return s4_use_focus_point;
	} else if(sectionNum == 5){
		return s5_use_focus_point;
	} else if(sectionNum == 6){
		return s6_use_focus_point;
	} else if(sectionNum == 7){
		return s7_use_focus_point;
	} else if(sectionNum == 8){
		return s8_use_focus_point;
	}
}

mat3 get_gradient_transform(in int sectionNum){
	if(sectionNum == 1){
		return s1_gradient_transform;
	} else if(sectionNum == 2){
		return s2_gradient_transform;
	} else if(sectionNum == 3){
		return s3_gradient_transform;
	} else if(sectionNum == 4){
		return s4_gradient_transform;
	} else if(sectionNum == 5){
		return s5_gradient_transform;
	} else if(sectionNum == 6){
		return s6_gradient_transform;
	} else if(sectionNum == 7){
		return s7_gradient_transform;
	} else if(sectionNum == 8){
		return s8_gradient_transform;
	}
}
//////////////////// End Radial ////////////////////

vec2 solid_color()
{
    return vec2(0.0, 0.5);
}

vec2 linear_gradient(in vec2 start,in vec2 end, in vec2 pixel, in mat3 gradientTransform)
{
    	float gradValue = find_intersection_point(start, end, pixel, gradientTransform);
		if(gradValue == -1.0){return vec2(-1.0);}
		gradValue = clamp(gradValue, 0.0, 1.0);
		//Do a distance calculation between the gradient origin and the current UV
		return vec2(gradValue, 0.5);
		//vec4 gradientColor = get_color_from_section(section, lookupUV);
}

vec2 radial_gradient(in vec2 pixel, in vec2 center, in vec2 focus, in float radius, in bool useFocus, in mat3 gradientTransform)
{
    vec2 gradientOrigin;
	if (!useFocus){
		gradientOrigin = center;
	} else {
		gradientOrigin = focus;
	}
	//Use 0 to 1 to represent the distance from the circle
	float gradValue = get_distance_from_circle(center, radius, gradientOrigin, pixel, gradientTransform);
	if(gradValue == -1.0){return vec2(-1.0, -1.0);}
	gradValue = clamp(gradValue, 0.0, 1.0);
	//Do a distance calculation between the gradient origin and the current UV
	return vec2(gradValue, 0.5);
}

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

vec2 get_UV1(in int sectionNum){
	if(sectionNum == 1){
		return s1_UV1;
	} else if(sectionNum == 2){
		return s2_UV1;
	} else if(sectionNum == 3){
		return s3_UV1;
	} else if(sectionNum == 4){
		return s4_UV1;
	} else if(sectionNum == 5){
		return s5_UV1;
	} else if(sectionNum == 6){
		return s6_UV1;
	} else if(sectionNum == 7){
		return s7_UV1;
	} else if(sectionNum == 8){
		return s8_UV1;
	}
}

vec2 get_UV2(in int sectionNum){
	if(sectionNum == 1){
		return s1_UV2;
	} else if(sectionNum == 2){
		return s2_UV2;
	} else if(sectionNum == 3){
		return s3_UV2;
	} else if(sectionNum == 4){
		return s4_UV2;
	} else if(sectionNum == 5){
		return s5_UV2;
	} else if(sectionNum == 6){
		return s6_UV2;
	} else if(sectionNum == 7){
		return s7_UV2;
	} else if(sectionNum == 8){
		return s8_UV2;
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
        vec2 sectionTexUV;
		if (color_method == 0){
			sectionTexUV = solid_color();
		} else if (color_method == 1) {
		    sectionTexUV = linear_gradient(UV * (1.0 / TEXTURE_PIXEL_SIZE), get_UV1(section), get_UV2(section), get_gradient_transform(section));
		} else if (color_method == 2){
		    sectionTexUV = radial_gradient(UV * (1.0 / TEXTURE_PIXEL_SIZE), get_UV1(section), get_UV2(section), get_radius(section), get_use_focus(section), get_gradient_transform(section));
		}
		//vec4 replacementColor = vec4(1.0);
		//replacementColor.rg = vec2(0.5);
		vec4 replacementColor = get_color_from_section(section, sectionTexUV);
		COLOR = replacementColor; 
		COLOR.a = texColor.a * replacementColor.a;
		if(debug){
			if(color_method == 2){
				if(sectionTexUV.x < 0.25){
					COLOR = vec4(0.48, 0.7255, 0.9, 1.0);
				}else if(sectionTexUV.x < 0.5){
					COLOR = vec4(0.180392157, 0.345, 0.58, 1.0);
				}else if(sectionTexUV.x < 0.75){
					COLOR = vec4(0.0, 1.0, 1.0, 1.0);
				}else if(sectionTexUV.x < 1.0){
					COLOR = vec4(.0314, .1451, .4039, 1.0);
				}
			}
			
			if(distance(UV * (1.0/TEXTURE_PIXEL_SIZE), get_UV1(section)) < 5.0){
				COLOR = vec4(0, 1.0, 0, 1.0);
			}
			
		}
	} else {COLOR = texColor;}
}
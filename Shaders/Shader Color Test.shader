shader_type canvas_item;

uniform vec2 centerUV;
uniform float radius;
uniform bool use_focal_point;
uniform vec2 focal_pointUV;
uniform sampler2D gradientLookup;
uniform bool debug;

vec2 solve_quadratic_equation(in float a, in float b, in float c){
	//-b +- sqrt(b^2 - 4ac) / 2a
	float sq = sqrt(pow(b, 2) - (4.0 * a * c));
	float div = 2.0 * a;
	float res1 = (-b + sq) / div;
	float res2 = (-b - sq) / div;
	return vec2(res1, res2);
} 

float get_distance_from_circle(in vec2 circleCenterUV, in vec2 gradientCenterUV, in vec2 texSize, in vec2 pixelUV){
	vec2 circlePos = circleCenterUV * texSize;
	vec2 pixelPos = pixelUV * texSize;
	vec2 focusPos = gradientCenterUV * texSize;
	
	//Test if current pixel is outside circle
	if(pow(pixelPos.x - circlePos.x, 2.0) + pow(pixelPos.y - circlePos.y, 2.0) > pow(radius, 2.0)){
		return -1.0;
	}
	
	//Need to test if the focus is outside the circle
	float focusDistance = distance(focusPos, circlePos);
	//float focusDistance = sqrt(pow(focusPos.x - circlePos.x, 2.0) + pow(focusPos.y - circlePos.y, 2.0)) - radius;
	if (focusDistance > radius){
		focusPos = circlePos + (normalize(focusPos - circlePos) * radius);
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
		c += p1 - pow(radius, 2); 
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
		float c = pow(k, 2.0) - pow(radius, 2.0) + pow(h, 2.0) - (2.0*lc*k) + pow(lc, 2.0);
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
	//return 0.0;
	return distanceFromFocus / totalDistance;
	//pointDistance = sqrt(pow(pixelPos.x - circlePos.x, 2.0) + pow(pixelPos.y - circlePos.y, 2.0)) - radius;
	
	//Need to use pixel screen position to accurately get distance of pixel from circle
}

void fragment() {
	vec2 gradientOrigin;
	if (!use_focal_point){
		gradientOrigin = centerUV;
	} else {
		gradientOrigin = focal_pointUV;
	}
	//Get the color from the texture
	vec4 color = texture(TEXTURE, UV);
	//if(color.a == 0.0){ discard;}
//	if (pixelDistFromCircle < 0.0){
//		discard;
//	}
	//Use 0 to 1 to represent the distance from the circle
	float gradValue = get_distance_from_circle(centerUV, gradientOrigin, 1.0 /  TEXTURE_PIXEL_SIZE, UV);
	if(gradValue == -1.0){discard;}
	gradValue = clamp(gradValue, 0.0, 1.0);
	//Do a distance calculation between the gradient origin and the current UV
	vec2 lookupUV = vec2(gradValue, 0.0);
	vec4 gradientColor = texture(gradientLookup, lookupUV);
	//vec2 endPoint = get_distance_from_circle(centerUV, gradientOrigin, 1.0 /  TEXTURE_PIXEL_SIZE, UV);
	//COLOR = vec4(1.0, 1.0, 0.0, gradValue);
	COLOR = gradientColor;
}

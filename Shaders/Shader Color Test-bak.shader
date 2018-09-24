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

vec2 get_distance_from_circle(in vec2 circleCenterUV, in vec2 gradientCenterUV, in vec2 texSize, in vec2 pixelUV){
	vec2 circlePos = circleCenterUV * texSize;
	vec2 pixelPos = pixelUV * texSize;
	vec2 focusPos = gradientCenterUV * texSize;
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
	vec2 endPoint;
	//y = m x + c
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
	float c = pow(k, 2.0) - pow(radius, 2.0) + (pow(h, 2.0) - (2.0*lc*k) + pow(lc, 2.0));
	vec2 results = solve_quadratic_equation(a, b, c);
	vec2 intersect1 = vec2(results.x, m*results.x + lc);
	vec2 intersect2 = vec2(results.y, m*results.y + lc);
	//endPoint = intersect1;
	endPoint = intersect2;

	float totalDistance = distance(endPoint, focusPos);
	float distanceFromFocus = distance(pixelPos, focusPos);
	return endPoint;
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
	vec2 point = get_distance_from_circle(centerUV, gradientOrigin, 1.0 /  TEXTURE_PIXEL_SIZE, UV);
	if (color.a == 0.0){
		discard;
	}
	//Use 0 to 1 to represent the distance from the circle
	
	COLOR = vec4(point.x,point.y,0.0,1.0);
	//COLOR = gradientColor;
	//COLOR.rgb = gradientColor.rgb;//vec3(0.0,0.0,0.0);
	//COLOR.a =  color.a * gradientColor.a;
}
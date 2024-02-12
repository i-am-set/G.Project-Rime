shader_type spatial;

uniform float fov = 50;

void vertex() {
    float scale = 1.0 / tan(fov * 0.5 * PI / 180.0); 
    PROJECTION_MATRIX[0][0] = scale / (VIEWPORT_SIZE.x / VIEWPORT_SIZE.y);
    PROJECTION_MATRIX[1][1] = -scale;
}

void fragment() {
	// Place fragment code here.
}

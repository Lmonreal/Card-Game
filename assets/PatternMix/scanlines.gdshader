shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.15;
uniform int spacing : hint_range(1, 16) = 4;     // period: one band every N rows
uniform int thickness : hint_range(1, 16) = 1;   // dark rows per band
uniform float speed = 0.0;                       // rows per second, 0 = static

void fragment() {
    float y = FRAGCOORD.y + TIME * speed;
    int row = int(y) % spacing;
    float line = float(row < thickness);
    COLOR = vec4(0.0, 0.0, 0.0, line * strength);
}
// class vec3 #(parameter WIDTH = 32, parameter FBITS = 16); // width is total width, fbits is fraction bits
//     logic [WIDTH-1:0] x;
//     logic [WIDTH-1:0] y;
//     logic [WIDTH-1:0] z;

//     function new(logic [WIDTH-1:0] _x = 0, logic [WIDTH-1:0] _y = 0, logic [WIDTH-1:0] _z = 0);
//         x = _x;
//         y = _y;
//         z = _z;
//     endfunction

//     function vec3 #(WIDTH, FBITS) add(vec3 #(WIDTH, FBITS) v);
//         vec3 #(WIDTH, FBITS) v_add = new(x+v.x, y+v.y, z+v.z);
//         return v_add;
//     endfunction

//     function vec3 #(WIDTH, FBITS) dot(vec3 #(WIDTH, FBITS) v); // Note that x_y_z*x_y_z cannot > 2^(2*WIDTH) 
//         automatic logic [WIDTH*2-1:0] temp_x = (x*v.x) >> FBITS;
//         automatic logic [WIDTH*2-1:0] temp_y = (y*v.y) >> FBITS;
//         automatic logic [WIDTH*2-1:0] temp_z = (z*v.z) >> FBITS;
//         automatic vec3 #(WIDTH, FBITS) v_dot = new(temp_x, temp_y, temp_z);
//         return v_dot;
//     endfunction

//     function vec3 #(WIDTH, FBITS) _cross(vec3 #(WIDTH, FBITS) v); // cross is a keyword
//         automatic logic [WIDTH*2-1:0] temp_x = (y*v.z - z*v.y) >> FBITS;
//         automatic logic [WIDTH*2-1:0] temp_y = (z*v.x - x*v.z) >> FBITS;
//         automatic logic [WIDTH*2-1:0] temp_z = (x*v.y - y*v.x) >> FBITS;
//         vec3 #(WIDTH, FBITS) v_cross = new(temp_x, temp_y, temp_z);
//         return v_cross;
//     endfunction

//     function automatic logic [WIDTH*2-1:0] length_squared();
//         automatic logic [WIDTH*2-1:0] temp_x = x*x>>FBITS;
//         automatic logic [WIDTH*2-1:0] temp_y = y*y>>FBITS;
//         automatic logic [WIDTH*2-1:0] temp_z = z*z>>FBITS;
//         return temp_x + temp_y + temp_z;
//     endfunction

//     function vec3 #(WIDTH, FBITS) scale_mul(logic [WIDTH-1:0] t); // Note that t*x_y_z cannot > 2^(2*WIDTH) 
//         automatic logic [WIDTH*2-1:0] temp_x = (x*t)>>FBITS;
//         automatic logic [WIDTH*2-1:0] temp_y = (y*t)>>FBITS;
//         automatic logic [WIDTH*2-1:0] temp_z = (z*t)>>FBITS;
//         vec3 #(WIDTH, FBITS) v_scale_mul = new(temp_x, temp_y, temp_z);
//         return v_scale_mul;
//     endfunction

//     function vec3 #(WIDTH, FBITS) scale_div(logic [WIDTH-1:0] t); // Note that x/t cannot > 2^WIDTH 
//         automatic logic [WIDTH*2-1:0] temp_x = (x<<FBITS)/t;
//         automatic logic [WIDTH*2-1:0] temp_y = (y<<FBITS)/t;
//         automatic logic [WIDTH*2-1:0] temp_z = (z<<FBITS)/t;
//         vec3 #(WIDTH, FBITS) v_scale_div = new(temp_x, temp_y, temp_z);
//         return v_scale_div;
//     endfunction

//     // unit vector = v / v.length()
//     // random in unit sphere = while() {p = random(), if }
//     // inline vec3 unit_vector(vec3 v) {
//     //     return v / v.length();
//     // }

//     // vec3 random_in_unit_sphere() {
//     //     while (true) {
//     //         auto p = vec3::random(-1, 1);
//     //         if (p.length_squared() >= 1) continue;
//     //         return p;
//     //     }
//     // }

//     // vec3 random_unit_vector() {
//     //     return unit_vector(random_in_unit_sphere());
//     // }

    
// endclass

package vec3_package;
    parameter WIDTH = 32;
    parameter FBITS = 16;

    // VEC3
    typedef struct {
        logic [WIDTH-1:0] x;
        logic [WIDTH-1:0] y;
        logic [WIDTH-1:0] z;    
    } vec3;
    typedef vec3 color;
    typedef vec3 point;
    task set;
        input logic [WIDTH-1:0] _x, _y, _z;
        output vec3 v; 
        begin
            v.x = _x;
            v.y = _y;
            v.z = _z;
        end
    endtask
    task add;
        input vec3 v1, v2;
        output vec3 v3;
        begin
            set(v1.x+v2.x, v1.y+v2.y, v1.z+v2.z, v3);
        end
    endtask
    task minus;
        input vec3 v1, v2;
        output vec3 v3;
        begin
            set(v1.x-v2.x, v1.y-v2.y, v1.z-v2.z, v3);
        end
    endtask
    task dot;
        input vec3 v1, v2;
        output vec3 v3;
        begin
            automatic logic [WIDTH*2-1:0] temp_x = (v1.x*v2.x)>>FBITS;
            automatic logic [WIDTH*2-1:0] temp_y = (v1.y*v2.y)>>FBITS;
            automatic logic [WIDTH*2-1:0] temp_z = (v1.z*v2.z)>>FBITS;
            set(temp_x, temp_y, temp_z, v3);
        end
    endtask
    task scale;
        input vec3 v_in;
        input logic [WIDTH-1:0] t;
        output vec3 v_out;
        begin
            automatic logic [WIDTH*2-1:0] temp_x = (v_in.x*t)>>FBITS;
            automatic logic [WIDTH*2-1:0] temp_y = (v_in.y*t)>>FBITS;
            automatic logic [WIDTH*2-1:0] temp_z = (v_in.z*t)>>FBITS;
            set(temp_x, temp_y, temp_z, v_out);
        end
    endtask
    task length_squared;
        input vec3 v;
        output logic [WIDTH-1:0] length_squared;
        begin
            automatic logic [WIDTH*2-1:0] temp_x = (v.x*v.x)>>FBITS;
            automatic logic [WIDTH*2-1:0] temp_y = (v.y*v.y)>>FBITS;
            automatic logic [WIDTH*2-1:0] temp_z = (v.z*v.z)>>FBITS;
            length_squared = temp_x + temp_y + temp_z;
        end
    endtask
    task set_lower_left;
        input point origin;
        input vec3 horizontal, vertical, focal_vec;
        output point lower_left_corner;
        begin
            // auto lower_left_corner = origin - horizontal/2 - vertical/2 - vec3(0, 0, focal_length);
            automatic logic [WIDTH-1:0] temp_x = origin.x - horizontal.x/2 - vertical.x/2 - focal_vec.x;
            automatic logic [WIDTH-1:0] temp_y = origin.y - horizontal.y/2 - vertical.y/2 - focal_vec.y;
            automatic logic [WIDTH-1:0] temp_z = origin.z - horizontal.z/2 - vertical.z/2 - focal_vec.z;
            set(temp_x, temp_y, temp_z, lower_left_corner);
        end
    endtask
    task to_pixel;
        input color c;
        output [11:0] pixel;
        begin
            automatic logic [WIDTH-1:0] temp_x = c.x>>(FBITS-8);
            automatic logic [WIDTH-1:0] temp_y = c.y>>(FBITS-8);
            automatic logic [WIDTH-1:0] temp_z = c.z>>(FBITS-8);
            pixel = {temp_x[3:0], temp_y[3:0], temp_z[3:0]};
        end
    endtask

    // RAY
    typedef struct{
        point orig;
        vec3 dir;
    } ray;
    task at;
        input ray r;
        input logic [WIDTH-1:0] t;
        output point3 p;
        begin
            automatic vec3 scaled_dir;
            scale(r.dir, t, scaled_dir);
            add(r.orig, scaled_dir, p);
        end
    endtask
    task set_r;
        input point orig;
        input vec3 dir;
        output ray r;
        begin
            r.orig = orig;
            r.dir = dir;
        end
    endtask
    task ray_color;
        input ray r;
        output color c;
        begin
            
        end
    endtask
endpackage
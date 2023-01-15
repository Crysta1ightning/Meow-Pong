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
        output point p;
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
import vec3_package::*;
module sqrt_vec3 #(parameter WIDTH=32, parameter FBITS=16) (
    input clk,
    input rst,
    input vec3 v_in,
    output reg all_valid,
    output vec3 v_out
);
    
    reg [WIDTH-1:0] rad, root, rem;
    reg [WIDTH-1:0] x_out, y_out, z_out;
    reg [1:0] state, next_state;
    parameter DO_X = 2'b00, DO_Y = 2'b01, DO_Z = 2'b10, FINISH = 2'b11;
    reg valid;
    reg sqrt_rst, next_sqrt_rst;
    
    // we don't care about rem here
    sqrt #(.WIDTH(WIDTH), .FBITS(FBITS)) sqrt_inst (.clk(clk), .rst(sqrt_rst), .valid(valid), .rad(rad), .root(root), .rem(rem));

    always_ff @(posedge clk, rst) begin
        if (rst) state <= DO_X;
        else state <= next_state;
    end
    always_comb begin
        if (rst) next_state = DO_X;
        else begin
            case (state)
                DO_X : begin
                    if (valid) next_state = DO_Y;
                    else next_state = DO_X;
                end
                DO_Y : begin
                    if (valid) next_state = DO_Z;
                    else next_state = DO_Y;
                end
                DO_Z : begin
                    if (valid) next_state = FINISH;
                    else next_state = DO_Z;
                end
                FINISH : next_state = FINISH;
            endcase
        end
    end

    always_ff @(posedge clk, rst) begin
        if (rst) all_valid <= 0;
        else if (state == FINISH) all_valid <= 1;
        else all_valid <= 0;
    end

    always_ff @(posedge clk, rst) begin
        if (rst) sqrt_rst = 1;
        else sqrt_rst <= next_sqrt_rst;
    end

    always_comb begin
        if (rst) begin
            set(0, 0, 0, v_out);
            rad = v_in.x;
            next_sqrt_rst = 1;
        end
        else begin
            next_sqrt_rst = 0;
            case (state)
                DO_X : begin
                    v_out.x = root;
                    if (valid) begin
                        rad = v_in.y;
                        next_sqrt_rst = 1;
                        // $display("X passed %d", valid);
                    end
                    else rad = v_in.x;
                end
                DO_Y : begin
                    v_out.y = root;
                    if (valid) begin
                        rad = v_in.z;
                        next_sqrt_rst = 1;
                    end
                    else rad = v_in.y;
                end
                DO_Z : begin
                    v_out.z = root;
                    if (valid) begin
                        rad = v_in.x;
                        next_sqrt_rst = 1;
                    end
                    else rad = v_in.z;
                end
            endcase
        end
    end

endmodule

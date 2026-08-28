`default_nettype none

module clk_div #(parameter NUM = 250) ( 
    input  wire clk_in,
    input  wire rstn,
    output reg  clk_out
);
    localparam WIDTH = $clog2(NUM);
    reg [WIDTH-1:0] counter;

    always @(posedge clk_in or negedge rstn) begin
        if (!rstn) begin
            counter <= {WIDTH{1'b0}};
            clk_out <= 1'b0;
        end else begin
            if (counter == NUM - 1) begin 
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
endmodule
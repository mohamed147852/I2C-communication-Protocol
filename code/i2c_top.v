`timescale 1ns/1ps
`default_nettype none

module i2c_top (
    input  wire        CLK,
    input  wire        rst_n,
    input  wire        Start,
    input  wire  [6:0] Slave_Addr,
    input  wire        Read_Write,
    input  wire  [7:0] Data_In,
    
    output wire  [7:0] Data_Out,
    output wire        Busy,
    output wire        Done,
    output wire        Ack_Error
);
    wire clk_div;
    wire SDA_bus, SCL_bus;
    wire SDA_Master_out, SCL_Master_out, SDA_Slave_out;

    clk_div cd (.clk_in(CLK), .rstn(rst_n), .clk_out(clk_div));

    Master ms (
        .CLK(clk_div), 
        .rst_n(rst_n), 
        .Start(Start), 
        .Slave_Addr(Slave_Addr),
        .Read_Write(Read_Write), 
        .Data_In(Data_In), 
        .SDA_IN(SDA_bus),
        .Data_Out(Data_Out), 
        .Busy(Busy), 
        .Done(Done), 
        .Ack_Error(Ack_Error),
        .SDA_Out(SDA_Master_out), 
        .SCL_Out(SCL_Master_out)
    );

    slave sv (
        .clk(CLK), 
        .rst_n(rst_n), 
        .sda_s_in(SDA_bus), 
        .scl_s_in(SCL_bus), 
        .sda_s_out(SDA_Slave_out)
    );

    assign SDA_bus = (SDA_Master_out == 1'b0 || SDA_Slave_out == 1'b0) ? 1'b0 : 1'bz;
    assign SCL_bus = (SCL_Master_out == 1'b0) ? 1'b0 : 1'bz;
    
endmodule
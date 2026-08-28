`timescale 1ns/1ps

module tb_i2c;
    reg        CLK;
    reg        rst_n;
    reg        Start;
    reg  [6:0] Slave_Addr;
    reg        Read_Write;
    reg  [7:0] Data_In;

    wire [7:0] Data_Out;
    wire       Busy;
    wire       Done;
    wire       Ack_Error;

    wire SDA = ti.SDA_bus;
    wire SCL = ti.SCL_bus;

    i2c_top ti (
        .CLK(CLK), 
        .rst_n(rst_n), 
        .Start(Start), 
        .Slave_Addr(Slave_Addr),
        .Read_Write(Read_Write), 
        .Data_In(Data_In), 
        .Data_Out(Data_Out),
        .Busy(Busy), 
        .Done(Done), 
        .Ack_Error(Ack_Error)
    );
   
    always #10 CLK = ~CLK; 

    initial begin
        CLK = 0; 
        rst_n = 0; 
        Start = 0; 
        Slave_Addr = 0; 
        Read_Write = 0; 
        Data_In = 0;
        
        #100 
        
        rst_n = 1;
        #100;

        Slave_Addr = 7'h20;
        Read_Write = 1'b0;  
        Data_In    = 8'hA5; 

        Start = 1'b1;
        @(posedge ti.clk_div); 
        Start = 1'b0;

        wait (Done == 1'b1);
        #5000; 

        Slave_Addr = 7'h20;
        Read_Write = 1'b1;  

        Start = 1'b1;
        @(posedge ti.clk_div); 
        Start = 1'b0;

        wait (Done == 1'b1);
        #5000;

        $finish;
    end

 \\
endmodule
`timescale 1ns/1ps

module Master_TB ();

parameter Width = 8;
parameter CLK_PERIOD = 10;

reg               CLK_TB;
reg               rst_n_TB;
reg               Start_TB;
reg  [6:0]        Slave_Addr_TB;
reg               Read_Write_TB;
reg  [Width-1:0]  Data_In_TB;
reg               SDA_IN_TB;
reg               SCL_IN_TB;
reg               stop_TB;

wire [Width-1:0]  Data_Out_TB;
wire              Busy_TB;
wire              Done_TB;
wire              Ack_Error_TB;
wire              SDA_Out_TB;
wire              SCL_Out_TB;


reg [Width-1:0] Slave_Data_TB;
reg [1:0]       Ack_Error_Test_TB;

always #(CLK_PERIOD/2) CLK_TB = ~CLK_TB;
always #25 SCL_IN_TB = ~SCL_IN_TB;

Master #(.Width(Width)) DUT
(
    .CLK        (CLK_TB),
    .rst_n      (rst_n_TB),
    .Start      (Start_TB),
    .Slave_Addr(Slave_Addr_TB),
    .Read_Write(Read_Write_TB),
    .Data_In   (Data_In_TB),
    .SDA_IN    (SDA_IN_TB),
    .SCL_IN    (SCL_IN_TB),
    .stop      (stop_TB),

    .Data_Out  (Data_Out_TB),
    .Busy      (Busy_TB),
    .Done      (Done_TB),
    .Ack_Error (Ack_Error_TB),
    .SDA_Out   (SDA_Out_TB),
    .SCL_Out   (SCL_Out_TB)
);


initial
 begin
    initialize();
    reset();

     $display("TEST 1 : Write");
    // WRITE
    Write_Read(8'b10110110 ,7'b1010000 ,1'b0);

    $display("Write DATA  = %b", Data_In_TB);
    $display("DONE        = %b", Done_TB);
    $display("ACK ERROR   = %b", Ack_Error_TB);

     if (Done_TB == 1'b1 && Ack_Error_TB == 1'b0)
       begin
        $display("TEST 1 : PASS");
        $display("----------------------------------------");
        end

     else
       begin
        $display("TEST 1 : FAIL");
        $display("----------------------------------------");
       end
    #10;


    $display("TEST 2 : Read");
    // READ 
    Slave_Data_TB = 8'b10110110;
    Write_Read(8'b00000000 ,7'b1010000 ,1'b1);

    $display("READ DATA  = %b", Data_Out_TB);
    $display("ACK ERROR   = %b", Ack_Error_TB);

     if ((Data_Out_TB == 8'b10110110) && (Ack_Error_TB == 1'b0))
          begin
        $display("TEST 2 : PASS");
        $display("----------------------------------------");
        end
    else
       begin
        $display("TEST 2 : FAIL");
        $display("----------------------------------------");
        end
    #10;


     $display("TEST 3 : Write");
     // WRITE
     Write_Read(8'b11010110 ,7'b1110000 ,1'b0);

    $display("Write DATA  = %b", Data_In_TB);
    $display("DONE        = %b", Done_TB);
    $display("ACK ERROR   = %b", Ack_Error_TB);

     if (Done_TB == 1'b1 && Ack_Error_TB == 1'b0)
       begin
        $display("TEST 3 : PASS");
        $display("----------------------------------------");
        end
     else
         begin
        $display("TEST 3 : FAIL");
        $display("----------------------------------------");
        end
       #10;


      $display("TEST 4 : Read");
      // READ 
      Slave_Data_TB = 8'b11010110;
      Write_Read(8'b00000000 ,7'b1110000 ,1'b1);
     $display("READ DATA  = %b", Data_Out_TB);
     $display("ACK ERROR   = %b", Ack_Error_TB);

     if ((Data_Out_TB == 8'b11010110) && (Ack_Error_TB == 1'b0))
       begin
        $display("TEST 4 : PASS");
        $display("----------------------------------------");
        end
     else
       begin
        $display("TEST 4 : FAIL");
        $display("----------------------------------------");
        end
      #10;


       //  ADDRESS ACK ERROR
       $display("TEST 5 : ADDRESS ACK ERROR");
       Ack_Error_Test_TB = 1;
       Write_Read(8'b10110110 ,7'b1010000 ,1'b0);

       $display("DONE        = %b", Done_TB);
       $display("ACK ERROR   = %b", Ack_Error_TB);

    if (Ack_Error_TB == 1'b1)
       begin
         $display("TEST 5 : PASS");
         $display("----------------------------------------");
        end
    else
       begin
         $display("TEST 5 : FAIL");
         $display("----------------------------------------");
        end
       #10;
 
       //  DATA ACK ERROR
       $display("TEST 6 : DATA ACK ERROR");
       Ack_Error_Test_TB = 2;
       Write_Read(8'b11010110 ,7'b1110000 ,1'b0);

       $display("Write DATA  = %b", Data_In_TB);
       $display("DONE        = %b", Done_TB);
       $display("ACK ERROR   = %b", Ack_Error_TB);

    if (Ack_Error_TB == 1'b1)
       begin
         $display("TEST 6 : PASS");
         $display("----------------------------------------");
        end
    else
       begin
         $display("TEST 6 : FAIL");
         $display("----------------------------------------");
        end
       Ack_Error_Test_TB = 2'd0;
       #10;


   $display("TEST 7 : Write");
    // WRITE
    Write_Read(8'b11110000 ,7'b0110011 ,1'b0);

    $display("Write DATA  = %b", Data_In_TB);
    $display("DONE        = %b", Done_TB);
    $display("ACK ERROR   = %b", Ack_Error_TB);

     if (Done_TB == 1'b1 && Ack_Error_TB == 1'b0)
       begin
        $display("TEST 7 : PASS");
        $display("----------------------------------------");
        end

     else
       begin
        $display("TEST 7 : FAIL");
        $display("----------------------------------------");
       end
    #10;


    $display("TEST 8 : Read");
    // READ 
    Slave_Data_TB = 8'b11110000;
    Write_Read(8'b00000000 ,7'b0110011 ,1'b1);

    $display("READ DATA  = %b", Data_Out_TB);
    $display("ACK ERROR   = %b", Ack_Error_TB);

     if ((Data_Out_TB == 8'b11110000) && (Ack_Error_TB == 1'b0))
          begin
        $display("TEST 8 : PASS");
        $display("----------------------------------------");
        end
    else
       begin
        $display("TEST 8 : FAIL");
        $display("----------------------------------------");
        end
    #10;
     $stop;

end


task initialize;
  begin
    CLK_TB        = 1'b0;
    rst_n_TB      = 1'b0;
    Start_TB      = 1'b0;
    Slave_Addr_TB = 7'b0;
    Read_Write_TB = 1'b0;
    Data_In_TB    = 8'b0;
    SDA_IN_TB     = 1'b1;
    SCL_IN_TB     = 1'b1;
    stop_TB       = 1'b0;
    Slave_Data_TB = 8'b0;
    Ack_Error_Test_TB = 1'b0;
 end
endtask

task reset;
 begin
    rst_n_TB = 1'b0;
    #(CLK_PERIOD);
    rst_n_TB = 1'b1;
    #(CLK_PERIOD);
 end
endtask

task Write_Read;
input [Width-1:0] Data_In;
input [6:0]       Address;
input             R_W;
  begin
    Slave_Addr_TB = Address;
    Read_Write_TB = R_W;
    Data_In_TB = Data_In;

    Start_TB = 1'b1;
    #(CLK_PERIOD * 2);
    Start_TB = 1'b0;

     #400;

 end
endtask


always @(*)
 begin
    // Default = NACK / released bus
    SDA_IN_TB = 1'b1;

    // ADDRESS ACK
    if (DUT.current_state == DUT.addr_ack)
    begin
        if (Ack_Error_Test_TB == 1)
            SDA_IN_TB = 1'b1;       // NACK
        else
            SDA_IN_TB = 1'b0;       // ACK
    end


    // DATA ACK
    else if (DUT.current_state == DUT.data_ack)
    begin
        if (Ack_Error_Test_TB == 2)
            SDA_IN_TB = 1'b1;       // NACK
        else
            SDA_IN_TB = 1'b0;       // ACK
    end

    // READ DATA
    else if (DUT.current_state == DUT.receive_data)
    begin
        SDA_IN_TB = Slave_Data_TB[DUT.bit_count];
    end
end

endmodule
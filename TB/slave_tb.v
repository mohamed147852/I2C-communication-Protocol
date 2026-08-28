`timescale 1ns/1ps
module slave_tb ();

parameter width = 8;

reg  clk_tb;
reg  rst_tb;
reg  sda_s_in_tb;
reg  scl_s_in_tb;
wire sda_s_out_tb;

integer test_num;

parameter clk_period = 20;
parameter scl_hold    = 20;
parameter testcases   = 3;   // single-frame cases; frame 4 (two-frame) handled separately

reg [6:0]       Test_addr       [0:testcases-1];
reg             Test_rw         [0:testcases-1];
reg [width-1:0] Test_data       [0:testcases-1];
reg             Expect_addr_ack [0:testcases-1];
reg             Expect_data_ack [0:testcases-1];

always #(clk_period/2) clk_tb = ~clk_tb;

task initialization();
    begin
        clk_tb      = 1'b0;
        sda_s_in_tb = 1'b1;
        scl_s_in_tb = 1'b1;
        rst_tb      = 1'b0;
        #(clk_period*4);
        rst_tb = 1'b1;
        #(clk_period*4);
    end
endtask

task i2c_wait(input integer n);
    integer k;
    begin
        for (k = 0; k < n; k = k+1)
            @(posedge clk_tb);
    end
endtask

task i2c_start();
    begin
        sda_s_in_tb = 1'b1;
        scl_s_in_tb = 1'b1;
        i2c_wait(scl_hold);
        sda_s_in_tb = 1'b0;
        i2c_wait(scl_hold);
        scl_s_in_tb = 1'b0;
        i2c_wait(scl_hold);
    end
endtask

task i2c_stop();
    begin
        sda_s_in_tb = 1'b0;
        scl_s_in_tb = 1'b0;
        i2c_wait(scl_hold);
        scl_s_in_tb = 1'b1;
        i2c_wait(scl_hold);
        sda_s_in_tb = 1'b1;
        i2c_wait(scl_hold);
    end
endtask

task i2c_read_ack(output ack_val);
    begin
        sda_s_in_tb = 1'b1;
        i2c_wait(scl_hold/2);
        scl_s_in_tb = 1'b1;
        i2c_wait(scl_hold);
        ack_val = ~sda_s_out_tb;
        scl_s_in_tb = 1'b0;
        i2c_wait(scl_hold);
    end
endtask

// bit-sending is now inlined here instead of a separate task
task i2c_send_byte(input [7:0] byte_val);
    integer i;
    begin
        for (i = 7; i >= 0; i = i-1) begin
            sda_s_in_tb = byte_val[i];
            i2c_wait(scl_hold/2);
            scl_s_in_tb = 1'b1;
            i2c_wait(scl_hold);
            scl_s_in_tb = 1'b0;
            i2c_wait(scl_hold);
        end
    end
endtask

task run_test(input integer i);
    reg addr_ack_got, data_ack_got;
    begin
        i2c_start();
        i2c_send_byte({Test_addr[i], Test_rw[i]});
        i2c_read_ack(addr_ack_got);

        if (addr_ack_got !== Expect_addr_ack[i]) begin
            $display("Test %0d FAILED at ADDRESS ACK: expected %b got %b at time %0d",
                       i+1, Expect_addr_ack[i], addr_ack_got, $time);
        end else if (!Expect_addr_ack[i]) begin
            $display("Test %0d Passed (correctly NACKed wrong address) at time %0d", i+1, $time);
        end else begin
            i2c_send_byte(Test_data[i]);
            i2c_read_ack(data_ack_got);
            if (data_ack_got !== Expect_data_ack[i]) begin
                $display("Test %0d FAILED at DATA ACK: expected %b got %b at time %0d",
                           i+1, Expect_data_ack[i], data_ack_got, $time);
            end else begin
                $display("Test %0d Passed with addr_ack=%b data_ack=%b at time %0d",
                           i+1, addr_ack_got, data_ack_got, $time);
            end
        end

        i2c_stop();
        i2c_wait(scl_hold*2);
    end
endtask

initial begin
    $dumpfile("slave.vcd");
    $dumpvars;

    // Test case 1: correct address, write, ordinary data byte
    Test_addr[0] = 7'b1010101; Test_rw[0] = 1'b0; Test_data[0] = 8'hA5;
    Expect_addr_ack[0] = 1'b1; Expect_data_ack[0] = 1'b1;

    // Test case 2: wrong address, should NACK, no data phase
    Test_addr[1] = 7'b1111111; Test_rw[1] = 1'b0; Test_data[1] = 8'h00;
    Expect_addr_ack[1] = 1'b0; Expect_data_ack[1] = 1'b0;

    // Test case 3: correct address, different data byte
    Test_addr[2] = 7'b1010101; Test_rw[2] = 1'b0; Test_data[2] = 8'h3C;
    Expect_addr_ack[2] = 1'b1; Expect_data_ack[2] = 1'b1;

    initialization();

    for (test_num = 0; test_num < testcases; test_num = test_num+1)
        run_test(test_num);

    // Test case 4: two consecutive frames joined by a repeated START (no STOP in between)
    begin : two_frame_test
        reg addr_ack_1, data_ack_1, addr_ack_2, data_ack_2;

        i2c_start();
        i2c_send_byte({7'b1010101, 1'b0});
        i2c_read_ack(addr_ack_1);
        i2c_send_byte(8'h5A);
        i2c_read_ack(data_ack_1);

        i2c_start();  // repeated START, no i2c_stop before this
        i2c_send_byte({7'b1010101, 1'b0});
        i2c_read_ack(addr_ack_2);
        i2c_send_byte(8'hC3);
        i2c_read_ack(data_ack_2);

        i2c_stop();

        if (addr_ack_1 && data_ack_1 && addr_ack_2 && data_ack_2)
            $display("Test 4 Passed (two-frame transaction) at time %0d", $time);
        else
            $display("Test 4 FAILED: addr1=%b data1=%b addr2=%b data2=%b at time %0d",
                       addr_ack_1, data_ack_1, addr_ack_2, data_ack_2, $time);
    end

    #(scl_hold*clk_period*4);
    $stop;
end

slave #(.width(width)) DUT (
    .sda_s_in  (sda_s_in_tb),
    .scl_s_in  (scl_s_in_tb),
    .clk       (clk_tb),
    .rst       (rst_tb),
    .sda_s_out (sda_s_out_tb)
);

endmodule
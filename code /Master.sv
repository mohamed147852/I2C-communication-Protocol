module Master #(parameter Width = 8)
(
    input  wire               CLK,
    input  wire               rst_n,
    input  wire               Start,
    input  wire  [6:0]        Slave_Addr,
    input  wire               Read_Write,
    input  wire  [Width-1:0]  Data_In,
    input  wire               SDA_IN,
    input  wire               SCL_IN,
    input  wire               stop,

    output reg  [Width-1:0]  Data_Out,
    output reg               Busy,
    output reg               Done,
    output reg               Ack_Error,
    output reg               SDA_Out,
    output reg               SCL_Out
);

typedef enum bit [3:0] 
{
  IDLE         = 4'b0000,
           strt         = 4'b0001,
           send_addr    = 4'b0011,
           send_R_W     = 4'b0010,
           addr_ack     = 4'b0110,
           send_data    = 4'b0111,
           data_ack     = 4'b0101,
           receive_data = 4'b0100,
           error        = 4'b1100,
           send_data_ack= 4'b1101,
           stp          = 4'b1111
} state_e ;
state_e current_state , next_state;

reg [3:0] bit_count;
reg [Width-1:0] Data_Out_reg;
reg             Done_reg;
reg             Ack_Error_reg;

always @(posedge CLK or negedge rst_n)
begin
    if (!rst_n)
    begin
        current_state <= IDLE;
        bit_count     <= 4'd0;
        Data_Out_reg  <= {Width{1'b0}};
        Done_reg      <= 1'b0;
        Ack_Error_reg <= 1'b0;
    end

    else
    begin
        current_state <= next_state;

        // Start address
        if ((current_state == IDLE) && Start)
        begin
            Done_reg      <= 1'b0;
            Ack_Error_reg <= 1'b0;
        end

        // ADDRESS ACK ERROR or DATA ACK ERROR
        else if (((current_state == addr_ack) || (current_state == data_ack)) && (SCL_IN == 1'b1) &&(SDA_IN == 1'b1))
        begin
            Ack_Error_reg <= 1'b1;
        end

        else if ((current_state == stp) && (SCL_IN == 1'b1))
        begin
            Done_reg <= 1'b1;
        end

          // BIT COUNTER
          if ((current_state == IDLE) && Start)
           begin
            bit_count <= 4'd6;
          end
        // Address counter
        else if ((current_state == send_addr) && (SCL_IN == 1'b0))
        begin
            if (bit_count != 0)
                bit_count <= bit_count - 1'b1;
        end

        // Start WRITE data
        else if ((current_state == addr_ack) && (Read_Write == 1'b0) && (SDA_IN == 1'b0) && (SCL_IN == 1'b1))
        begin
            bit_count <= 4'd7;
        end

        // WRITE data counter
        else if ((current_state == send_data) && (SCL_IN == 1'b0))
        begin
            if (bit_count != 0)
                bit_count <= bit_count - 1'b1;
        end

        // Start READ data
        else if ((current_state == addr_ack) && (Read_Write == 1'b1) && (SDA_IN == 1'b0) && (SCL_IN == 1'b1))
        begin
            bit_count <= 4'd7;
            Data_Out_reg <= {Width{1'b0}};
        end

        // Receive data
        else if ((current_state == receive_data) && (SCL_IN == 1'b1))
        begin
            Data_Out_reg[bit_count] <= SDA_IN;

            if (bit_count != 0)
                bit_count <= bit_count - 1'b1;
        end

    end
end


always @(*)
 begin
    Data_Out  = Data_Out_reg;
    Busy      = 1'b0;
    Done      = Done_reg;
    Ack_Error = Ack_Error_reg;
    SDA_Out   = 1'b0;
    SCL_Out   = 1'b0;

    next_state = current_state;

    case (current_state)

        IDLE: begin
            Busy = 1'b0;
            if (Start)
                next_state = strt;
            else
                next_state = IDLE;
        end


        strt: begin
            Busy = 1'b1;
            if (SCL_IN == 1'b1)
            begin
                SDA_Out = 1'b1;
                next_state = send_addr;
            end

            else
            begin
                next_state = strt;
            end
        end

        send_addr: begin
            Busy = 1'b1;
            if (SCL_IN == 1'b0)
            begin
                SDA_Out = Slave_Addr[bit_count];

                if (bit_count == 0)
                    next_state = send_R_W;
                else
                    next_state = send_addr;
            end

            else
            begin
                next_state = send_addr;
            end
        end

        send_R_W: begin
            Busy = 1'b1;
            if (SCL_IN == 1'b0)
            begin
                SDA_Out = Read_Write;
                next_state = addr_ack;
            end

            else
            begin
                next_state = send_R_W;
            end
        end

    addr_ack: begin
            Busy = 1'b1;
            SDA_Out = 1'b0;
            if (SCL_IN == 1'b1)
            begin
                if (SDA_IN == 1'b0)
                begin

                    if (Read_Write == 1'b0)
                        next_state = send_data;
                    else
                        next_state = receive_data;
                end

                else
                begin
                    // NACK
                    next_state = error;
                end
            end
            else
            begin
                // Wait for SCL HIGH
                next_state = addr_ack;
            end
        end

        send_data: begin
            Busy = 1'b1;
            if (SCL_IN == 1'b0)
            begin

                SDA_Out = Data_In[bit_count];

                if (bit_count == 0)
                    next_state = data_ack;
                else
                    next_state = send_data;
            end
            else
            begin
                next_state = send_data;
            end
        end

    data_ack: begin
            Busy = 1'b1;
            SDA_Out = 1'b0;

            if (SCL_IN == 1'b1)
            begin
                if (SDA_IN == 1'b0)
                begin
                    // ACK
                    next_state = stp;
                end
                else
                begin
                    // NACK
                    next_state = error;
                end
            end
            else
            begin
                next_state = data_ack;
            end
        end

        receive_data: begin
            Busy = 1'b1;
            SDA_Out = 1'b0;
            if (SCL_IN == 1'b1)
            begin
                if (bit_count == 0)
                    next_state = send_data_ack;
                else
                    next_state = receive_data;
            end

            else
            begin
                next_state = receive_data;
            end
        end


        send_data_ack: begin
            Busy = 1'b1;
            if (SCL_IN == 1'b0)
            begin
                SDA_Out = 1'b0;
                next_state = stp;
            end

            else
            begin
                next_state = send_data_ack;
            end
        end

        error: begin
            Busy      = 1'b0;
            Ack_Error = 1'b1;
            next_state = stp;
        end


        stp: begin
            Busy = 1'b1;
            if (SCL_IN == 1'b1)
            begin
               if (stop)
                begin
                   SDA_Out = 1'b1;
                  next_state = IDLE; 
                end

                else
                 begin
                   SDA_Out = 1'b0;
                   next_state = IDLE;
                 end
            end

            else
            begin
                next_state = stp;
            end
        end


        default: begin
                    next_state = IDLE;
                end
    endcase
end

endmodule

module slave #(parameter width = 8)(
    input sda_s_in,
    input scl_s_in,
    input clk,                  // This will be the divided clk that samples the incoming data
    input rst,
    output reg sda_s_out
);

localparam [6:0] addr =7'b1010101;
 
typedef enum bit [ 2 : 0 ] {
    IDLE     =3'b000,
    ADDRESS  =3'b001,
    R_W      =3'b011,
    ACK_ADDR =3'b010,
    DATA     =3'b110,
    ACK_DATA =3'b111,
    STOP     =3'b101//grey coding that only one bit changing during change between diffrent states to save power
} state_e;

state_e cs,ns;

integer i;

reg sda_s_d,scl_s_d;
reg [4:0] bit_cnt;
reg [6:0] sent_addr;
wire [ width-1 : 0 ] data_out = 8'b11001100;
reg [4:0] cnt;
reg r_or_w;
reg cont;
reg [ width-1 :0 ] data_in;
reg edge_detection_d;

wire start_cond,stop_cond;
wire edge_detection;

assign start_cond = ((sda_s_d==1'b1 && sda_s_in==1'b0) && scl_s_in==1'b1);
assign stop_cond = ((sda_s_d==1'b0 && sda_s_in==1'b1) && scl_s_in==1'b1);
assign edge_detection = ( scl_s_in==1'b1 && scl_s_d==1'b0);


always @(posedge clk or negedge rst )
    begin
        if(!rst)
            begin
                bit_cnt<=0;
                edge_detection_d<=0;
            end
        else
            begin
                bit_cnt <= start_cond ? 1'b0:edge_detection? bit_cnt+1 : bit_cnt;
                edge_detection_d<=edge_detection;
            end
    end

always @(posedge clk or negedge rst ) 
    begin
        if(!rst)
            begin
                sda_s_d<=0;
                scl_s_d<=0;
            end
        else
            begin
                sda_s_d<=sda_s_in;
                scl_s_d<=scl_s_in;
            end
    end

always@(posedge clk or negedge rst)
    begin
        if(!rst)
            begin
                cs<=IDLE;
            end
        else 
            begin
                cs<=ns;
            end
    end

always @(*) 
    begin
        case(cs)
            IDLE:   
                begin
                    if (start_cond) 
                        begin
                            ns=ADDRESS;
                        end
                    else 
                        begin
                            ns=IDLE;
                        end
                end

            ADDRESS:   
                begin
                    if(bit_cnt==1 && edge_detection_d)
                        begin
                            ns=ADDRESS;
                            sent_addr[6]=sda_s_d;
                            cont=0;
                        end
                    else if(bit_cnt !=7 && edge_detection_d)
                        begin
                            ns=ADDRESS;
                            sent_addr[7 - bit_cnt]=sda_s_d;
                            cont=0;
                        end
                    else 
                        begin
                            if(edge_detection_d)
                                begin
                                    sent_addr[0] =sda_s_d; 
                                    if(sent_addr == addr)
                                        begin
                                            ns=R_W;
                                            cont=1'b1;
                                        end
                                    else
                                        begin
                                            ns=R_W;
                                            cont=1'b0;
                                        end
                                end
                            else 
                                begin
                                    ns=ADDRESS;
                                    cont=1'b0;
                                    sent_addr=sent_addr;
                                end
                            
                        end
                end
            R_W:   
                begin
                    if(edge_detection_d)      //bit count = 8
                        begin
                            ns=ACK_ADDR;
                            r_or_w=r_or_w;
                        end
                    else 
                        begin
                            ns=R_W;
                            r_or_w=sda_s_d; //bit count =7
                        end
                end

            ACK_ADDR:
                    begin
                        if( edge_detection_d)     //9
                            begin
                                if(cont)
                                    begin
                                        sda_s_out=1'b0;
                                        ns=DATA;
                                    end
                                else 
                                    begin
                                        sda_s_out=1'b1;
                                        ns=IDLE;
                                    end
                            end
                        else 
                            begin
                                sda_s_out=1'b1; //8
                                ns=ACK_ADDR;
                            end      
                    end
            DATA:
                begin
                    if(r_or_w)
                        begin
                            if(bit_cnt==9)
                                begin
                                    sda_s_out=data_out[7]; //9
                                    ns=DATA;
                                end
                            else if (bit_cnt !=16)
                                begin
                                    sda_s_out=data_out[16-bit_cnt]; //10-15
                                    ns=DATA;
                                end
                            else 
                                begin
                                    sda_s_out=data_out[0]; //16
                                    ns=ACK_DATA;
                                end
                        end
                    else 
                        begin
                            if(bit_cnt==9)
                                begin
                                    data_in[7]=sda_s_in; //9
                                    ns=DATA;
                                end
                            else if (bit_cnt !=16)
                                begin
                                    data_in[16-bit_cnt]=sda_s_in; //10-15
                                    ns=DATA;
                                end
                            else 
                                begin
                                    data_in[0]=sda_s_in; //16
                                    ns=ACK_DATA;
                                end
                        end
                    
                end
            ACK_DATA:   
                begin
                    if(edge_detection_d)
                        begin
                            sda_s_out=1'b0; //18
                            if(start_cond)
                                begin
                                    ns=DATA;
                                end
                            else 
                                begin
                                    ns=STOP;
                                end
                                
                            
                        end
                    else
                        begin
                            sda_s_out=sda_s_out; //17
                            ns=ACK_DATA;
                        end
                end 
            STOP:
                begin
                    if(stop_cond)
                        begin
                            ns=IDLE;
                        end
                    else 
                        begin
                            ns=STOP;
                        end
                end 

        endcase
    end


    
endmodule
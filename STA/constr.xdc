create_clock -name sys_clk -period 20.0 [get_ports CLK]

set_clock_uncertainty 0.5 [get_clocks sys_clk]

set_input_delay -clock sys_clk -max 2.5 [get_ports rst_n ]
set_input_delay -clock sys_clk -min 0.5 [get_ports rst_n ] 

set_input_delay -clock sys_clk -max 2.5 [get_ports Start ]
set_input_delay -clock sys_clk -min 0.5 [get_ports Start ]

set_input_delay -clock sys_clk -max 2.5 [get_ports Read_Write ]
set_input_delay -clock sys_clk -min 0.5 [get_ports Read_Write ]

set_input_delay -clock sys_clk -max 2.5 [get_ports  Slave_Addr[*]]
set_input_delay -clock sys_clk -min 0.5 [get_ports  Slave_Addr[*]]

set_input_delay -clock sys_clk -max 2.5 [get_ports  Data_In[*]]
set_input_delay -clock sys_clk -min 0.5 [get_ports  Data_In[*]]

set_output_delay -clock sys_clk -max 2.5 [get_ports Busy ] 
set_output_delay -clock sys_clk -min 0.5 [get_ports Busy ]

set_output_delay -clock sys_clk -max 2.5 [get_ports Done ]
set_output_delay -clock sys_clk -min 0.5 [get_ports Done ]

set_output_delay -clock sys_clk -max 2.5 [get_ports  Ack_Error ]
set_output_delay -clock sys_clk -min 0.5 [get_ports  Ack_Error ]

set_output_delay -clock sys_clk -max 2.5 [get_ports  Data_Out[*]]
set_output_delay -clock sys_clk -min 0.5 [get_ports  Data_Out[*]]
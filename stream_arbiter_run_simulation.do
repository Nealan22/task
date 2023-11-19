transcript on

vlib work

vlog -sv +incdir+./ ./stream_arbiter_tb.sv
vlog -sv +incdir+./ ./stream_arbiter.sv

vsim -t 1ns -voptargs="+acc" stream_arbiter_tb

add wave stream_arbiter_tb/clk
add wave stream_arbiter_tb/rst_n
add wave stream_arbiter_tb/s_valid_i
add wave stream_arbiter_tb/s_ready_o
add wave stream_arbiter_tb/s_last_i
add wave -radix hexadecimal stream_arbiter_tb/s_qos_i
add wave -radix hexadecimal stream_arbiter_tb/s_data_i
add wave stream_arbiter_tb/m_valid_o
add wave stream_arbiter_tb/m_ready_i
add wave stream_arbiter_tb/m_last_o
add wave stream_arbiter_tb/m_id_o
add wave -radix hexadecimal stream_arbiter_tb/m_qos_o
add wave -radix hexadecimal stream_arbiter_tb/m_data_o
add wave -radix hexadecimal stream_arbiter_tb/i_stream_arbiter/state
add wave -radix hexadecimal stream_arbiter_tb/i_stream_arbiter/qos_i
add wave -radix hexadecimal stream_arbiter_tb/i_stream_arbiter/qos_i_d

configure wave -timelineunits us

run -all

wave zoom full
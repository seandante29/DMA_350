`timescale 1ns / 1ps

module mux (
//input wire clk, resetn,
input wire [31:0] a,b,c,// a- previous value //b- default value // c-cmd fsm
input wire s1,s0,// s1- regclr //s0-header cmd
output wire [31:0] y);//concat cmd
wire [31:0] w1;

assign w1 = s1 ? b : a;
assign y  = s0? c : w1;

endmodule
 

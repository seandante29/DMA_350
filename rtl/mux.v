`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.01.2026 12:29:34
// Design Name: 
// Module Name: mux
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux (
//input wire clk, resetn,
input wire [31:0] a,b,c,// a- previous value //b- default value // c-cmd fsm
input wire s1,s0,// s1- regclr //s0-header cmd
output wire [31:0] y);//concat cmd

wire [31:0] w1;

assign w1 = s1 ? b : a;
assign y  = s0? c : w1;

endmodule
 

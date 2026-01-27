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
//reg prev_s1,prev_s0,s1_edge,s0_edge;
/*always@(posedge clk or negedge resetn) begin
if(!resetn) begin
    prev_s1 <= 0;
    s1_edge <= 0;
    prev_s0 <= 0;
    s0_edge <= 0;
end 
else begin
    prev_s1 <= s1;
    s1_edge <= (!prev_s1 & s1);
    prev_s0 <= s0;
    s0_edge <= (!prev_s0 & s0);
 end
 end*/
wire [31:0] w1;

assign w1 = s1 ? b : a;
assign y  = s0? c : w1;

endmodule
 

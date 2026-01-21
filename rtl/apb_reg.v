`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2026 02:46:58 PM
// Design Name: 
// Module Name: top_mod
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
/////////////////////////////////////////////

module apb_reg #(parameter DATA_WIDTH = 32,
         ADDR_WIDTH = 32,
         STRB_WIDTH =  DATA_WIDTH/8,
         WIDTH = 32)
     (
     //APB signals
      input wire clk,
      input wire resetn,
      input wire PCLK,
      input wire PRESETn,
      input wire [ ADDR_WIDTH-1 : 0 ] PADDR,
      input wire PWRITE,
      input wire PENABLE,
      input wire PSEL,
      input  wire [(WIDTH*2)-1 : 0] chn_reg_in,
      input wire reg_wr_en,
      input wire [DATA_WIDTH-1 : 0] PWDATA,
      input wire [STRB_WIDTH-1 : 0] PSTRB,
      output wire [DATA_WIDTH-1 : 0] PRDATA,
      output wire PREADY,
      output wire PSLVERR,
      output wire chn_wr_en,
      //REGBANK signals
      //this is for testing 2 mods
     // input wire ch_wr_en_i,
      //output wire chn_wr_en_o,
      output wire  [(WIDTH * 15) -1:0] reg_chn_out
      );
      
      wire cfg_rd_en;
      wire cfg_wr_en;
      wire [DATA_WIDTH-1 : 0] cfg_wdata;
      wire [ADDR_WIDTH-1 : 0] cfg_addr;
      wire [DATA_WIDTH-1 : 0] cfg_data_out;
      
      
      apb_slave dut0
      (.PCLK(PCLK),
       .PRESETn(PRESETn),
       .PADDR(PADDR),
       .PWRITE(PWRITE),
       .PSEL(PSEL),
       .PENABLE(PENABLE),
       .PWDATA(PWDATA),
       .PSTRB(PSTRB),
       .PRDATA(PRDATA),
       .PREADY(PREADY),
       .PSLVERR(PSLVERR),
       .cfg_rdata(cfg_data_out),
       .cfg_wdata(cfg_wdata),
       .cfg_addr(cfg_addr),
       .cfg_wr_en(cfg_wr_en),
       .cfg_rd_en(cfg_rd_en));
       
       register_bank dut1
         (.clk(clk),
         .resetn(resetn),
         .cfg_rd_en(cfg_rd_en),
         .cfg_wr_en(cfg_wr_en),
        // .chn_wr_en_i(chn_wr_en_i),
         .cfg_data_in(cfg_wdata),
         .addr_in(cfg_addr),
         .chn_reg_in(chn_reg_in),
         .cfg_data_out(cfg_data_out),
         .chn_wr_en(chn_wr_en),
         .reg_wr_en(reg_wr_en),
         .reg_chn_out(reg_chn_out));
endmodule

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
      input wire [ ADDR_WIDTH-1 : 0 ] PADDR, // 
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
      output wire [WIDTH-1 : 0] cfg_CH_CMD,
	  output wire [WIDTH-1 : 0] cfg_CH_STATUS,
	  output wire [WIDTH-1 : 0] cfg_CH_INTREN,
	  output wire [WIDTH-1 : 0] cfg_CH_CTRL,
      output wire [WIDTH-1 : 0] cfg_CH_SRCADDR,
	  output wire [WIDTH-1 : 0] cfg_CH_DESADDR,
	  output wire [WIDTH-1 : 0] cfg_CH_XSIZE,
	  output wire [WIDTH-1 : 0] cfg_CH_SRCTRANSCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_DESTRANSCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_XADDRINC,
	  output wire [WIDTH-1 : 0] cfg_CH_FILLVAL,
	  output wire [WIDTH-1 : 0] cfg_CH_SRCTRIGINCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_DESTRIGINCFG,
	  output wire [WIDTH-1 : 0] cfg_CH_TRIGOUTCFG,
	  output wire [WIDTH-1 : 0] cfg_LINKADDR,
	  output wire chn_cmd_wr_en_o, chn_stat_wr_en_o, chn_intren_wr_en_o,
      chn_ctrl_wr_en_o,chn_srcaddr_wr_en_o, chn_desaddr_wr_en_o, chn_xsize_wr_en_o, chn_srctrans_wr_en_o,
      chn_destrans_wr_en_o,chn_xaddrinc_wr_en_o,chn_fillval_wr_en_o,chn_srctrigin_wr_en_o,chn_destrigin_wr_en_o,
      chn_trigout_wr_en_o,chn_linkaddr_wr_en_o
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
//         .reg_wr_en(reg_wr_en),
        .cfg_CH_CMD            (cfg_CH_CMD),
        .cfg_CH_STATUS         (cfg_CH_STATUS),
        .cfg_CH_INTREN         (cfg_CH_INTREN),
        .cfg_CH_CTRL           (cfg_CH_CTRL),
        .cfg_CH_SRCADDR        (cfg_CH_SRCADDR),
        .cfg_CH_DESADDR        (cfg_CH_DESADDR),
        .cfg_CH_XSIZE          (cfg_CH_XSIZE),
        .cfg_CH_SRCTRANSCFG    (cfg_CH_SRCTRANSCFG),
        .cfg_CH_DESTRANSCFG    (cfg_CH_DESTRANSCFG),
        .cfg_CH_XADDRINC       (cfg_CH_XADDRINC),
        .cfg_CH_FILLVAL        (cfg_CH_FILLVAL),
        .cfg_CH_SRCTRIGINCFG   (cfg_CH_SRCTRIGINCFG),
        .cfg_CH_DESTRIGINCFG   (cfg_CH_DESTRIGINCFG),
        .cfg_CH_TRIGOUTCFG     (cfg_CH_TRIGOUTCFG),
        .cfg_LINKADDR          (cfg_LINKADDR),
        
        .chn_cmd_wr_en_o       (chn_cmd_wr_en_o),
        .chn_stat_wr_en_o      (chn_stat_wr_en_o),
        .chn_intren_wr_en_o    (chn_intren_wr_en_o),
        .chn_ctrl_wr_en_o      (chn_ctrl_wr_en_o),
        .chn_srcaddr_wr_en_o   (chn_srcaddr_wr_en_o),
        .chn_desaddr_wr_en_o   (chn_desaddr_wr_en_o),
        .chn_xsize_wr_en_o     (chn_xsize_wr_en_o),
        .chn_srctrans_wr_en_o  (chn_srctrans_wr_en_o),
        .chn_destrans_wr_en_o  (chn_destrans_wr_en_o),
        .chn_xaddrinc_wr_en_o  (chn_xaddrinc_wr_en_o),
        .chn_fillval_wr_en_o   (chn_fillval_wr_en_o),
        .chn_srctrigin_wr_en_o (chn_srctrigin_wr_en_o),
        .chn_destrigin_wr_en_o (chn_destrigin_wr_en_o),
        .chn_trigout_wr_en_o   (chn_trigout_wr_en_o),
        .chn_linkaddr_wr_en_o  (chn_linkaddr_wr_en_o)
         );
endmodule

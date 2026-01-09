`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.01.2026 14:26:11
// Design Name: 
// Module Name: internal_reg
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


module internal_reg_tb();

   //inputs
   reg clk,resetn;
 //  reg wr_en,
   reg [(32 * 14) -1:0] data_in;
 
 //error signals from data fsm
   reg AXIRDRESPERR;
   reg AXIRDPOISERR;
   reg AXIWRRESPERR;
   reg BUSERR;
   reg config_error;
   reg regval_error;
 // from trigger
   reg SRCTRIGINSELERR;
   reg DESTRIGINSELERR;
   reg TRIGOUTSELERR;
 // from cmd fsm
   reg AXIRDRESPERR_CMDFSM;
   reg AXIRDPOISERR_CMDFSM;
   reg BUSERR_CMDFSM;
   reg LINKHDERR;
 
   reg STAT_TRIGOUTACKWAIT;
   reg STAT_DESTRIGINWAIT;
   reg STAT_SRCTRIGINWAIT;
   reg STAT_RESUMEWAIT;
   reg STAT_STOPPED;
   reg STAT_PAUSED;
   reg STAT_DISABLED;
   reg STAT_ERR;
   reg STAT_DONE;
 
 //outputs
 
 // to reg bank
   wire [(32*2)-1 : 0] chn_reg_out;
 // to partselect module
    wire [31:0] CH_CTRL;
    wire [31:0] CH_INTREN;
    wire [31:0] CH_XSIZE;
    wire [31:0] CH_LINKADDR;
    wire [31:0] CH_CMD;
    wire [31:0] CH_STATUS;
    wire [31:0] CH_XADDRINC;
    wire [31:0] CH_SRCTRANSCFG;
    wire [31:0] CH_DESTRANSCFG;
    wire [31:0] CH_SRCTRIGINCFG;
    wire [31:0] CH_DESTRIGINCFG;
    wire [31:0] CH_TRIGOUTCFG;
    wire [31:0] CH_SRCADDR;
    wire [31:0] CH_DESADDR;
    wire [31:0] CH_FILLVAL;
    wire IRQ;
   
    always #5 clk = ~clk;
    
     internal_reg dut1 ( clk,resetn,data_in,AXIRDRESPERR,AXIRDPOISERR,AXIWRRESPERR,BUSERR,config_error,regval_error,SRCTRIGINSELERR, DESTRIGINSELERR,
   TRIGOUTSELERR,  AXIRDRESPERR_CMDFSM, AXIRDPOISERR_CMDFSM,BUSERR_CMDFSM,LINKHDERR, STAT_TRIGOUTACKWAIT,
   STAT_DESTRIGINWAIT, STAT_SRCTRIGINWAIT, STAT_RESUMEWAIT, STAT_STOPPED, STAT_PAUSED, STAT_DISABLED,
   STAT_ERR,STAT_DONE,chn_reg_out,CH_CTRL,CH_INTREN,CH_XSIZE,CH_LINKADDR,CH_CMD,CH_STATUS, CH_XADDRINC,CH_SRCTRANSCFG,CH_DESTRANSCFG,CH_SRCTRIGINCFG,
   CH_DESTRIGINCFG,CH_TRIGOUTCFG,CH_SRCADDR,CH_DESADDR,CH_FILLVAL,IRQ);
   
   initial begin
    clk = 0;
    resetn = 0;
 
 #10 resetn = 1;
 
 #10 data_in = 'h1234_5678_9abc_def0_1234_5678_9abc_def0_1234_5678_9abc_def0_1234_5678_1234_5678_1234_5678_1234_5678_1234_5678_1234_5678_1234_5678_1234_5678;
     
 AXIRDRESPERR = 0 ;
    AXIRDPOISERR = 0 ;
    AXIWRRESPERR = 0 ;
    BUSERR = 0 ;
    config_error = 0 ;
    regval_error = 0 ;
    SRCTRIGINSELERR = 0 ;
    DESTRIGINSELERR = 0 ;
    TRIGOUTSELERR = 0 ;
    AXIRDRESPERR_CMDFSM = 0 ;
    AXIRDPOISERR_CMDFSM = 0 ;
    BUSERR_CMDFSM = 0 ;
    LINKHDERR = 0 ;
    STAT_TRIGOUTACKWAIT = 0 ;
    STAT_DESTRIGINWAIT = 0 ;
    STAT_SRCTRIGINWAIT = 0 ;
    STAT_RESUMEWAIT = 0 ;
    STAT_STOPPED = 0 ;
    STAT_PAUSED = 0 ;
    STAT_DISABLED = 0 ;
    STAT_ERR = 0 ;
    STAT_DONE  = 0;
    
    
    #30 AXIWRRESPERR = 1 ;
    
    #50 STAT_ERR = 1;
    
    #500;
    
    end
 
    
    
endmodule
 

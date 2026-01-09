module internal_reg #(parameter WIDTH = 32,
      parameter DEPTH = 145)
 (
 input wire clk,resetn,
 //input wire wr_en,
 input wire [(WIDTH * 14) -1:0] data_in,
 
 //error signals from data fsm
 input wire AXIRDRESPERR,
 input wire AXIRDPOISERR,
 input wire AXIWRRESPERR,
 input wire BUSERR,
 input wire config_error,
 input wire regval_error,
 // from trigger
 input wire SRCTRIGINSELERR,
 input wire DESTRIGINSELERR,
 input wire TRIGOUTSELERR,
 // from cmd fsm
 input wire AXIRDRESPERR_CMDFSM,
 input wire AXIRDPOISERR_CMDFSM,
 input wire BUSERR_CMDFSM,
 input wire LINKHDERR,
 
 input wire STAT_TRIGOUTACKWAIT,
 input wire STAT_DESTRIGINWAIT,
 input wire STAT_SRCTRIGINWAIT,
 input wire STAT_RESUMEWAIT,
 input wire STAT_STOPPED,
 input wire STAT_PAUSED,
 input wire STAT_DISABLED,
 input wire STAT_ERR,
 input wire STAT_DONE,
 
 
 // to reg bank
 output wire [(WIDTH*2)-1 : 0] chn_reg_out,
 // to partselect module
 output  wire [31:0] CH_CTRL_O,
 output  wire [31:0] CH_INTREN_O,
 output  wire [31:0] CH_XSIZE_O,
 output  wire [31:0] CH_LINKADDR_O,
 output  wire [31:0] CH_CMD_O,
 output  wire [31:0] CH_STATUS_O,
 output  wire [31:0] CH_XADDRINC_O,
 output  wire [31:0] CH_SRCTRANSCFG_O,
 output  wire [31:0] CH_DESTRANSCFG_O,
 output  wire [31:0] CH_SRCTRIGINCFG_O,
 output  wire [31:0] CH_DESTRIGINCFG_O,
 output  wire [31:0] CH_TRIGOUTCFG_O,
 output  wire [31:0] CH_SRCADDR_O,
 output  wire [31:0] CH_DESADDR_O,
 output  wire [31:0] CH_FILLVAL_O,
 output  wire IRQ
 
 
 );
 integer i;
 wire INTR_TRIGOUTACKWAIT;
 wire INTR_DESTRIGINWAIT;
 wire INTR_SRCTRIGINWAIT;
 wire INTR_STOPPED;
 wire INTR_DISABLED;
 wire INTR_ERR;
 wire INTR_DONE;
 
 reg [ WIDTH-1:0 ] intr_mem [ 0:DEPTH-1 ];
 
 assign INTR_TRIGOUTACKWAIT = (STAT_TRIGOUTACKWAIT && intr_mem[8][10]);
 assign INTR_DESTRIGINWAIT = (STAT_DESTRIGINWAIT && intr_mem [8][9]);
 assign INTR_SRCTRIGINWAIT = (STAT_SRCTRIGINWAIT && intr_mem [8][8]);
 assign INTR_STOPPED = (STAT_STOPPED && intr_mem [8][3]);
 assign INTR_DISABLED = (STAT_DISABLED && intr_mem [8][2]);
 assign INTR_ERR = (STAT_ERR && intr_mem [8][1]);
 assign INTR_DONE = (STAT_DONE && intr_mem [8][0]);
 assign IRQ = (INTR_DISABLED || INTR_STOPPED || INTR_ERR || INTR_DONE);
 
 assign chn_reg_out = {intr_mem[4],intr_mem[144]};// error,status and 

 assign CH_CMD_O = intr_mem [0];
 assign CH_STATUS_O = intr_mem[4];
 assign CH_INTREN_O = intr_mem [8];
 assign CH_CTRL_O = intr_mem [12];
 assign CH_SRCADDR_O = intr_mem [16];
 assign CH_DESADDR_O = intr_mem [24];
 assign CH_XSIZE_O = intr_mem [32];
 assign CH_SRCTRANSCFG_O = intr_mem [40];
 assign CH_DESTRANSCFG_O = intr_mem [44];
 assign CH_XADDRINC_O = intr_mem [48];
 assign CH_FILLVAL_O = intr_mem [56];
 assign CH_SRCTRIGINCFG_O = intr_mem [76];
 assign CH_DESTRIGINCFG_O = intr_mem [80];
 assign CH_TRIGOUTCFG_O = intr_mem [84];
 assign CH_LINKADDR_O = intr_mem [120];

 
 
 always @(posedge clk or negedge resetn) 
 begin
  if(!resetn)
  for(i = 0;i<DEPTH;i=i+1)
   intr_mem [i] <= 'd0;
  else
   begin
   //if(wr_en)
   //{intr_mem[0],intr_mem[8],intr_mem[12],intr_mem[16],intr_mem[24],intr_mem[32],intr_mem[40],intr_mem[44],
   //intr_mem[48],intr_mem[56],intr_mem[76],intr_mem[80],intr_mem[84],intr_mem[120]} <= data_in;
   
   intr_mem[0] <= data_in [(WIDTH * 1) -1 : 0];
   intr_mem[8] <= data_in [(WIDTH * 2) -1 : (WIDTH*1)];
   intr_mem[12] <= data_in [(WIDTH * 3) -1 : (WIDTH*2)];
   intr_mem[16] <= data_in [(WIDTH * 4) -1 : (WIDTH*3)];
   intr_mem[24] <= data_in [(WIDTH * 5) -1 : (WIDTH*4)];
   intr_mem[32] <= data_in [(WIDTH * 6) -1 : (WIDTH*5)];
   intr_mem[40] <= data_in [(WIDTH * 7) -1 : (WIDTH*6)];
   intr_mem[44] <= data_in [(WIDTH * 8) -1 : (WIDTH*7)];
   intr_mem[48] <= data_in [(WIDTH * 9) -1 : (WIDTH*8)];
   intr_mem[56] <= data_in [(WIDTH * 10) -1 : (WIDTH*9)];
   intr_mem[76] <= data_in [(WIDTH * 11) -1 : (WIDTH*10)];
   intr_mem[80] <= data_in [(WIDTH * 12) -1 : (WIDTH*11)];
   intr_mem[84] <= data_in [(WIDTH * 13) -1 : (WIDTH*12)];
   intr_mem[120] <= data_in [(WIDTH * 14) -1 : (WIDTH*13)];
   
   intr_mem[144] <= {6'd0,regval_error,LINKHDERR,6'd0,{AXIRDPOISERR|AXIRDPOISERR_CMDFSM},{AXIRDRESPERR|AXIRDRESPERR_CMDFSM},AXIWRRESPERR,11'd0,
         TRIGOUTSELERR,DESTRIGINSELERR,SRCTRIGINSELERR,config_error,{BUSERR|BUSERR_CMDFSM}};
   
   intr_mem[4] <= {5'd0,STAT_TRIGOUTACKWAIT,STAT_DESTRIGINWAIT,STAT_SRCTRIGINWAIT,2'd0,STAT_RESUMEWAIT,STAT_PAUSED,STAT_STOPPED,
       STAT_DISABLED,STAT_ERR,STAT_DONE,5'd0,INTR_TRIGOUTACKWAIT,INTR_DESTRIGINWAIT,INTR_SRCTRIGINWAIT,4'd0,
       INTR_STOPPED,INTR_DISABLED,INTR_ERR,INTR_DONE};
   
   end
 end
   
   

endmodule 

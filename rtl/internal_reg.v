module internal_reg #(parameter WIDTH = 32,
      parameter DEPTH = 145)
 (
 input wire clk,resetn,
 //input wire wr_en,
 input wire [(WIDTH * 15) -1:0] data_in,
 
 //
     input wire [31:0] SRCADDR_UPDATED,
    input wire [31:0]  DESADDR_UPDATED,
    input wire [31:0]  XSIZE_UPDATED,
    input wire  wr_en_for_updated,
    input wire STAT_CMD_DONE,
    
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
 
 input wire STAT_TRIGOUTACKWAIT_DATA,
 input wire STAT_DESTRIGINWAIT_DATA,
 input wire STAT_SRCTRIGINWAIT_DATA,
 input wire STAT_RESUMEWAIT_DATA,
 input wire STAT_STOPPED_DATA,
 input wire STAT_PAUSED_DATA,
 input wire STAT_DISABLED_DATA,
 input wire STAT_DONE_DATA,
 
 input wire ENABLECMD_DATA,
 input wire DISABLECMD_DATA,
 input wire STOPCMD_DATA,
 
 
 
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
 output  wire IRQ,
output wire stat_done_intr_reg,//data fsm
output wire stat_disable_intr_reg ,
output wire stat_stopped_intr_reg ,
output wire  stat_err_intr_reg,
output wire [(WIDTH*3)-1 : 0] src_des_xsize_updated,
 
 output  wire reg_wr_en,
 output wire [31:0] wrkregval_rd,
 input wire [31:0] cfg_WRKREGPTR,
 input wire [31:0] SRCADDR_INITIAL,
 input wire [31:0] DESADDR_INITIAL,
 input wire [31:0] SRCXSIZE_INITIAL,
 input wire [31:0] DESXSIZE_INITIAL//inputs from data fsm
 );
 
 integer i;
 wire INTR_TRIGOUTACKWAIT;
 wire INTR_DESTRIGINWAIT;
 wire INTR_SRCTRIGINWAIT;
 wire INTR_STOPPED;
 wire INTR_DISABLED;
 wire INTR_ERR;
 wire INTR_DONE;
 
 reg [31:0] WRKREGVAL_temp;
 
 wire STAT_ERR = AXIRDRESPERR| AXIRDPOISERR | AXIWRRESPERR| BUSERR |
                 config_error| regval_error | SRCTRIGINSELERR| DESTRIGINSELERR 
                 | TRIGOUTSELERR | AXIRDRESPERR_CMDFSM | AXIRDPOISERR_CMDFSM |  
                 BUSERR_CMDFSM |  LINKHDERR;
 
   assign stat_disable_intr_reg = data_in [50] ?1'b0 : STAT_DISABLED_DATA;
   assign stat_stopped_intr_reg = data_in [51]? 1'b0: STAT_STOPPED_DATA;
  // wire stat_done = IRQ ? data_in [48] : STAT_DONE;
  assign stat_done_intr_reg = data_in [48] ? 1'b0  : STAT_DONE_DATA;//?1:stat_done;
  assign stat_err_intr_reg = data_in [49] ? 1'b0  : STAT_ERR;
  // wire  stat_done_reg  = data_in [48];
   //assign stat_disable_reg = data_in [50];
 //  wire stat_stopped_reg = data_in [51];
 //  wire stat_err_reg = data_in [49]; //== 1 )? 0 :1 ;//stat_err;
   
   
   wire stopcmd = STOPCMD_DATA ? 0 :data_in [3]? 1: stopcmd; //STOPCMD : data_in [3];
   wire disablecmd = DISABLECMD_DATA ? 0 : data_in [2]? 1: disablecmd;
   wire enablecmd =ENABLECMD_DATA ?  0 : data_in [0] ?1: enablecmd;
   wire pausecmd =  STAT_PAUSED_DATA   ? 0 :data_in [4] ?1: pausecmd;
   wire resumecmd =  !STAT_PAUSED_DATA   ? 0 :data_in [5] ?1: resumecmd;
   
 reg [ WIDTH-1:0 ] intr_mem [ 0:DEPTH-1 ];
 //reg [31:0 ] intr_mem_regval [ 0:15 ]; //wrkregval

 
 assign INTR_TRIGOUTACKWAIT = (STAT_TRIGOUTACKWAIT_DATA && intr_mem[8][10]);
 assign INTR_DESTRIGINWAIT = (STAT_DESTRIGINWAIT_DATA && intr_mem [8][9]);
 assign INTR_SRCTRIGINWAIT = (STAT_SRCTRIGINWAIT_DATA && intr_mem [8][8]);
 assign INTR_STOPPED = (stat_stopped_intr_reg && intr_mem [8][3]);
 assign INTR_DISABLED = (stat_disable_intr_reg && intr_mem [8][2]);
 assign INTR_ERR = (stat_err_intr_reg && intr_mem [8][1]);
 assign INTR_DONE = (stat_done_intr_reg && intr_mem [8][0]);
 assign IRQ = (INTR_DISABLED | INTR_STOPPED | INTR_ERR | INTR_DONE);
 
 //to reg bank
 assign reg_wr_en = IRQ  ? 1: 0;
 assign chn_reg_out = {intr_mem[4],intr_mem[144]};// error,status 
assign src_des_xsize_updated = {intr_mem[16],intr_mem[24],intr_mem[32]};
 assign wrkregval_rd = intr_mem[140];
 
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

 
 always @(*)
 begin
 case(cfg_WRKREGPTR)
 'd1:WRKREGVAL_temp = SRCADDR_INITIAL;
 'd3:WRKREGVAL_temp = DESADDR_INITIAL;
 'd5:WRKREGVAL_temp = SRCXSIZE_INITIAL;
 'd6:WRKREGVAL_temp = DESXSIZE_INITIAL;
 default:WRKREGVAL_temp = 'd0;
 endcase
 end
 
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
   
   intr_mem[0] <= {data_in [31:6],resumecmd,pausecmd,stopcmd,disablecmd,data_in[1],enablecmd};
   intr_mem[8]  <= data_in [(WIDTH * 3) -1 : (WIDTH*2)];
   intr_mem[12] <= data_in [(WIDTH * 4) -1 : (WIDTH*3)];
   intr_mem[16] <=data_in [(WIDTH * 5) -1 : (WIDTH*4)];
    intr_mem[24] <=  data_in [(WIDTH * 6) -1 : (WIDTH*5)];//
   //intr_mem[16] <= wr_en_for_updated ? SRCADDR_UPDATED : data_in [(WIDTH * 5) -1 : (WIDTH*4)];//
  // intr_mem[24] <=  wr_en_for_updated ? DESADDR_UPDATED : data_in [(WIDTH * 6) -1 : (WIDTH*5)];//
  //  intr_mem[32] <=  wr_en_for_updated ? XSIZE_UPDATED :  data_in [(WIDTH * 7) -1 : (WIDTH*6)];//
   //intr_mem[32] <=  wr_en_for_updated ? XSIZE_UPDATED : STAT_CMD_DONE? data_in [(WIDTH * 7) -1 : (WIDTH*6)]:intr_mem[32] ;//
   intr_mem[32] <=data_in [(WIDTH * 7) -1 : (WIDTH*6)];
   intr_mem[40] <= data_in [(WIDTH * 8) -1 : (WIDTH*7)];
   intr_mem[44] <= data_in [(WIDTH * 9) -1 : (WIDTH*8)];
   intr_mem[48] <= data_in [(WIDTH * 10) -1 : (WIDTH*9)];
   intr_mem[56] <= data_in [(WIDTH * 11) -1 : (WIDTH*10)];
   intr_mem[76] <= data_in [(WIDTH * 12) -1 : (WIDTH*11)];
   intr_mem[80] <= data_in [(WIDTH * 13) -1 : (WIDTH*12)];
   intr_mem[84] <= data_in [(WIDTH * 14) -1 : (WIDTH*13)];
   intr_mem[120]<= data_in [(WIDTH * 15) -1 : (WIDTH*14)];
   
   intr_mem[144] <= {6'd0,regval_error,LINKHDERR,6'd0,{AXIRDPOISERR|AXIRDPOISERR_CMDFSM},{AXIRDRESPERR|AXIRDRESPERR_CMDFSM},AXIWRRESPERR,11'd0,
         TRIGOUTSELERR,DESTRIGINSELERR,SRCTRIGINSELERR,config_error,{BUSERR|BUSERR_CMDFSM}};
   
   intr_mem[4] <= {5'd0,STAT_TRIGOUTACKWAIT_DATA,STAT_DESTRIGINWAIT_DATA,STAT_SRCTRIGINWAIT_DATA,2'd0,STAT_RESUMEWAIT_DATA,STAT_PAUSED_DATA,stat_stopped_intr_reg,
       stat_disable_intr_reg,stat_err_intr_reg,stat_done_intr_reg,5'd0,INTR_TRIGOUTACKWAIT,INTR_DESTRIGINWAIT,INTR_SRCTRIGINWAIT,4'd0,
       INTR_STOPPED,INTR_DISABLED,INTR_ERR,INTR_DONE};
       
       intr_mem[136] <= cfg_WRKREGPTR;
       intr_mem[140] <= WRKREGVAL_temp;
    
   
   end
 end
   
endmodule 

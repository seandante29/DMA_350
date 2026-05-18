module internal_reg #(parameter WIDTH = 32,
      parameter DEPTH = 145)
 (
 input wire clk,resetn,
 //input wire wr_en,
 input wire [(WIDTH * 21) -1:0] data_in,
 
 //
//     input wire [31:0] read_base_addr_UPDATED,
//    input wire [31:0]  write_base_addr_UPDATED,
//    input wire [31:0]  x_transfer_count_UPDATED,y_transfer_count_UPDATED,
    //input wire  wr_en_for_updated,
    //input wire STAT_CMD_DONE,
    
    input wire boot_en,
      input wire [29:0] boot_addr,
    
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
 input wire SWTRIGOUTACK_DATA,SRCSWTRIGINREQ_DATA ,DESSWTRIGINREQ_DATA,
 
 
 // to reg bank
 output wire [(WIDTH*18)-1 : 0] chn_reg_out,
 // to partselect module
 output  wire [31:0] control_config_O,
 output  wire [31:0] interrupt_enable_O,
 output  wire [31:0] x_transfer_count_O,
 output  wire [31:0] CH_next_cmd_addr_O,
 output  wire [31:0] channel_start_O,
 output  wire [31:0] channel_status_O,
 output  wire [31:0] addr_increment_cfg_O,
 output  wire [31:0] read_transfer_cfg_O,
 output  wire [31:0] write_transfer_cfg_O,
 output  wire [31:0] read_trigger_cfg_O,
 output  wire [31:0] write_trigger_cfg_O,
 output  wire [31:0] trigger_out_cfg_O,
 output  wire [31:0] read_base_addr_O,
 output  wire [31:0] write_base_addr_O,
 output  wire [31:0] fill_data_O,
 output wire [31:0] template_config_O,
 output wire [31:0] read_template_data_O,
 output wire [31:0] write_template_data_O,
 output wire [31:0] auto_restart_config_O,
 output wire deassert_stat_done,
 output wire [31:0] line_stride_O,
 output wire [31:0] y_transfer_count_O,
 output  wire IRQ,
output wire stat_done_intr_reg,//data fsm
output wire stat_disable_intr_reg ,
output wire stat_stopped_intr_reg ,
output wire  stat_err_intr_reg,
output wire [(WIDTH*3)-1 : 0] src_des_x_transfer_count_updated,
//output reg rst_posedge,
 
 output  wire reg_wr_en,
 output wire [31:0] wrkregval_rd,
 input wire [31:0] cfg_work_reg_pointer,
 input wire [31:0] read_base_addr_INITIAL,read_base_addr_LINEINITIAL,
 input wire [31:0] write_base_addr_INITIAL,write_base_addr_LINEINITIAL,
 input wire [31:0] SRCx_transfer_count_INITIAL,DESy_transfer_count_INITIAL,
 input wire [31:0] DESx_transfer_count_INITIAL,SRCy_transfer_count_INITIAL//inputs from data fsm
 );
 
 integer i;
 wire INTR_TRIGOUTACKWAIT;
 wire INTR_DESTRIGINWAIT;
 wire INTR_SRCTRIGINWAIT;
 wire INTR_STOPPED;
 wire INTR_DISABLED;
 wire INTR_ERR;
 wire INTR_DONE;
 reg data_in_0_1 ;
    
 reg [ WIDTH-1:0 ] intr_mem [ 0:DEPTH-1 ];
 reg [31:0] WRKREGVAL_temp;
      
  wire regval_err_reserved_bits = ( (|intr_mem[0][31:25]) | (intr_mem[0][23]) | intr_mem[0][19] | (|intr_mem[0][15:6]) 
        | (|intr_mem[4][31:27]) | (|intr_mem[4][23:22]) | (|intr_mem[4][15:11]) | (|intr_mem[4][7:4])
        | (|intr_mem[8][31:11]) | (|intr_mem[8][7:4])
        | (|intr_mem[12][31:30]) | (|intr_mem[12][17:15]) | (intr_mem[12][8]) | (|intr_mem[12][3]) 
        | (|intr_mem[40][31:20]) | (|intr_mem[40][15:12]) 
        | (|intr_mem[44][31:20]) | (|intr_mem[44][15:12])
        | (|intr_mem[76][31:24]) | (|intr_mem[76][15:12])
        | (|intr_mem[80][31:24]) | (|intr_mem[80][15:12])
        | (|intr_mem[84][31:10]) | (|intr_mem[84][7:6])
        | (intr_mem[120][1])
        | (|intr_mem[136][31:4])
        | (|intr_mem[144][15:8]) | (|intr_mem[144][6:5]) );
      
 wire STAT_ERR = AXIRDRESPERR| AXIRDPOISERR | AXIWRRESPERR|  BUSERR |
                 config_error| regval_error | SRCTRIGINSELERR| DESTRIGINSELERR 
                 | TRIGOUTSELERR | AXIRDRESPERR_CMDFSM | AXIRDPOISERR_CMDFSM |  
                 BUSERR_CMDFSM |  LINKHDERR | regval_err_reserved_bits;
 
   assign stat_disable_intr_reg = data_in [50]| data_in[0] ?1'b0 : STAT_DISABLED_DATA;
   assign stat_stopped_intr_reg = (data_in [3] && data_in[0])?  STAT_STOPPED_DATA : (data_in [51]| data_in[0]) ? 0 :STAT_STOPPED_DATA ;
  assign stat_done_intr_reg = data_in [48] | data_in[0] ? 1'b0  : STAT_DONE_DATA;
  assign stat_err_intr_reg = data_in [49] | data_in[0] ? 1'b0  : STAT_ERR;
  assign deassert_stat_done = data_in [48] | data_in[0];
   
   reg stopcmd,disablecmd,enablecmd,pausecmd,resumecmd,swtrigoutack,srcswtriginreq,desswtriginreq; 
// reg resetn_d;
//wire resetn_posedge;
//reg resetn_posedge_1;
//always @(posedge clk) begin
//    if(!resetn)begin
//    resetn_d <= 0;
//    resetn_posedge_1 <= 0;
//    end
    
//    else begin
//    resetn_d <= resetn;
//    resetn_posedge_1 <= resetn_posedge;end
//end

//assign resetn_posedge = resetn & ~resetn_d;
 
 
 reg resetn_d;
reg resetn_posedge;

always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
        resetn_d       <= 1'b0;
        resetn_posedge <= 1'b0;
       // rst_posedge <= 0;
    end
    else begin
        resetn_posedge <= resetn & ~resetn_d;
        resetn_d       <= resetn;
        //rst_posedge <= resetn_posedge;
    end
end


 assign INTR_TRIGOUTACKWAIT = (STAT_TRIGOUTACKWAIT_DATA && intr_mem[8][10]);
 assign INTR_DESTRIGINWAIT = (STAT_DESTRIGINWAIT_DATA && intr_mem [8][9]);
 assign INTR_SRCTRIGINWAIT = (STAT_SRCTRIGINWAIT_DATA && intr_mem [8][8]);
 assign INTR_STOPPED = (stat_stopped_intr_reg && intr_mem [8][3]);
 assign INTR_DISABLED = (stat_disable_intr_reg && intr_mem [8][2]);
 assign INTR_ERR = (stat_err_intr_reg && intr_mem [8][1]);
 assign INTR_DONE = (stat_done_intr_reg && intr_mem [8][0]);
 assign IRQ = (INTR_DISABLED | INTR_STOPPED | INTR_ERR | INTR_DONE |INTR_TRIGOUTACKWAIT | INTR_DESTRIGINWAIT | INTR_SRCTRIGINWAIT);
 
 //to reg bank
 assign reg_wr_en = IRQ  ? 1: 0;
 assign chn_reg_out = {intr_mem[0],intr_mem[4],intr_mem[12],intr_mem[40],intr_mem[44],intr_mem[48],intr_mem[56],
 intr_mem[64],intr_mem[68],intr_mem[72],intr_mem[76],intr_mem[80],intr_mem[84],intr_mem[116],intr_mem[120],intr_mem[144],intr_mem[52],intr_mem[60]};// error,status 
assign src_des_x_transfer_count_updated = {intr_mem[16],intr_mem[24],intr_mem[32]};
 assign wrkregval_rd = intr_mem[140];
 
 assign channel_start_O = intr_mem [0];
 assign channel_status_O = intr_mem[4];
 assign interrupt_enable_O = intr_mem [8];
 assign control_config_O = intr_mem [12];
 assign read_base_addr_O = intr_mem [16];
 assign write_base_addr_O = intr_mem [24];
 assign x_transfer_count_O = intr_mem [32];
 assign read_transfer_cfg_O = intr_mem [40];
 assign write_transfer_cfg_O = intr_mem [44];
 assign addr_increment_cfg_O = intr_mem [48];
 assign fill_data_O = intr_mem [56];
 assign write_template_data_O = intr_mem[72];
 assign read_template_data_O = intr_mem[68];
 assign template_config_O = intr_mem[64];
 assign read_trigger_cfg_O = intr_mem [76];
 assign write_trigger_cfg_O = intr_mem [80];
 assign auto_restart_config_O = intr_mem [116];
 assign trigger_out_cfg_O = intr_mem [84];
 assign CH_next_cmd_addr_O = intr_mem [120];
 assign line_stride_O = intr_mem [52];
 assign y_transfer_count_O = intr_mem [60];

 
 always @(*)
 begin
 case(cfg_work_reg_pointer)
 'd1:WRKREGVAL_temp = read_base_addr_INITIAL;
 'd3:WRKREGVAL_temp = write_base_addr_INITIAL;
 'd5:WRKREGVAL_temp = SRCx_transfer_count_INITIAL;
 'd6:WRKREGVAL_temp = DESx_transfer_count_INITIAL;
 'd7:WRKREGVAL_temp = read_base_addr_LINEINITIAL;
 'd9:WRKREGVAL_temp = write_base_addr_LINEINITIAL;
 'd11:WRKREGVAL_temp = SRCy_transfer_count_INITIAL;
 'd12:WRKREGVAL_temp = DESy_transfer_count_INITIAL;
 default:WRKREGVAL_temp = 'd0;
 endcase
 end
 
 always @(posedge clk or negedge resetn) 
 begin

        if(!resetn)begin
            data_in_0_1<= 0;
            for(i = 0;i<DEPTH;i=i+1)
                intr_mem [i] <= 'd0;
            {stopcmd,disablecmd,enablecmd,pausecmd,resumecmd,swtrigoutack,srcswtriginreq,desswtriginreq} <= 'd0;
        end
  
    
  else
   begin
   //if(wr_en)
   //{intr_mem[0],intr_mem[8],intr_mem[12],intr_mem[16],intr_mem[24],intr_mem[32],intr_mem[40],intr_mem[44],
   //intr_mem[48],intr_mem[56],intr_mem[76],intr_mem[80],intr_mem[84],intr_mem[120]} <= data_in;
    data_in_0_1 <= data_in [0];
            stopcmd <= STOPCMD_DATA ? 0 :(data_in [3] && enablecmd)? 1: stopcmd; 
            disablecmd <= DISABLECMD_DATA ? 0 : (data_in [2] && enablecmd)? 1: disablecmd;
            enablecmd <= (((data_in [0]|data_in_0_1 )&& !enablecmd) || (boot_en && resetn_posedge) ) ?  1 : (ENABLECMD_DATA||/*stat_done_intr_reg||*/stat_err_intr_reg)  ? 0 : enablecmd;// for autoboot pg no - 100 trm
            pausecmd <=  STAT_PAUSED_DATA   ? 0 : (data_in [4] && enablecmd) ?1: pausecmd;
            resumecmd <=  !STAT_PAUSED_DATA   ? 0 :data_in [5] ?1: resumecmd;
            swtrigoutack <= SWTRIGOUTACK_DATA ? 0 : (( data_in [0] || enablecmd ) && data_in[24]) ? 1 :swtrigoutack;
            srcswtriginreq <= SRCSWTRIGINREQ_DATA ? 0 : (( data_in [0] || enablecmd ) && data_in[16]) ? 1 :srcswtriginreq;
            desswtriginreq <= DESSWTRIGINREQ_DATA ? 0 : (( data_in [0] || enablecmd ) && data_in[20]) ? 1 :desswtriginreq;

   intr_mem[0] <= {data_in [31:25],swtrigoutack,data_in [23:21],desswtriginreq,data_in [19:17],srcswtriginreq,data_in [15:6],resumecmd,pausecmd,stopcmd,disablecmd,data_in[1],enablecmd};
   intr_mem[8]  <= data_in [(WIDTH * 3) -1 : (WIDTH*2)];
   intr_mem[12] <= data_in [(WIDTH * 4) -1 : (WIDTH*3)];
   intr_mem[16] <=data_in [(WIDTH * 5) -1 : (WIDTH*4)];
    intr_mem[24] <=  data_in [(WIDTH * 6) -1 : (WIDTH*5)];//
   //intr_mem[16] <= wr_en_for_updated ? read_base_addr_UPDATED : data_in [(WIDTH * 5) -1 : (WIDTH*4)];//
  // intr_mem[24] <=  wr_en_for_updated ? write_base_addr_UPDATED : data_in [(WIDTH * 6) -1 : (WIDTH*5)];//
  //  intr_mem[32] <=  wr_en_for_updated ? x_transfer_count_UPDATED :  data_in [(WIDTH * 7) -1 : (WIDTH*6)];//
   //intr_mem[32] <=  wr_en_for_updated ? x_transfer_count_UPDATED : STAT_CMD_DONE? data_in [(WIDTH * 7) -1 : (WIDTH*6)]:intr_mem[32] ;//
   intr_mem[32] <=data_in [(WIDTH * 7) -1 : (WIDTH*6)];
   intr_mem[40] <= data_in [(WIDTH * 8) -1 : (WIDTH*7)];
   intr_mem[44] <= data_in [(WIDTH * 9) -1 : (WIDTH*8)];
   intr_mem[48] <= data_in [(WIDTH * 10) -1 : (WIDTH*9)];
   intr_mem[56] <= data_in [(WIDTH * 11) -1 : (WIDTH*10)];
   intr_mem [64]<= data_in [(WIDTH * 12) -1 : (WIDTH*11)];
   intr_mem[68]<=data_in [(WIDTH * 13) -1 : (WIDTH*12)];
   intr_mem[72]<=data_in [(WIDTH * 14) -1 : (WIDTH*13)];
   intr_mem[76] <= data_in [(WIDTH * 15) -1 : (WIDTH*14)];
   intr_mem[80] <= data_in [(WIDTH * 16) -1 : (WIDTH*15)];
   intr_mem[84] <= data_in [(WIDTH * 17) -1 : (WIDTH*16)];
   intr_mem[116] <= data_in [(WIDTH * 18) -1 : (WIDTH*17)];
   intr_mem[120]<= (resetn_posedge && boot_en) ? {boot_addr,1'b0,boot_en}:data_in [(WIDTH * 19) -1 : (WIDTH*18)];
   intr_mem [52]<= data_in [(WIDTH * 20) -1 : (WIDTH*19)];
   intr_mem [60]<= data_in [(WIDTH * 21) -1 : (WIDTH*20)];
         intr_mem[144] <= {6'd0,(regval_error | config_error| regval_err_reserved_bits),LINKHDERR,5'd0,{AXIRDPOISERR|AXIRDPOISERR_CMDFSM},AXIWRRESPERR,{AXIRDRESPERR|AXIRDRESPERR_CMDFSM},11'd0,
         TRIGOUTSELERR,DESTRIGINSELERR,SRCTRIGINSELERR,(config_error|LINKHDERR| regval_err_reserved_bits),{BUSERR|BUSERR_CMDFSM}};
   
   intr_mem[4] <= {5'd0,STAT_TRIGOUTACKWAIT_DATA,STAT_DESTRIGINWAIT_DATA,STAT_SRCTRIGINWAIT_DATA,2'd0,STAT_RESUMEWAIT_DATA,STAT_PAUSED_DATA,stat_stopped_intr_reg,
       stat_disable_intr_reg,stat_err_intr_reg,stat_done_intr_reg,5'd0,INTR_TRIGOUTACKWAIT,INTR_DESTRIGINWAIT,INTR_SRCTRIGINWAIT,4'd0,
       INTR_STOPPED,INTR_DISABLED,INTR_ERR,INTR_DONE};
       
       intr_mem[136] <= cfg_work_reg_pointer;
       intr_mem[140] <= WRKREGVAL_temp;
    
   
   end
 end
   
endmodule 
 

module internal_reg #(
    parameter WIDTH = 32,
    parameter DEPTH = 145)
    (
    input wire clk,resetn,
    input wire [(WIDTH * 15) -1:0] data_in,
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
    output wire [(WIDTH*12)-1 : 0] chn_reg_out,
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
    reg stopcmd,disablecmd,enablecmd,pausecmd,resumecmd;
    reg data_in_0_1 ;
    reg [ WIDTH-1:0 ] intr_mem [ 0:DEPTH-1 ];
    
    wire regval_err_reserved_bits = ( (|intr_mem[0][31:25]) | (intr_mem[0][23]) | intr_mem[0][19] | (|intr_mem[0][15:6]) 
        | (|intr_mem[4][31:27]) | (|intr_mem[4][23:22]) | (|intr_mem[4][15:11]) | (|intr_mem[4][7:4])
        | (|intr_mem[8][31:11]) | (|intr_mem[8][7:4])
        | (|intr_mem[12][31:30]) | (|intr_mem[12][17:15]) | (intr_mem[12][8]) | (|intr_mem[12][3]) 
        | (|intr_mem[40][31:20]) | (|intr_mem[40][15:12]) 
        | (intr_mem[44][31:20]) | (|intr_mem[44][15:12])
        | (|intr_mem[76][31:24]) | (|intr_mem[76][15:12])
        | (|intr_mem[80][31:24]) | (|intr_mem[80][15:12])
        | (|intr_mem[84][31:10]) | (|intr_mem[84][7:6])
        | (intr_mem[120][1])
        | (|intr_mem[136][31:4])
        | (|intr_mem[144][15:8]) | (|intr_mem[144][6:5]) );
    
    wire STAT_ERR = (AXIRDRESPERR| AXIRDPOISERR | AXIWRRESPERR| BUSERR |
                    config_error| regval_error | SRCTRIGINSELERR| DESTRIGINSELERR 
                    | TRIGOUTSELERR | AXIRDRESPERR_CMDFSM | AXIRDPOISERR_CMDFSM |  
                    BUSERR_CMDFSM |  LINKHDERR | regval_err_reserved_bits) ;
    assign stat_disable_intr_reg = data_in [50]| data_in[0] ?1'b0 : STAT_DISABLED_DATA;
    assign stat_stopped_intr_reg = data_in [51]| data_in[0] ? 1'b0: STAT_STOPPED_DATA;
    assign stat_done_intr_reg = data_in [48] | data_in[0] ? 1'b0  : STAT_DONE_DATA;
    assign stat_err_intr_reg = data_in [49] | data_in[0] ? 1'b0  : STAT_ERR;
    assign INTR_TRIGOUTACKWAIT = (STAT_TRIGOUTACKWAIT_DATA && intr_mem[8][10]);
    assign INTR_DESTRIGINWAIT = (STAT_DESTRIGINWAIT_DATA && intr_mem [8][9]);
    assign INTR_SRCTRIGINWAIT = (STAT_SRCTRIGINWAIT_DATA && intr_mem [8][8]);
    assign INTR_STOPPED = (stat_stopped_intr_reg && intr_mem [8][3]);
    assign INTR_DISABLED = (stat_disable_intr_reg && intr_mem [8][2]);
    assign INTR_ERR = (stat_err_intr_reg && intr_mem [8][1]);
    assign INTR_DONE = (stat_done_intr_reg && intr_mem [8][0]);
    assign IRQ = (INTR_DISABLED | INTR_STOPPED | INTR_ERR | INTR_DONE);
    assign chn_reg_out = {intr_mem[0],intr_mem[4],intr_mem[12],intr_mem[40],intr_mem[44],intr_mem[48],intr_mem[56],intr_mem[76],intr_mem[80],intr_mem[84],intr_mem[120],intr_mem[144]};// error,status 
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
        if(!resetn)begin
            data_in_0_1<= 0;
            for(i = 0;i<DEPTH;i=i+1)
                intr_mem [i] <= 'd0;
            {stopcmd,disablecmd,enablecmd,pausecmd,resumecmd} <= 'd0;
        end
        else
        begin
            data_in_0_1 <= data_in [0];
            stopcmd <= STOPCMD_DATA ? 0 :data_in [3]? 1: stopcmd; 
            disablecmd <= DISABLECMD_DATA ? 0 : data_in [2]? 1: disablecmd;
            enablecmd <= data_in [0]|data_in_0_1 ?  1 : (ENABLECMD_DATA||stat_done_intr_reg||stat_err_intr_reg)  ? 0 : enablecmd;
            pausecmd <=  STAT_PAUSED_DATA   ? 0 :data_in [4] ?1: pausecmd;
            resumecmd <=  !STAT_PAUSED_DATA   ? 0 :data_in [5] ?1: resumecmd;
            intr_mem[0] <= {data_in [31:6],resumecmd,pausecmd,stopcmd,disablecmd,data_in[1],enablecmd};
            intr_mem[8]  <= data_in [(WIDTH * 3) -1 : (WIDTH*2)];
            intr_mem[12] <= data_in [(WIDTH * 4) -1 : (WIDTH*3)];
            intr_mem[16] <=data_in [(WIDTH * 5) -1 : (WIDTH*4)];
            intr_mem[24] <=  data_in [(WIDTH * 6) -1 : (WIDTH*5)];
            intr_mem[32] <=data_in [(WIDTH * 7) -1 : (WIDTH*6)];
            intr_mem[40] <= data_in [(WIDTH * 8) -1 : (WIDTH*7)];
            intr_mem[44] <= data_in [(WIDTH * 9) -1 : (WIDTH*8)];
            intr_mem[48] <= data_in [(WIDTH * 10) -1 : (WIDTH*9)];
            intr_mem[56] <= data_in [(WIDTH * 11) -1 : (WIDTH*10)];
            intr_mem[76] <= data_in [(WIDTH * 12) -1 : (WIDTH*11)];
            intr_mem[80] <= data_in [(WIDTH * 13) -1 : (WIDTH*12)];
            intr_mem[84] <= data_in [(WIDTH * 14) -1 : (WIDTH*13)];
            intr_mem[120]<= data_in [(WIDTH * 15) -1 : (WIDTH*14)];
            intr_mem[144] <= {6'd0,(regval_error | config_error| regval_err_reserved_bits) ,LINKHDERR,5'd0,{AXIRDPOISERR|AXIRDPOISERR_CMDFSM},AXIWRRESPERR,{AXIRDRESPERR|AXIRDRESPERR_CMDFSM},11'd0,
            TRIGOUTSELERR,DESTRIGINSELERR,SRCTRIGINSELERR,(config_error|LINKHDERR| regval_err_reserved_bits),{BUSERR|BUSERR_CMDFSM}};
            intr_mem[4] <= {5'd0,STAT_TRIGOUTACKWAIT_DATA,STAT_DESTRIGINWAIT_DATA,STAT_SRCTRIGINWAIT_DATA,2'd0,STAT_RESUMEWAIT_DATA,STAT_PAUSED_DATA,stat_stopped_intr_reg,
            stat_disable_intr_reg,stat_err_intr_reg,stat_done_intr_reg,5'd0,INTR_TRIGOUTACKWAIT,INTR_DESTRIGINWAIT,INTR_SRCTRIGINWAIT,4'd0,
            INTR_STOPPED,INTR_DISABLED,INTR_ERR,INTR_DONE};
            intr_mem[136] <= cfg_WRKREGPTR;
            intr_mem[140] <= WRKREGVAL_temp;
        end
    end
    
endmodule 

`timescale 1ns/1ps
module data_fsm_tb();

parameter ADDR_W = 32;
parameter DATA_W = 128;
parameter ID_W   = 4;

// --------------------------------------------------
// Clock & Reset
// --------------------------------------------------
reg clk;
reg resetn;

// --------------------------------------------------
// INPUTS (declare as reg)
// --------------------------------------------------

reg stat_error_intr_reg;
reg stat_done_intr_reg;
reg link_en;
reg LINKHDERR;

reg enable_cmd_partsel;
reg pause_cmd_partsel;
reg resume_cmd_partsel;
reg disable_cmd_partsel;
reg stop_cmd_partsel;
reg stat_disable_intr_reg;
reg stat_stop_intr_reg;
reg cmd_done;

reg use_src_trigin;
reg [1:0] src_trigin_type;
reg [1:0] src_trigin_mode;
reg [7:0] src_trigin_blk_size;
reg [7:0] src_trigin_sel;

reg use_des_trigin;
reg [1:0] des_trigin_type;
reg [1:0] des_trigin_mode;
reg [7:0] des_trigin_blk_size;
reg [7:0] des_trigin_sel;

reg use_trigout;
reg [1:0] trigout_type;
reg [5:0] trigout_sel;

reg src_trigin_sw;
reg des_trigin_sw;
reg trig_out_ack_sw;
reg src_trigin;
reg des_trigin;
reg trig_out_ack;

reg [1:0] des_trig_req_type;
reg [1:0] src_trig_req_type;
reg [ADDR_W-1:0] SRC_ADDR;
reg [ADDR_W-1:0] des_ADDR;
reg [2:0]        transize;
reg [15:0]       srcxsize;
reg [15:0]       desxsize;
reg [2:0]        x_type;
reg [31:0]       fillval;
reg [15:0]       src_xaddr_inc;
reg [15:0]       des_xaddr_inc;
reg [3:0]        src_max_burst_len;
reg [3:0]        des_max_burst_len;


//2d

reg [15:0] src_yaddr_stride,des_yaddr_stride;
reg [15:0] desysize,srcysize;
reg [2:0] y_type;

reg stop_cmd_apb;
reg [1:0] src_trigin_sw_type,des_trigin_sw_type;
reg cmd_restart_en;
reg cmd_restart_cnt;
reg [2:0] reg_reload_type;
reg [2:0] done_type;
reg [3:0] BID;

//tmplt


    reg [4:0] des_tmplt_size;
    reg [4:0] src_tmplt_size;
    reg [31:0] des_tmplt;
    reg [31:0] src_tmplt;

// AXI READ
reg              ARREADY;
reg [3:0]        RID;
reg              RVALID;
reg [127:0]      RDATA;
reg [1:0]        RRESP;
reg              RLAST;

// AXI WRITE
reg              AWREADY;
reg              WREADY;
reg              BVALID;
reg [1:0]        BRESP;

// --------------------------------------------------
// OUTPUTS (declare as wire)
// --------------------------------------------------

wire              ARVALID;
wire [ADDR_W-1:0] ARADDR;
wire [2:0]        ARSIZE;
wire [1:0]        ARBURST;
wire [ID_W-1:0]   ARID;
wire [3:0]        ARLEN;
wire              RREADY;

wire              AWVALID;
wire [ADDR_W-1:0] AWADDR;
wire [2:0]        AWSIZE;
wire [1:0]        AWBURST;
wire [ID_W-1:0]   AWID;
wire [3:0]        AWLEN;

wire              WVALID;
wire [31:0] WDATA;
wire              WLAST;
wire              BREADY;

wire              DONE;

wire [31:0] SRCADDR_UPDATED;
wire [31:0] DESADDR_UPDATED;
wire [31:0] XSIZE_UPDATED;
wire        wr_en_for_updated;

wire [31:0] SRCADDR_INITIAL;
wire [31:0] DESADDR_INITIAL;
wire [31:0] SRCXSIZE_INITIAL;
wire [31:0] DESXSIZE_INITIAL;

wire config_error;
wire ard_error;
wire arpoison_error;
wire awr_error;
wire bus_error;
wire regvalerr;

wire ENABLECMD_DATA;
wire DISABLECMD_DATA;
wire STOPCMD_DATA;

wire STAT_STOP_DATA;
wire STAT_DISABLE_DATA;
wire STAT_RESUMEWAIT_DATA;
wire STAT_TRIGOUTACKWAIT_DATA;
wire STAT_SRCTRIGINWAIT_DATA;
wire STAT_DESTRIGINWAIT_DATA;
wire STAT_PAUSED_DATA;
wire STAT_DONE_DATA;

wire src_trigack;
wire des_trigack;
wire trig_out_req;

// --------------------------------------------------
// DUT INSTANTIATION
// --------------------------------------------------

data_fsm #(
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .ID_W(ID_W)
) dut (

    .clk(clk),
    .resetn(resetn),

    .stat_error_intr_reg(stat_error_intr_reg),
    .stat_done_intr_reg(stat_done_intr_reg),
    .link_en(link_en),
    .LINKHDERR(LINKHDERR),
    .des_trig_req_type(des_trig_req_type),

    .enable_cmd_partsel(enable_cmd_partsel),
    .pause_cmd_partsel(pause_cmd_partsel),
    .resume_cmd_partsel(resume_cmd_partsel),
    .disable_cmd_partsel(disable_cmd_partsel),
    .stop_cmd_partsel(stop_cmd_partsel),
    .stat_disable_intr_reg(stat_disable_intr_reg),
    .stat_stop_intr_reg(stat_stop_intr_reg),
    .cmd_done(cmd_done),

    .use_src_trigin(use_src_trigin),
    .src_trigin_type(src_trigin_type),
    .src_trigin_mode(src_trigin_mode),
    .src_trigin_blk_size(src_trigin_blk_size),
    .src_trigin_sel(src_trigin_sel),

    .use_des_trigin(use_des_trigin),
    .des_trigin_type(des_trigin_type),
    .des_trigin_mode(des_trigin_mode),
    .des_trigin_blk_size(des_trigin_blk_size),
    .des_trigin_sel(des_trigin_sel),

    .use_trigout(use_trigout),
    .trigout_type(trigout_type),
    .trigout_sel(trigout_sel),

    .src_trigin_sw(src_trigin_sw),
    .des_trigin_sw(des_trigin_sw),
    .trig_out_ack_sw(trig_out_ack_sw),
    .src_trigin(src_trigin),
    .des_trigin(des_trigin),

    .src_trigack(src_trigack),
    .des_trigack(des_trigack),
    .trig_out_req(trig_out_req),
    .trig_out_ack(trig_out_ack),

    .SRC_ADDR(SRC_ADDR),
    .des_ADDR(des_ADDR),
    .transize(transize),
    .srcxsize(srcxsize),
    .desxsize(desxsize),
    .x_type(x_type),
    .fillval(fillval),
    .src_xaddr_inc(src_xaddr_inc),
    .des_xaddr_inc(des_xaddr_inc),
    .src_max_burst_len(src_max_burst_len),
    .des_max_burst_len(des_max_burst_len),

    .des_tmplt_size (des_tmplt_size),
    .src_tmplt_size (src_tmplt_size),
    .des_tmplt      (des_tmplt),
    .src_tmplt      (src_tmplt),
    
    .stop_cmd_apb(stop_cmd_apb),
    .src_trigin_sw_type(src_trigin_sw_type),.des_trigin_sw_type(des_trigin_sw_type),
    .cmd_restart_en(cmd_restart_en),
    .cmd_restart_cnt(cmd_restart_cnt),
    .reg_reload_type(cmd_restart_cnt),
    .done_type(done_type),
    .BID(BID),
    
    .y_type(y_type),
    .des_ysize(desysize),
    .src_ysize(srcysize),
    .src_yaddr_stride(src_yaddr_stride),
    .des_yaddr_stride(des_yaddr_stride),
    .ARREADY(ARREADY),
    .ARVALID(ARVALID),
    .ARADDR(ARADDR),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),
    .ARID(ARID),
    .ARLEN(ARLEN),

    .RID(RID),
    .RVALID(RVALID),
    .RDATA(RDATA),
    .RRESP(RRESP),
    .RLAST(RLAST),
    .RREADY(RREADY),

    .AWREADY(AWREADY),
    .AWVALID(AWVALID),
    .AWADDR(AWADDR),
    .AWSIZE(AWSIZE),
    .AWBURST(AWBURST),
    .AWID(AWID),
    .AWLEN(AWLEN),

    .WREADY(WREADY),
    .WVALID(WVALID),
    .WDATA(WDATA),
    .WLAST(WLAST),

    .BVALID(BVALID),
    .BRESP(BRESP),
    .BREADY(BREADY),

    .DONE(DONE),
    .src_trig_req_type(src_trig_req_type),
    .SRCADDR_UPDATED(SRCADDR_UPDATED),
    .DESADDR_UPDATED(DESADDR_UPDATED),
    .XSIZE_UPDATED(XSIZE_UPDATED),
    .wr_en_for_updated(wr_en_for_updated),

    .SRCADDR_INITIAL(SRCADDR_INITIAL),
    .DESADDR_INITIAL(DESADDR_INITIAL),
    .SRCXSIZE_INITIAL(SRCXSIZE_INITIAL),
    .DESXSIZE_INITIAL(DESXSIZE_INITIAL),

    .config_error(config_error),
    .ard_error(ard_error),
    .arpoison_error(arpoison_error),
    .awr_error(awr_error),
    .bus_error(bus_error),
    .regvalerr(regvalerr),

    .ENABLECMD_DATA(ENABLECMD_DATA),
    .DISABLECMD_DATA(DISABLECMD_DATA),
    .STOPCMD_DATA(STOPCMD_DATA),

    .STAT_STOP_DATA(STAT_STOP_DATA),
    .STAT_DISABLE_DATA(STAT_DISABLE_DATA),
    .STAT_RESUMEWAIT_DATA(STAT_RESUMEWAIT_DATA),
    .STAT_TRIGOUTACKWAIT_DATA(STAT_TRIGOUTACKWAIT_DATA),
    .STAT_SRCTRIGINWAIT_DATA(STAT_SRCTRIGINWAIT_DATA),
    .STAT_DESTRIGINWAIT_DATA(STAT_DESTRIGINWAIT_DATA),
    .STAT_PAUSED_DATA(STAT_PAUSED_DATA),
    .STAT_DONE_DATA(STAT_DONE_DATA)

);

always #5 clk = !clk;

initial begin

clk = 0;
resetn = 0;
#20 resetn = 1;

src_tmplt_size = 'd0;
des_tmplt_size = 'd0;

src_tmplt = 0;
des_tmplt = 0;

LINKHDERR = 0;
pause_cmd_partsel = 0;
resume_cmd_partsel = 0;
stop_cmd_apb = 0;
stat_stop_intr_reg = 0;
src_trigin_mode = 'd0;
src_trigin_sel = 'd0;
des_trigin_mode = 'd0;
des_trigin_blk_size = 'd0;
des_trigin_sel = 'd0;
use_trigout = 'd0;
trigout_type = 'd0;
trigout_sel = 'd0;
trig_out_ack_sw = 'd0;
src_trigin_sw_type = 'd2;
des_trigin_sw_type = 'd2;
src_trigin = 'd0;
des_trigin = 'd0;
trig_out_ack = 'd0;
cmd_restart_en = 'd0;
cmd_restart_cnt = 'd0;
reg_reload_type = 'd0;
done_type = 'd0;
RID = 0;


enable_cmd_partsel = 1;
cmd_done = 1;
stop_cmd_partsel = 0;
disable_cmd_partsel = 0;
stat_done_intr_reg = 0;
stat_disable_intr_reg = 0;
stat_error_intr_reg = 0;
WREADY=1;
BRESP = 'd0;
BVALID = 'b1;
// case4
// config
des_ADDR ='hf0;
SRC_ADDR = 300;
transize ='d2;
fillval = 'hFABCFABCFABCFABCFABCFABCFABCFABC;

srcxsize = 'd3;
srcysize = 'd3;
desxsize = 'd2;
desysize = 'd5;

x_type = 'd1;
y_type = 'd1;
src_yaddr_stride = 10;
des_yaddr_stride = 10; 
link_en = 'b1;
src_xaddr_inc = 1;
des_xaddr_inc = 1;


src_trigin_blk_size = 'd7;
src_max_burst_len = 'd1;
des_max_burst_len = 'd1;
src_trig_req_type = 'd2;
des_trig_req_type = 'd2;
//#20 cmd_done = 0;
#20;
// triggers
use_src_trigin ='b1;
use_des_trigin = 'b1;
src_trigin_type = 'd0 ; src_trigin_sw=1;
#20;
des_trigin_type = 'd0; des_trigin_sw=1;
// block 
//1

#40;
RRESP = 'b01;
AWREADY = 'b1;
WREADY = 'b1;
//1
 ARREADY = 'b1;
#30 ARREADY = 'b0;
#10 

RVALID = 1'b1;

RDATA = 128'hABC0ABC0ABC0ABC0ABC0ABC0ABC0ABC0; 
#10 RDATA = 128'hABC1ABC1ABC1ABC1ABC1ABC1ABC1ABC1; 

RLAST = 1;
#10 RLAST = 0;

RVALID = 1'b0;
 ARREADY = 'b1;
 WREADY = 1;
#30 ARREADY = 'b0;
#15;
RVALID = 1'b1;
 RDATA = 128'hABC2ABC2ABC2ABC2ABC2ABC2ABC2ABC2; 
 //#10 RDATA = 128'hABC3ABC3ABC3ABC3ABC3ABC3ABC3ABC3; 
 RLAST = 1;
#10 RLAST = 0;

 

RVALID = 1'b0;
 ARREADY = 'b1;
#30 ARREADY = 'b0;
#10 

RVALID = 1'b1;
RDATA = 128'hABC3ABC3ABC3ABC3ABC3ABC3ABC3ABC3;
#10;
 RDATA = 128'hABC4ABC4ABC4ABC4ABC4ABC4ABC4ABC4;

RLAST = 1;
#10 RLAST = 0;

RVALID = 0;


//2

 ARREADY = 'b1;
#30 ARREADY = 'b0;
#10 

RVALID = 1'b1;

RDATA = 128'hABC5ABC5ABC5ABC5ABC5ABC5ABC5ABC5; 
//#10 RDATA = 128'hABC6ABC6ABC6ABC6ABC6ABC6ABC6ABC6; 

RLAST = 1;
#10 RLAST = 0;

RVALID = 1'b0;
 ARREADY = 'b1;
 WREADY = 1;
#30 ARREADY = 'b0;
#15;
RVALID = 1'b1;
 RDATA = 128'hABC6ABC6ABC6ABC6ABC6ABC6ABC6ABC6; 
 #10RDATA = 128'hABC7ABC7ABC7ABC7ABC7ABC7ABC7ABC7;
 
 RLAST = 1;
#10 RLAST = 0;

 

RVALID = 1'b0;
 ARREADY = 'b1;
#30 ARREADY = 'b0;
#10 

RVALID = 1'b1;
 RDATA = 128'hABC8ABC8ABC8ABC8ABC8ABC8ABC8ABC8;

RLAST = 1;
#10 RLAST = 0;

RVALID = 1'b0;



// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;

//RDATA = 128'hABC0ABC0ABC0ABC0ABC0ABC0ABC0ABC0; 
//#10 RDATA = 128'hABC1ABC1ABC1ABC1ABC1ABC1ABC1ABC1; 

//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 1'b0;
// ARREADY = 'b1;
// WREADY = 1;
//#30 ARREADY = 'b0;
//#15;
//RVALID = 1'b1;
// RDATA = 128'hABC2ABC2ABC2ABC2ABC2ABC2ABC2ABC2; 
// //#10 RDATA = 128'hABC3ABC3ABC3ABC3ABC3ABC3ABC3ABC3; 
// RLAST = 1;
//#10 RLAST = 0;

 

//RVALID = 1'b0;
// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;
//RDATA = 128'hABC3ABC3ABC3ABC3ABC3ABC3ABC3ABC3;
//#10;
// RDATA = 128'hABC4ABC4ABC4ABC4ABC4ABC4ABC4ABC4;

//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 0;


////2

// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;

//RDATA = 128'hABC5ABC5ABC5ABC5ABC5ABC5ABC5ABC5; 
////#10 RDATA = 128'hABC6ABC6ABC6ABC6ABC6ABC6ABC6ABC6; 

//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 1'b0;
////3
// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;

//RDATA = 128'hABC3ABC3ABC3ABC3ABC3ABC3ABC3ABC3; 
//#10 RDATA = 128'hABC4ABC4ABC4ABC4ABC4ABC4ABC4ABC4; 

//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 1'b0;
// ARREADY = 'b1;
// WREADY = 1;
//#30 ARREADY = 'b0;
//#15;
//RVALID = 1'b1;
// RDATA = 128'hABC5ABC5ABC5ABC5ABC5ABC5ABC5ABC5; 
 
// RLAST = 1;
//#10 RLAST = 0;

 
//RVALID = 1'b0;
// ARREADY = 'b1;
// WREADY = 1;
//#30 ARREADY = 'b0;
//#15;
//RVALID = 1'b1;
// RDATA = 128'hABC0ABC0ABC0ABC0ABC0ABC0ABC0ABC0; 
// #10 RDATA = 128'hABC1ABC1ABC1ABC1ABC1ABC1ABC1ABC1; 
// RLAST = 1;
//#10 RLAST = 0;

 

//RVALID = 1'b0;
// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;
// RDATA = 128'hABC2ABC2ABC2ABC2ABC2ABC2ABC2ABC2;

//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 1'b0;

////3
// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;

//RDATA = 128'hABC3ABC3ABC3ABC3ABC3ABC3ABC3ABC3; 
//#10 RDATA = 128'hABC4ABC4ABC4ABC4ABC4ABC4ABC4ABC4; 

//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 1'b0;
// ARREADY = 'b1;
// WREADY = 1;
//#30 ARREADY = 'b0;
//#15;
//RVALID = 1'b1;
// RDATA = 128'hABC5ABC5ABC5ABC5ABC5ABC5ABC5ABC5; 
 
// RLAST = 1;
//#10 RLAST = 0;


//RVALID = 1'b0;
// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;
// RDATA = 128'hABC4ABC4ABC4ABC4ABC4ABC4ABC4ABC4;
// #10 RDATA = 128'hABC3ABC3ABC3ABC3ABC3ABC3ABC3ABC3; 

//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 1'b0;
/////////////////////////////////////////////////////////////////
//RVALID = 1'b0;
// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;
// RDATA =    128'hABC6ABC6ABC6ABC6ABC6ABC6ABC6ABC6; 


//RLAST = 1;
//#10 RLAST = 0;

//RVALID = 1'b0;
// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;
// RDATA = 128'hABC7ABC7ABC7ABC7ABC7ABC7ABC7ABC7;
//#10 RDATA = 128'hABC8ABC8ABC8ABC8ABC8ABC8ABC8ABC8; 
//RLAST = 1;
//#10 RLAST = 0;
//RVALID = 1'b0;
// ARREADY = 'b1;
// WREADY = 1;
//#30 ARREADY = 'b0;
//RVALID = 1'b1;
// RDATA = 128'hABC9ABC9ABC9ABC9ABC9ABC9ABC9ABC9; 
//RLAST = 1;
//#10 RLAST = 0; 

// ARREADY = 'b1;
//#30 ARREADY = 'b0;
//#10 

//RVALID = 1'b1;

//RDATA = 128'hABC5; 
//#10 RDATA = 128'hABC6; 
//#10 RDATA = 128'hABC7; 
//RLAST = 1;
//#10 RLAST = 0;
// ARREADY = 'b1;
// WREADY = 1;
//#30 ARREADY = 'b0;
// RDATA = 128'hABC8; 
//#10 RDATA = 128'hABC9; 
//RLAST = 1;
//#10 RLAST = 0; 

WREADY = 1;
#1000 $finish;
end
endmodule

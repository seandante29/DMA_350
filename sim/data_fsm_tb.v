module data_fsm_tb();
  parameter ADDR_W = 32;
    parameter DATA_W = 128;
    parameter ID_W   = 4;
reg              clk;
reg              resetn;
reg             stat_error;
reg             stat_done;
reg             link_en;        // added
    // Control
reg             enable_cmd;
reg             pause_cmd;
reg             resume_cmd;
reg             disable_cmd;
reg             stop_cmd;
reg             cmd_done;

    // Triggers
reg             use_src_trigin;
reg[1:0]        src_trigin_type;
reg[1:0]        src_trigin_mode;
reg[7:0]        src_trigin_sel;

reg             use_des_trigin;
reg[1:0]        des_trigin_type;
reg[1:0]        des_trigin_mode;
reg[7:0]        des_trigin_sel;

reg             use_trigout;
reg[1:0]        trigout_type;
reg[7:0]        trigout_sel;

reg             src_trigin_sw;
reg             des_trigin_sw;
reg             trig_out_ack_sw;

reg[1:0]        src_trigin_req_type;
reg[1:0]        des_trigin_req_type;

    // To trigger matrix
wire  [1:0]        src_trigin_ack_type;
wire  [1:0]        des_trigin_ack_type;

reg             SRCTRIGINSELERR;
reg             DESTRIGINSELERR;
reg             TRIGOUTSELERR;
wire            trig_err;

reg             src_trigin;
reg             des_trigin;
wire               src_trigack;
wire               des_trigack;
wire               trig_out_req;
reg             trig_out_ack;

    // Config
reg[ADDR_W-1:0] SRC_ADDR;
reg[ADDR_W-1:0] des_ADDR;
reg[2:0]        transize;
reg[15:0]       srcxsize;
reg[15:0]       desxsize;
reg[2:0]        x_type;
reg[127:0]      fillval;
reg             src_xaddr_inc;
reg             des_xaddr_inc;

    // AXI READ
reg             ARREADY;
wire               ARVALID;
wire  [ADDR_W-1:0] ARADDR;
wire  [2:0]        ARSIZE;
wire  [1:0]        ARBURST;
wire  [ID_W-1:0]   ARID;
wire  [7:0]        ARLEN;

reg             RVALID;
reg[127 : 0]    RDATA;
reg[1:0]        RRESP;
reg             RLAST;
wire               RREADY;

    // AXI WRITE
reg             AWREADY;
wire               AWVALID;
wire  [ADDR_W-1:0] AWADDR;
wire  [2:0]        AWSIZE;
wire  [1:0]        AWBURST;
wire  [ID_W-1:0]   AWID;

reg             WREADY;
wire               WVALID;
wire  [DATA_W-1:0] WDATA;
wire               WLAST;

reg             BVALID;
reg[1:0]        BRESP;
wire               BREADY;

    // Status
wire               DONE;
wire            ERROR;

    // Error flags
wire               config_error;
wire               ard_error;
wire               arpoison_error;
wire               awr_error;
wire               bus_error;
wire               regvalerr;

wire               ENABLECMD, DISABLECMD, STOPCMD;
wire               STAT_STOP, STAT_DISABLE, STAT_RESUMEWAIT; 
wire               STAT_TRIGOUTACKWAIT, STAT_SRCTRIGINWAIT; 
wire               STAT_DESTRIGINWAIT, STAT_PAUSED, STAT_DONE;

data_fsm dut(
.clk(clk),
.resetn(resetn),
.stat_error(stat_error),
.stat_done(stat_done),
.link_en(link_en),
.enable_cmd(enable_cmd),
.pause_cmd(pause_cmd),
.disable_cmd(disable_cmd),
.stop_cmd(stop_cmd),
. resume_cmd( resume_cmd),
.cmd_done(cmd_done),
.use_src_trigin(use_src_trigin),
.src_trigin_type(src_trigin_type),
.src_trigin_mode(src_trigin_mode),
.src_trigin_sel(src_trigin_sel),
.use_des_trigin(use_des_trigin),
.des_trigin_type(des_trigin_type),
.des_trigin_mode(des_trigin_mode),
.des_trigin_sel(des_trigin_sel),
.use_trigout(use_trigout),
.trigout_type(trigout_type),
.trigout_sel(trigout_sel),
.src_trigin_sw(src_trigin_sw),
.des_trigin_sw(des_trigin_sw),
.trig_out_ack_sw(trig_out_ack_sw),
.src_trigin_req_type(src_trigin_req_type),
.des_trigin_req_type(des_trigin_req_type),
.src_trigin_ack_type(src_trigin_ack_type),
.des_trigin_ack_type(des_trigin_ack_type),
.SRCTRIGINSELERR(SRCTRIGINSELERR),
.DESTRIGINSELERR(DESTRIGINSELERR),
.TRIGOUTSELERR(TRIGOUTSELERR),
.trig_err(trig_err),
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
.ARREADY(ARREADY),
.ARVALID(ARVALID),
.ARADDR(ARADDR),
.ARSIZE(ARSIZE),
.ARBURST(ARBURST),
.ARID(ARID),
.ARLEN(ARLEN),
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
.WREADY(WREADY),
.WVALID(WVALID),
.WDATA(WDATA),
.WLAST(WLAST),
.BVALID(BVALID),
.BRESP(BRESP),
.BREADY(BREADY),
.DONE(DONE),
.ERROR(ERROR),
.config_error(config_error),
.ard_error(ard_error),
.arpoison_error(arpoison_error),
.awr_error(awr_error),
.bus_error(bus_error),
.regvalerr(regvalerr),
.ENABLECMD(ENABLECMD),
.DISABLECMD(DISABLECMD),
.STOPCMD(STOPCMD),
.STAT_STOP(STAT_STOP),
.STAT_DISABLE(STAT_DISABLE),
.STAT_RESUMEWAIT(STAT_RESUMEWAIT),
.STAT_TRIGOUTACKWAIT(STAT_TRIGOUTACKWAIT),
.STAT_SRCTRIGINWAIT(STAT_SRCTRIGINWAIT),
.STAT_DESTRIGINWAIT(STAT_DESTRIGINWAIT),
.STAT_PAUSED(STAT_PAUSED),
.STAT_DONE(STAT_DONE));



always #5 clk = !clk;
initial begin

clk = 0;
resetn = 0;
#20 resetn = 1;


enable_cmd = 1;
cmd_done = 1;
disable_cmd = 0;

// case4
// config
des_ADDR ='hEF;
SRC_ADDR ='hEE;
transize ='d0;
fillval = 'hABCDE;
srcxsize = 'd4;
desxsize = 'd4;
x_type = 'b1;
link_en = 'b1;
#20 cmd_done = 0;
// triggers
use_src_trigin ='b1;
use_des_trigin = 'b1;
src_trigin_type = 2'b00 ; src_trigin_sw=1;
#20;
des_trigin_type = 2'b00; des_trigin_sw=1;

#10 ARREADY = 'b1;
#30 ARREADY = 'b0;

#10 
RRESP = 'b01;
RVALID = 'b1;
RDATA = 'hABC0;
#10
RDATA = 'hABC1;
#10
RDATA = 'hABC2;
#10
RDATA = 'hABC3;
RLAST = 'b1;
#10 RLAST = 'b0;
RVALID = 'b0;
#20;

AWREADY = 'b1;
#30 AWREADY = 'b0;

WREADY = 'b1;
#80;

BVALID = 1'b1;
BRESP = 'b00;
#20 BVALID = 'b0;

use_trigout = 'b1;
 trigout_type = 'b00;
#10 trig_out_ack_sw = 'b1;
#30 trig_out_ack_sw = 'b0;


#100;
//case 2

enable_cmd = 1;
cmd_done = 1;
disable_cmd = 0;


// config
des_ADDR ='hEF;
SRC_ADDR ='hEE;
transize ='d0;
fillval = 'hABCDE;
srcxsize = 'd0;
desxsize = 'd4;
x_type = 'd3;
#20 cmd_done = 0;
// triggers
use_src_trigin ='b1;
use_des_trigin = 'b1;
src_trigin_type = 2'b10 ; src_trigin=1;src_trigin_sel =0; 
#20;
des_trigin_type = 2'b10; des_trigin=1;des_trigin_sel=1;

#10 ARREADY = 'b1;
#30 ARREADY = 'b0;

#10 
RRESP = 'b01;
RVALID = 'b1;
RDATA = 'hABC0;
#10
RDATA = 'hABC1;
#10
RDATA = 'hABC2;
#10
RDATA = 'hABC3;
RLAST = 'b1;
#10 RLAST = 'b0;
RVALID = 'b0;

#30;

AWREADY = 'b1;
#40 AWREADY = 'b0;

WREADY = 'b1;
#80;

BVALID = 1'b1;
BRESP = 'b00;
#20 BVALID = 'b0;

use_trigout = 'b1;
 trigout_type = 'b10;
  trigout_sel = 1;
#10 trig_out_ack= 'b1;
#30 trig_out_ack = 'b0;

//case6

enable_cmd = 1;
cmd_done = 1;
disable_cmd = 0;


// config
des_ADDR ='hEF;
SRC_ADDR ='hEE;
transize ='d0;
fillval = 'hABCDE;
srcxsize = 'd4;
desxsize = 'd8;
x_type = 'd2;
#20 cmd_done = 0;
// triggers
use_src_trigin ='b1;
use_des_trigin = 'b1;
src_trigin_type = 2'b10 ; src_trigin=1;src_trigin_sel =0; 
#20;
des_trigin_type = 2'b10; des_trigin=1;des_trigin_sel=1;

#10 ARREADY = 'b1;
#30 ARREADY = 'b0;

#10 
RRESP = 'b01;
RVALID = 'b1;
RDATA = 'hABC0;
#10
RDATA = 'hABC1;
#10
RDATA = 'hABC2;
#10
RDATA = 'hABC3;
RLAST = 'b1;
#10 RLAST = 'b0;
RVALID = 'b0;
#30;

AWREADY = 'b1;
#40 AWREADY = 'b0;

WREADY = 'b1;
#160;

BVALID = 1'b1;
BRESP = 'b00;
#20 BVALID = 'b0;

use_trigout = 'b1;
 trigout_type = 'b10;
  trigout_sel = 1;
#10 trig_out_ack= 'b1;
link_en =0;
#30 trig_out_ack = 'b0;


//case5
enable_cmd = 1;
cmd_done = 1;
disable_cmd = 0;


// config
des_ADDR ='hEF;
SRC_ADDR ='hEE;
transize ='d0;
fillval = 'hABCDE;
srcxsize = 'd4;
desxsize = 'd2;
x_type = 'd2;
#20 cmd_done = 0;
// triggers
use_src_trigin ='b1;
use_des_trigin = 'b1;
src_trigin_type = 2'b10 ; src_trigin=1;src_trigin_sel =0; 
#20;
des_trigin_type = 2'b10; des_trigin=1;des_trigin_sel=1;

#10 ARREADY = 'b1;
#30 ARREADY = 'b0;

#10 
RRESP = 'b01;
RVALID = 'b1;
RDATA = 'hABC9;
#10
RDATA = 'hABC8;
#10
RDATA = 'hABC7;
#10
RDATA = 'hABC6;
RLAST = 'b1;
#10 RLAST = 'b0;
RVALID = 'b0;
#30;

AWREADY = 'b1;
#40 AWREADY = 'b0;

WREADY = 'b1;
#40;

BVALID = 1'b1;
BRESP = 'b00;
#20 BVALID = 'b0;

use_trigout = 'b1;
 trigout_type = 'b10;
  trigout_sel = 1;
#10 trig_out_ack= 'b1;
link_en =0;
#30 trig_out_ack = 'b0;

// case3


enable_cmd = 1;
cmd_done = 1;
disable_cmd = 0;


// config
des_ADDR ='hEF;
SRC_ADDR ='hEE;
transize ='d0;
fillval = 'hABCDE;
srcxsize = 'd4;
desxsize = 'd0;
x_type = 'd2;
#20 cmd_done = 0;
// triggers
stat_error = 'b0;
use_src_trigin ='b1;
use_des_trigin = 'b1;
src_trigin_type = 2'b10 ; src_trigin=1;src_trigin_sel =0; 
#20;
des_trigin_type = 2'b10; des_trigin=1;des_trigin_sel=1;

#10 ARREADY = 'b1;
#30 ARREADY = 'b0;

#10 
RRESP = 'b01;
RVALID = 'b1;
RDATA = 'hABC0;
#10
RDATA = 'hABC1;
#10
RDATA = 'hABC2;
#10
RDATA = 'hABC3;
RLAST = 'b1;
#10 RLAST = 'b0;
RVALID = 'b0;
#30;

AWREADY = 'b1;
#40 AWREADY = 'b0;

WREADY = 'b1;
#160;

BVALID = 1'b1;
BRESP = 'b00;
#20 BVALID = 'b0;

use_trigout = 'b1;
 trigout_type = 'b10;
  trigout_sel = 1;
#10 trig_out_ack= 'b1;
link_en =0;
#30 trig_out_ack = 'b0;


//case1

enable_cmd = 1;
cmd_done = 1;
disable_cmd = 0;


// config
des_ADDR ='hEF;
SRC_ADDR ='hEE;
transize ='d0;
fillval = 'hABCDE;
srcxsize = 'd0;
desxsize = 'd0;
x_type = 'd2;
#20 cmd_done = 0;
// triggers
stat_error = 'b0;
use_src_trigin ='b1;
use_des_trigin = 'b1;
src_trigin_type = 2'b10 ; src_trigin=1;src_trigin_sel =0; 
#20;
des_trigin_type = 2'b10; des_trigin=1;des_trigin_sel=1;

#10 ARREADY = 'b1;
#30 ARREADY = 'b0;

#10 
RRESP = 'b01;
RVALID = 'b1;
RDATA = 'hABC0;
#10
RDATA = 'hABC1;
#10
RDATA = 'hABC2;
#10
RDATA = 'hABC3;
RLAST = 'b1;
#10 RLAST = 'b0;
RVALID = 'b0;
#30;

AWREADY = 'b1;
#40 AWREADY = 'b0;

WREADY = 'b1;
#160;

BVALID = 1'b1;
BRESP = 'b00;
#20 BVALID = 'b0;

use_trigout = 'b1;
 trigout_type = 'b10;
  trigout_sel = 1;
#10 trig_out_ack= 'b1;
link_en =0;
#30 trig_out_ack = 'b0;



#500 $finish;

end

endmodule

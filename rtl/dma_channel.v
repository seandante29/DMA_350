module dma_channel
#(parameter WIDTH = 32,
    parameter DATA_W = 128 )
(
    input wire clk,resetn,                 
    // reg bank signals
    input wire [(WIDTH * 15) -1:0] reg_chn_in, // from reg bank       
    //inter reg signals    
    output wire [(WIDTH*2)-1 : 0] chn_reg_out,                       
    output  wire IRQ,
    //cmd fsm signal
     input wire ARREADY,
     input wire RID,
     input wire [DATA_W-1 : 0]RDATA_I,
     input wire [1:0]RRESP,
     input wire RLAST,
     input wire RVALID,
     input wire WREADY,
     input wire AWREADY,
     input wire BVALID,
     input wire [1:0] BRESP,
     
     //trig matrix o/p's as i/p's to channel
     input wire SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR,
     input wire src_trig_req,
     input wire [1:0]  src_trig_req_type,

    input wire         des_trig_req,
    input wire  [1:0]  des_trig_req_type,
    
    input wire ch_trigout_ack,
    
    output wire        ch_src_ack,
    output wire [1:0]  ch_src_ack_type,

    output wire        ch_des_ack,
    output wire [1:0]  ch_des_ack_type,

    output wire        ch_trigout_req,
    
    
     
     
     
     // to sys mem
      output wire [3:0] ARID,
      output wire [3:0] ARLEN,
      output wire[2:0] ARSIZE,
      output wire [1:0] ARBURST,
      output wire ARVALID,
      output wire [31:0]ARADDR,
      output wire RREADY,      
      
      output wire [3:0] ARID_D,
      output wire [3:0] ARLEN_D,
      output wire[2:0] ARSIZE_D,
      output wire [1:0] ARBURST_D,
      output wire ARVALID_D,
      output wire [31:0]ARADDR_D,
      output wire RREADY_D ,
      
      output wire [3:0] AWID_D,
      output wire [3:0] AWLEN_D,
      output wire[2:0] AWSIZE_D,
      output wire [1:0] AWBURST_D,
      output wire AWVALID_D,
      output wire [31:0]AWADDR_D,
      output wire WVALID_D,
      output wire [DATA_W -1 :0] WDATA_D,
      output wire WLAST_D,
      output wire BREADY_D,

    output wire [1:0]  src_trigin_type,
        output wire [7:0]  src_trigin_sel,
        output wire [1:0]  des_trigin_type,
        output wire [7:0]  des_trigin_sel,
        output wire [1:0]  trigout_type,
        output wire [5:0]  trigout_sel,
    output wire        use_trigout,
    output wire        use_des_trigin,
    output wire        use_src_trigin
        
      
                       
);

wire [(WIDTH * 15) -1:0]  mux_logic_in;

// wires to part select

 wire [31:0] CH_CTRL_O;
 wire [31:0] CH_INTREN_O;
 wire [31:0] CH_XSIZE_O;
 wire [31:0] CH_LINKADDR_O;
 wire [31:0] CH_CMD_O;
 wire [31:0] CH_STATUS_O;
 wire [31:0] CH_XADDRINC_O;
 wire [31:0] CH_SRCTRANSCFG_O;
 wire [31:0] CH_DESTRANSCFG_O;
 wire [31:0] CH_SRCTRIGINCFG_O;
 wire [31:0] CH_DESTRIGINCFG_O;
 wire [31:0] CH_TRIGOUTCFG_O;
 wire [31:0] CH_SRCADDR_O;
 wire [31:0] CH_DESADDR_O;
 wire [31:0] CH_FILLVAL_O;
 
 //wires to data fsm
 
//wire use_trigout;
//wire use_des_trigin;
//wire use_src_trigin;
wire [2:0] x_type;
wire [2:0] transize;
wire [15:0] srcxsize;
wire [15:0] desxsize;
wire [29:0] linkaddr;
wire linkaddren;
wire stop_cmd;
wire enable_cmd;
wire disable_cmd;
wire pause_cmd;
wire resume_cmd;
wire src_trigin_sw;
wire [1:0]  src_trigin_sw_req_type;
wire des_trigin_sw;
wire [1:0] des_trigin_sw_req_type;
wire trigout_ack_sw;
wire [1:0] src_trigin_mode;
//wire [1:0] src_trigin_type;
//wire [7:0] src_trigin_sel;
wire [1:0] des_trigin_mode;
//wire [1:0] des_trigin_type;
//wire [7:0] des_trigin_sel;
//wire [1:0] trigout_type;
//wire [5:0] trigout_sel;
wire [31:0] src_addr;
wire [31:0] des_addr;
wire [31:0] fillval;
wire [15:0] src_xaddr_inc;
wire [15:0] des_xaddr_inc;
wire stat_done;
wire stat_err;


// wires to internal reg from data fsm( stat and cmd)
  wire STAT_TRIGOUTACKWAIT;
  wire STAT_DESTRIGINWAIT;
  wire STAT_SRCTRIGINWAIT;
  wire STAT_RESUMEWAIT;
  wire STAT_STOPPED;
  wire STAT_PAUSED;
  wire STAT_DISABLED;
  wire STAT_DONE;
 
  wire ENABLECMD;
  wire DISABLECMD;
  wire STOPCMD;

// wires to cmd fsm
  //  wire [31:0]LINKADDR;
 // wire data_done;
   wire [31:0] RDATA_O;
   wire [31:0] LINK_HEADER;
   wire [5:0] wptr;
   wire LINKHDRERR;
   wire CMD_DONE; //done signal to data fsm
   wire AXIRDRESPERR;//address out of range error
   wire AXIRDPOISERR;//corrupted data error
   wire BUSERR;//any axi error assterts this
    
    //wires to trig mtx
    
    wire [1:0] des_trigin_ack_type;
    wire [1:0] src_trigin_ack_type;
    wire trig_out_req;
    wire des_trigack;
    wire src_trigack;

    internal_reg  #(.WIDTH (32),.DEPTH ( 145)) dut0
  (
  .clk(clk),
  .resetn(resetn),
  .data_in(mux_logic_in),
  .AXIRDRESPERR(AXIRDRESPERR),
  .AXIRDPOISERR(AXIRDPOISERR),
  .AXIWRRESPERR(AXIWRRESPERR),
  .BUSERR(BUSERR),
  .config_error(config_error),
  .regval_error(regval_error),
  .SRCTRIGINSELERR(SRCTRIGINSELERR),
  .DESTRIGINSELERR(DESTRIGINSELERR),
  .TRIGOUTSELERR(TRIGOUTSELERR),
  .AXIRDRESPERR_CMDFSM(AXIRDRESPERR_CMDFSM),
  .AXIRDPOISERR_CMDFSM(AXIRDPOISERR_CMDFSM),
  .BUSERR_CMDFSM(BUSERR_CMDFSM),
  .LINKHDERR(LINKHDERR),
  .STAT_TRIGOUTACKWAIT(STAT_TRIGOUTACKWAIT),
  .STAT_DESTRIGINWAIT(STAT_DESTRIGINWAIT),
  .STAT_SRCTRIGINWAIT(STAT_SRCTRIGINWAIT),
  .STAT_RESUMEWAIT(STAT_RESUMEWAIT),
  .STAT_STOPPED(STAT_STOPPED),
  .STAT_PAUSED(STAT_PAUSED),
  .STAT_DISABLED(STAT_DISABLED),
  .STAT_DONE(STAT_DONE),
   .ENABLECMD(ENABLECMD),
   .DISABLECMD(DISABLECMD),
   .STOPCMD(STOPCMD),
  .chn_reg_out(chn_reg_out),
  .CH_CTRL_O(CH_CTRL_O),
  .CH_INTREN_O(CH_INTREN_O),
  .CH_XSIZE_O(CH_XSIZE_O),
  .CH_LINKADDR_O(CH_LINKADDR_O),
  .CH_CMD_O(CH_CMD_O),
  .CH_STATUS_O(CH_STATUS_O),
  .CH_XADDRINC_O(CH_XADDRINC_O),
  .CH_SRCTRANSCFG_O(CH_SRCTRANSCFG_O),
  .CH_DESTRANSCFG_O(CH_DESTRANSCFG_O),
  .CH_SRCTRIGINCFG_O(CH_SRCTRIGINCFG_O),
  .CH_DESTRIGINCFG_O(CH_DESTRIGINCFG_O),
  .CH_TRIGOUTCFG_O(CH_TRIGOUTCFG_O),
  .CH_SRCADDR_O(CH_SRCADDR_O),
  .CH_DESADDR_O(CH_DESADDR_O),
  .CH_FILLVAL_O(CH_FILLVAL_O),
  .IRQ(IRQ)
  );
  
  partselect dut1(
    .CH_CTRL(CH_CTRL_O),
    .CH_XSIZE(CH_XSIZE_O),
    .CH_LINKADDR(CH_LINKADDR_O),
    .CH_CMD(CH_CMD_O),
    .CH_STATUS(CH_STATUS_O),
    .CH_XADDRINC(CH_XADDRINC_O),
    .CH_SRCTRIGINCFG(CH_SRCTRIGINCFG_O),
    .CH_DESTRIGINCFG(CH_DESTRIGINCFG_O),
    .CH_TRIGOUTCFG(CH_TRIGOUTCFG_O),
    .CH_SRCADDR(CH_SRCADDR_O),
    .CH_DESADDR(CH_DESADDR_O),
    .CH_FILLVAL(CH_FILLVAL_O),
    .use_trigout(use_trigout),
    .use_des_trigin(use_des_trigin),
    .use_src_trigin(use_src_trigin),
    .x_type(x_type),
    .transize(transize),
    .srcxsize(srcxsize),
    .desxsize(desxsize),
    .linkaddr(linkaddr),
    .linkaddren(linkaddren),
    .enable_cmd(enable_cmd),
    .disable_cmd(disable_cmd),
    .pause_cmd(pause_cmd),
    .resume_cmd(resume_cmd),
    .stop_cmd(stop_cmd),
    .src_trigin_sw(src_trigin_sw),
    .src_trigin_sw_type(src_trigin_sw_type),
    .des_trigin_sw(des_trigin_sw),
    .des_trigin_sw_type(des_trigin_sw_type),
    .trigout_ack_sw(trigout_ack_sw),
    .src_trigin_mode(src_trigin_mode),
    .src_trigin_type(src_trigin_type),
    .src_trigin_sel(src_trigin_sel),
    .des_trigin_mode(des_trigin_mode),
    .des_trigin_type(des_trigin_type),
    .des_trigin_sel(des_trigin_sel),
    .trigout_type(trigout_type),
    .trigout_sel(trigout_sel),
    .src_addr(src_addr),
    .des_addr(des_addr),
    .fillval(fillval),
    .src_xaddr_inc(src_xaddr_inc),
    .des_xaddr_inc(des_xaddr_inc),
    .stat_done(stat_done),
    .stat_err(stat_err)
);

 cmd_fsm dut2(.clk(clk), 
      .resetn(resetn),
      .STAT_ERROR(stat_err),
      .LINKADDR(linkaddr),
      .link_enable(linkaddren),
      .data_done(data_done),
      .ARREADY(ARREADY),
      .ARID(ARID),
      .ARLEN(ARLEN),
      .ARSIZE(ARSIZE),
      .ARBURST(ARBURST),
      .ARVALID(ARVALID),
      .ARADDR(ARADDR),
      .RID(RID),
      .RDATA_I(RDATA_I),
      .RRESP(RRESP),
      .RLAST(RLAST),
      .RVALID(RVALID),
      .RREADY(RREADY),
      .RDATA_O(RDATA_O),
      .LINK_HEADER(LINK_HEADER),
      .wptr(wptr),
      .LINKHDRERR(LINKHDRERR),
      .CMD_DONE(CMD_DONE),
      .AXIRDRESPERR(AXIRDRESPERR),
      .AXIRDPOISERR(AXIRDPOISERR),
      .BUSERR(BUSERR)
      );
      
      mux_logic  #(.WIDTH (32))
      dut3  (.cmd_data(RDATA_O),
       .clk(clk),
       .resetn(resetn),
       .wptr(wptr),
       .link_en(linkaddren),
       .header_in(LINK_HEADER),
       .CH_CTRL(CH_CTRL_O),
       .CH_INTREN(CH_INTREN_O),
       .CH_XSIZE(CH_XSIZE_O),
       .CH_LINKADDR(CH_LINKADDR_O),
       .CH_XADDRINC(CH_XADDRINC_O),
       .CH_SRCTRANSCFG(CH_SRCTRANSCFG_O),
       .CH_DESTRANSCFG(CH_DESTRANSCFG_O),
       .CH_SRCTRIGINCFG(CH_SRCTRIGINCFG_O),
       .CH_DESTRIGINCFG(CH_DESTRIGINCFG_O),
       .CH_TRIGOUTCFG(CH_TRIGOUTCFG_O),
       .CH_SRCADDR(CH_SRCADDR_O),
       .CH_DESADDR(CH_DESADDR_O),
       .CH_FILLVAL(CH_FILLVAL_O),
       .reg_bank_in(reg_chn_in),
       .mux_out_reg(mux_logic_in)
       );               
      
    data_fsm dut4(
    .clk(clk),
    .resetn(resetn),
    .stat_error(stat_err),
    .stat_done(stat_done),
    .link_en(linkaddren),
    .enable_cmd(enable_cmd),
    .pause_cmd(pause_cmd),
    .disable_cmd(disable_cmd),
    .stop_cmd(stop_cmd),
    . resume_cmd( resume_cmd),
    .cmd_done(CMD_DONE),
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
    .src_trigin_sw_req_type(src_trigin_sw_req_type),
    .des_trigin_sw_req_type(des_trigin_sw_req_type),
    .src_trigin_sw(src_trigin_sw),
    .des_trigin_sw(des_trigin_sw),
    .trig_out_ack_sw(trig_out_ack_sw),
    .src_trigin_req_type(src_trig_req_type),//
    .des_trigin_req_type(des_trig_req_type),//trig mtx
    .src_trigin_ack_type(ch_src_ack_type),//to trig mtx
    .des_trigin_ack_type(ch_des_ack_type),
 //   .SRCTRIGINSELERR(SRCTRIGINSELERR),
 //   .DESTRIGINSELERR(DESTRIGINSELERR),
  //  .TRIGOUTSELERR(TRIGOUTSELERR),
   // .trig_err(trig_err),
    .src_trigin(src_trig_req),//from trig
    .des_trigin(des_trig_req),//from trig
    .src_trigack(ch_src_ack),//to trig
    .des_trigack(ch_des_ack),
    .trig_out_req(ch_trigout_req),
    .trig_out_ack(ch_trigout_ack),//from trig
    .SRC_ADDR(src_addr),//
    .des_ADDR(des_addr),
    .transize(transize),
    .srcxsize(srcxsize),
    .desxsize(desxsize),
    .x_type(x_type),
    .fillval(fillval),
    .src_xaddr_inc(src_xaddr_inc),
    .des_xaddr_inc(des_xaddr_inc),
    .ARREADY(ARREADY),
    .ARVALID(ARVALID_D),
    .ARADDR(ARADDR_D),
    .ARSIZE(ARSIZE_D),
    .ARBURST(ARBURST_D),
    .ARID(ARID_D),
    .ARLEN(ARLEN_D),
    .RVALID(RVALID),
    .RDATA(RDATA_I),
    .RRESP(RRESP),
    .RLAST(RLAST),
    .RREADY(RREADY_D),
    .AWREADY(AWREADY),
    .AWVALID(AWVALID_D),
    .AWADDR(AWADDR_D),
    .AWSIZE(AWSIZE_D),
    .AWBURST(AWBURST_D),
    .AWLEN(AWLEN_D),
    .AWID(AWID_D),
    .WREADY(WREADY),
    .WVALID(WVALID_D),
    .WDATA(WDATA_D),
    .WLAST(WLAST_D),
    .BVALID(BVALID),
    .BRESP(BRESP),
    .BREADY(BREADY_D),
    .DONE(DONE),
   // .ERROR(ERROR),
    .config_error(config_error),
    .ard_error(AXIRDRESPERR),
    .arpoison_error(AXIRDPOISERR),
    .awr_error(AXIWRRESPERR),
    .bus_error(BUSERR),
    .regvalerr(regval_error),
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
    
    
    /*
    trigger_matrix dut5(
    .STAT_ERR(stat_err),
    .trig0_req(trig0_req),
    .trig0_req_type(trig0_req_type),
    .trig0_ack(trig0_ack),
    .trig0_ack_type(trig0_ack_type),
    .trig1_req(trig1_req),
    .trig1_req_type(trig1_req_type),
    .trig1_ack(trig1_ack),
    .trig1_ack_type(trig1_ack_type),
    .trig0_out_req(trig0_out_req),
    .trig0_out_ack(trig0_out_ack),
    .trig1_out_req(trig1_out_req),
    .trig1_out_ack(trig1_out_ack),
    .use_src_trigin(use_src_trigin),
    .src_trigin_type(src_trigin_type),
    .src_trigin_sel(src_trigin_sel), 
    .use_dst_trigin(use_dst_trigin),
    .dst_trigin_type(dst_trigin_type),   
    .dst_trigin_sel(dst_trigin_sel),
    .trigout_type(use_trigout),
    .trigout_type(trigout_type), 
    .trigout_sel(trigout_sel),
    .src_trig_req(src_trig_req),
    .src_trig_req_type(src_trig_req_type),
    .dst_trig_req(dst_trig_req),
    .dst_trig_req_type(dst_trig_req_type),
    .ch_src_ack(ch_src_ack), 
    .ch_src_ack_type(ch_dst_ack),
    .ch_dst_ack(ch_dst_ack),
    .ch_dst_ack_type(ch_dst_ack_type),
    .ch_trigout_req(ch_trigout_req),
    .ch_trigout_ack(ch_trigout_ack),
    .SRCTRIGINSELERR(SRCTRIGINSELERR), 
    .DESTRIGINSELERR(DESTRIGINSELERR), 
    .TRIGOUTSELERR(TRIGOUTSELERR)
    );*/
    


endmodule

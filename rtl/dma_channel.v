module dma_channel
#(parameter WIDTH = 32,
    parameter DATA_W = 128 )
(
    input wire clk,resetn,                 
    // reg bank signals
    input wire [WIDTH-1 : 0] cfg_CH_CMD,
    input wire [WIDTH-1 : 0] cfg_CH_STATUS,
    input wire [WIDTH-1 : 0] cfg_CH_INTREN,
    input wire [WIDTH-1 : 0] cfg_CH_CTRL,
    input wire [WIDTH-1 : 0] cfg_CH_SRCADDR,
    input wire [WIDTH-1 : 0] cfg_CH_DESADDR,
    input wire [WIDTH-1 : 0] cfg_CH_XSIZE,
    input wire [WIDTH-1 : 0] cfg_CH_SRCTRANSCFG,
    input wire [WIDTH-1 : 0] cfg_CH_DESTRANSCFG,
    input wire [WIDTH-1 : 0] cfg_CH_XADDRINC,
    input wire [WIDTH-1 : 0] cfg_CH_FILLVAL,
    input wire [WIDTH-1 : 0] cfg_CH_SRCTRIGINCFG,
    input wire [WIDTH-1 : 0] cfg_CH_DESTRIGINCFG,
    input wire [WIDTH-1 : 0] cfg_CH_TRIGOUTCFG,
    input wire [WIDTH-1 : 0] cfg_LINKADDR,
    
    input wire chn_cmd_wr_en_o,
    input wire chn_stat_wr_en_o,
    input wire chn_intren_wr_en_o,
    input wire chn_ctrl_wr_en_o,
    input wire chn_srcaddr_wr_en_o,
    input wire chn_desaddr_wr_en_o,
    input wire chn_xsize_wr_en_o,
    input wire chn_srctrans_wr_en_o,
    input wire chn_destrans_wr_en_o,
    input wire chn_xaddrinc_wr_en_o,
    input wire chn_fillval_wr_en_o,
    input wire chn_srctrigin_wr_en_o,
    input wire chn_destrigin_wr_en_o,
    input wire chn_trigout_wr_en_o,
    input wire chn_linkaddr_wr_en_o,




    //inter reg signals    
    output wire [(WIDTH*2)-1 : 0] chn_reg_out,              
    output wire reg_wr_en,         
    output  wire IRQ,
    //cmd fsm signal
     input wire ARREADY,
     input wire RID,
     input wire [DATA_W-1 : 0]RDATA_I,
     input wire [1:0]RRESP,
     input wire RLAST,
     input wire RVALID,
     
     input wire ARREADY_D,
     input wire RID_D,
     input wire [DATA_W-1 : 0]RDATA_I_D,
     input wire [1:0]RRESP_D,
     input wire RLAST_D,
     input wire RVALID_D,
     
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
    
    output wire stat_err,
     
     
     
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

wire cmd_done_1;
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
//wire stat_err; // made it as in output wire for trig matrix
wire DONE;
wire wr_en;

// wires to internal reg from data fsm( stat and cmd)
  wire STAT_TRIGOUTACKWAIT_DATA;
  wire STAT_DESTRIGINWAIT_DATA;
  wire STAT_SRCTRIGINWAIT_DATA;
  wire STAT_RESUMEWAIT_DATA;
  wire STAT_STOPPED_DATA;
  wire STAT_PAUSED_DATA;
  wire STAT_DISABLED_DATA;
  wire STAT_DONE_DATA;
 
  wire ENABLECMD_DATA;
  wire DISABLECMD_DATA;
  wire STOPCMD_DATA;

// wires to cmd fsm
  //  wire [31:0]LINKADDR;
 // wire data_done;
   wire [31:0] RDATA_O;
   wire [31:0] LINK_HEADER;
   wire [5:0] wptr;
   wire LINKHDERR;
   wire CMD_DONE,STAT_CMD_DONE; //done signal to data fsm
   wire AXIRDRESPERR;//address out of range error
   wire AXIRDPOISERR;//corrupted data error
   wire BUSERR;//any axi error assterts this
    
    //wires to trig mtx
    
    wire [1:0] des_trigin_ack_type;
    wire [1:0] src_trigin_ack_type;
    wire trig_out_req;
    wire des_trigack;
    wire src_trigack;
    wire stat_done_intr_reg ,stat_disable_intr_reg,stat_stopped_intr_reg ,stat_err_intr_reg ;
assign wr_en =chn_ctrl_wr_en_o || chn_stat_wr_en_o || chn_intren_wr_en_o || chn_ctrl_wr_en_o || 
                        chn_srcaddr_wr_en_o || chn_desaddr_wr_en_o || chn_xsize_wr_en_o 
                        || chn_srctrans_wr_en_o || chn_destrans_wr_en_o || chn_xaddrinc_wr_en_o || 
                        chn_fillval_wr_en_o || chn_srctrigin_wr_en_o || chn_destrigin_wr_en_o || 
                        chn_trigout_wr_en_o || chn_linkaddr_wr_en_o;

wire cmd_done_stop;
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
  .STAT_TRIGOUTACKWAIT_DATA(STAT_TRIGOUTACKWAIT_DATA),
  .STAT_DESTRIGINWAIT_DATA(STAT_DESTRIGINWAIT_DATA),
  .STAT_SRCTRIGINWAIT_DATA(STAT_SRCTRIGINWAIT_DATA),
  .STAT_RESUMEWAIT_DATA(STAT_RESUMEWAIT_DATA),
  .STAT_STOPPED_DATA(STAT_STOP_DATA),
  .STAT_PAUSED_DATA(STAT_PAUSED_DATA),
  .STAT_DISABLED_DATA(STAT_DISABLE_DATA),
  .STAT_DONE_DATA(STAT_DONE_DATA),
   .ENABLECMD_DATA(ENABLECMD_DATA),
   .DISABLECMD_DATA(DISABLECMD_DATA),
   .STOPCMD_DATA(STOPCMD_DATA),
  .chn_reg_out(chn_reg_out),
  //.ch_wr_en_o(ch_wr_en_o),
   .reg_wr_en(reg_wr_en),
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
  .stat_done_intr_reg(stat_done_intr_reg),
  .stat_disable_intr_reg(stat_disable_intr_reg),
  .stat_stopped_intr_reg (stat_stopped_intr_reg ),
  .stat_err_intr_reg (stat_err_intr_reg ),
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
      .STAT_ERROR_PARTSEL(stat_err_partsel),
      .LINKADDR(linkaddr),
      .link_enable(linkaddren),
      .wr_en(wr_en),
      .cmd_done_stop(cmd_done_stop),
      .data_done(DONE),
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
      .LINKHDRERR(LINKHDERR),
      .CMD_DONE(CMD_DONE),
      .STAT_CMD_DONE(STAT_CMD_DONE),
      .AXIRDRESPERR(AXIRDRESPERR_CMDFSM),
      .AXIRDPOISERR(AXIRDPOISERR_CMDFSM),
      .BUSERR(BUSERR_CMDFSM),
      .cmd_done_1(cmd_done_1)
      );
      
      mux_logic  #(.WIDTH (32))
      dut3  (.cmd_data(RDATA_O),
       .clk(clk),
       .resetn(resetn),
       .wptr(wptr),
       .data_done(DONE),
       .cmd_done(STAT_CMD_DONE),
      // .cmd_done_stop(cmd_done_stop),
       .link_en(linkaddren),
       .header_in(LINK_HEADER),
       .CH_STATUS(CH_STATUS_O),
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
        .chn_linkaddr_wr_en_o  (chn_linkaddr_wr_en_o),
        .mux_out_reg(mux_logic_in)
       );               
      
    data_fsm dut4(
    .clk(clk),
    .resetn(resetn),
    .stat_error_intr_reg(stat_err_intr_reg),
    .stat_done_intr_reg(stat_done_intr_reg),
    .link_en(linkaddren),
    .enable_cmd_partsel(enable_cmd),
    .pause_cmd_partsel(pause_cmd),
    .disable_cmd_partsel(disable_cmd),
    .stop_cmd_partsel(stop_cmd),
    . resume_cmd_partsel(resume_cmd),
    .cmd_done(CMD_DONE),
    .stat_disable_intr_reg(stat_disable_intr_reg),
    .stat_stop_intr_reg(stat_stopped_intr_reg),
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
    .trig_out_ack_sw(trigout_ack_sw),
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
    .ARREADY(ARREADY_D),
    .ARVALID(ARVALID_D),
    .ARADDR(ARADDR_D),
    .ARSIZE(ARSIZE_D),
    .ARBURST(ARBURST_D),
    .ARID(ARID_D),
    .ARLEN(ARLEN_D),
    .RVALID(RVALID_D),
    .RDATA(RDATA_I_D),
    .RRESP(RRESP_D),
    .RLAST(RLAST_D),
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
    .cmd_done_stop(cmd_done_stop),
    .STAT_DONE_DATA(STAT_DONE_DATA));
    
    

    


endmodule

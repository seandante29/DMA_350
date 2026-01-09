module dma_channel
#(parameter WIDTH = 32)
(
    input wire clk,resetn,                 
    // reg bank signals
    input wire [(WIDTH * 14) -1:0] reg_chn_in, // from reg bank       
    //inter reg signals    
    output wire [(WIDTH*2)-1 : 0] chn_reg_out,                       
    output  wire IRQ,
    //cmd fsm signal
     input wire ARREADY,
     input wire RID,
     input wire [31:0]RDATA_I,
     input wire [1:0]RRESP,
     input wire RLAST,
     input wire RVALID,
     input wire data_done,
     input wire linkaddren,
     
     // to sys mem
      output wire [3:0] ARID,
      output wire [3:0] ARLEN,
      output wire[2:0] ARSIZE,
      output wire [1:0] ARBURST,
      output wire ARVALID,
      output wire [31:0]ARADDR,
      output wire RREADY                           
);

wire [(WIDTH * 14) -1:0]  mux_logic_in;

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
 
wire use_trigout;
wire use_des_trigin;
wire use_src_trigin;
wire [2:0] x_type;
wire [2:0] transize;
wire [15:0] srcxsize;
wire [15:0] desxsize;
wire [29:0] linkaddr;
wire linkaddren1;
wire enable_cmd;
wire disable_cmd;
wire pause_cmd;
wire resume_cmd;
wire src_trigin_sw;
wire [1:0]  src_trigin_sw_type;
wire des_trigin_sw;
wire [1:0] des_trigin_sw_type;
wire trigout_ack_sw;
wire [1:0] src_trigin_mode;
wire [1:0] src_trigin_type;
wire [7:0] src_trigin_sel;
wire [1:0] des_trigin_mode;
wire [1:0] des_trigin_type;
wire [7:0] des_trigin_sel;
wire [1:0] trigout_type;
wire [5:0] trigout_sel;
wire [31:0] src_addr;
wire [31:0] des_addr;
wire [31:0] fillval;
wire [15:0] src_xaddr_inc;
wire [15:0] des_xaddr_inc;
wire stat_done;
wire stat_err;

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
  .STAT_ERR(STAT_ERR),
  .STAT_DONE(STAT_DONE),
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
    .linkaddren(linkaddren1),
    .enable_cmd(enable_cmd),
    .disable_cmd(disable_cmd),
    .pause_cmd(pause_cmd),
    .resume_cmd(resume_cmd),
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
                               
                             
    


endmodule


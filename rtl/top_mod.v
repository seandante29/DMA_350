module top_mod#( 
    parameter WIDTH = 32,
    parameter DATA_W = 128,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH =  DATA_WIDTH/8,
    parameter ID_W       =4,
    parameter DEPTH =145,
    parameter ADDR_W =32  
)
    (// apb_reg interface
      input wire clk,
      input wire resetn,
//      input wire PCLK,
//      input wire PRESETn,
      input wire [ ADDR_WIDTH-1 : 0 ] PADDR,
      input wire PWRITE,
      input wire PENABLE,
      input wire PSEL,
      
      input wire boot_en,
      input wire [29:0] boot_addr,
    //  input  wire [(WIDTH*2)-1 : 0] chn_reg_in,
      input wire [DATA_WIDTH-1 : 0] PWDATA,
      input wire [STRB_WIDTH-1 : 0] PSTRB,
      
      // going back to cpu
      output wire [DATA_WIDTH-1 : 0] PRDATA,
      output wire PREADY,
      output wire PSLVERR,
      

      // trigger matrix

    input  wire        trig0_req,
    input  wire [1:0]  trig0_req_type,
    output wire         trig0_ack,
    output wire  [1:0]  trig0_ack_type,

    input  wire        trig1_req,
    input  wire [1:0]  trig1_req_type,
    output wire         trig1_ack,
    output wire  [1:0]  trig1_ack_type,
    output wire         trig0_out_req,
    input  wire        trig0_out_ack,
    output wire         trig1_out_req,
    input  wire        trig1_out_ack,
      
     //AXI signals 
    input wire ARREADY,
     input wire [ID_W -1 : 0]RID,
     input wire [DATA_W-1 : 0]RDATA_I,
     input wire [1:0]RRESP,
     input wire RLAST,
     input wire RVALID,

     
//     input wire ARREADY_D,
//     input wire RID_D,
//     input wire [DATA_W-1 : 0]RDATA_I_D,
//     input wire [1:0]RRESP_D,
//     input wire RLAST_D,
//     input wire RVALID_D,
     
     input wire WREADY,
     input wire AWREADY,
     input wire [ID_W-1 : 0] BID,
     input wire BVALID,
     input wire [1:0] BRESP,
 
      output wire [3:0] ARQOS,AWQOS,
       output wire [ID_W -1 : 0] ARID,
      output wire [7:0] ARLEN,
      output wire[2:0] ARSIZE,
      output wire [1:0] ARBURST,
      output wire ARVALID,
      output wire [ADDR_W-1:0]ARADDR,
      output wire RREADY,      
      
//      output wire [3:0] ARID_D,
//      output wire [3:0] ARLEN_D,
//      output wire[2:0] ARSIZE_D,
//      output wire [1:0] ARBURST_D,
//      output wire ARVALID_D,
//      output wire [31:0]ARADDR_D,
//      output wire RREADY_D ,
      output wire [(DATA_W/8)-1:0] WSTRB,
      output wire [ID_W -1 : 0] AWID_D,
      output wire [7:0] AWLEN_D,
      output wire[2:0] AWSIZE_D,
      output wire [1:0] AWBURST_D,
      output wire AWVALID_D,
      output wire [ADDR_W-1:0]AWADDR_D,
      output wire WVALID_D,
      output wire [DATA_W -1 :0] WDATA_D,
      output wire WLAST_D,
      output wire BREADY_D,
      output  wire IRQ
    );
    wire enable_cmd_to_apb;
    wire [(WIDTH*3)-1 : 0]  src_des_x_transfer_count_updated;
    wire reg_wr_en;
      wire  [(WIDTH * 17) -1:0] reg_chn_out;
      wire [(WIDTH*18)-1 : 0] chn_reg_out;
     // wire ch_wr_en_o;
      // from channel to trigger matrix
   wire        use_src_trigin;
   wire [1:0]  src_trigin_type;   // 2'b10 = HW
   wire [7:0]  src_trigin_sel;  // 0 = trig0, 1 = trig1  for peripheral 1 and 2 respectively
   wire        use_des_trigin;
   wire [1:0]  des_trigin_type;   // 2'b10 = HW
   wire [7:0]  des_trigin_sel;   // 0 = trig0, 1 = trig1
   wire        use_trigout;
   wire [1:0]  trigout_type;    // 2'b10 = HW
   wire [5:0]  trigout_sel;      // 0 = trig0, 1 = trig1
   
//  wire [31:0] cfg_read_template_data;
//      wire [31:0] cfg_write_template_data;
//      wire [31:0] cfg_template_config;
//      wire chn_tmpltcfg_wr_en_o,chn_destmplt_wr_en_o,chn_srctmplt_wr_en_o;
       // To DMA Channel (REQ view)
    wire src_trig_req;
    wire [1:0]  src_trig_req_type;
    wire des_trig_req;
    wire [1:0]  des_trig_req_type;
    wire        ch_src_ack;
    wire [1:0]  ch_src_ack_type;
    wire        ch_des_ack;
    wire [1:0]  ch_des_ack_type;
    wire        ch_trigout_req;
    wire ch_trigout_ack;
 
    wire SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR;
      
    wire chn_wr_en;
    
wire [WIDTH-1 : 0] cfg_channel_start;
wire [WIDTH-1 : 0] cfg_channel_status;
wire [WIDTH-1 : 0] cfg_interrupt_enable;
wire [WIDTH-1 : 0] cfg_control_config;
wire [WIDTH-1 : 0] cfg_read_base_addr;
wire [WIDTH-1 : 0] cfg_write_base_addr;
wire [WIDTH-1 : 0] cfg_x_transfer_count;
wire [WIDTH-1 : 0] cfg_read_transfer_cfg;
wire [WIDTH-1 : 0] cfg_write_transfer_cfg;
wire [WIDTH-1 : 0] cfg_addr_increment_cfg;
wire [WIDTH-1 : 0] cfg_fill_data;
wire [WIDTH-1 : 0] cfg_read_trigger_cfg;
wire [WIDTH-1 : 0] cfg_write_trigger_cfg;
wire [WIDTH-1 : 0] cfg_trigger_out_cfg;
wire [WIDTH-1 : 0] cfg_auto_restart_config;
wire [WIDTH-1 : 0] cfg_next_cmd_addr,cfg_line_stride,cfg_y_transfer_count;
wire [31:0] cfg_read_template_data;
wire [31:0] cfg_write_template_data;
wire [31:0] cfg_template_config;
wire [WIDTH-1:0] wrkregval_rd;

wire chn_cmd_wr_en_o;
wire chn_stat_wr_en_o;
wire chn_intren_wr_en_o;
wire chn_ctrl_wr_en_o;
wire chn_read_base_addr_wr_en_o;
wire chn_write_base_addr_wr_en_o;
wire chn_x_transfer_count_wr_en_o;
wire chn_srctrans_wr_en_o;
wire chn_destrans_wr_en_o;
wire chn_xaddrinc_wr_en_o;
wire chn_fillval_wr_en_o;
wire chn_srctrigin_wr_en_o;
wire chn_destrigin_wr_en_o;
wire chn_trigout_wr_en_o;
wire chn_next_cmd_addr_wr_en_o;
wire chn_autocfg_wr_en_o,chn_yaddrestride_wr_en_o,chn_y_transfer_count_wr_en_o,chn_srctmplt_wr_en_o,chn_destmplt_wr_en_o,chn_tmpltcfg_wr_en_o,chn_work_reg_pointer_wr_en_o;

wire [31:0] cfg_work_reg_pointer,y_transfer_count_UPDATED;
wire stop_cmd_apb;wire [31:0] read_base_addr_UPDATED;wire [31:0]  write_base_addr_UPDATED;wire [31:0]  x_transfer_count_UPDATED;  
    dma_channel #(
    .WIDTH(WIDTH),
    .DATA_W(DATA_W),
    .ID_W(ID_W),
    .DEPTH(DEPTH),
    .ADDR_W(ADDR_W)
) dut0 (
    // Clock and Reset
    .clk                (clk),
    .resetn             (resetn),
      .boot_addr(boot_addr),
  .boot_en(boot_en),
    // Configuration Interface
    .chn_reg_out        (chn_reg_out),
    .reg_wr_en (reg_wr_en),
    .IRQ                (IRQ),
    .ARQOS(ARQOS),
    .AWQOS(AWQOS),
    .stat_err (stat_err),
    .cfg_channel_start            (cfg_channel_start),
    .cfg_channel_status         (cfg_channel_status),
    .cfg_interrupt_enable         (cfg_interrupt_enable),
    .cfg_control_config           (cfg_control_config),
    .cfg_read_base_addr        (cfg_read_base_addr),
    .cfg_write_base_addr        (cfg_write_base_addr),
    .cfg_x_transfer_count          (cfg_x_transfer_count),
    .cfg_read_transfer_cfg    (cfg_read_transfer_cfg),
    .cfg_write_transfer_cfg    (cfg_write_transfer_cfg),
    .cfg_addr_increment_cfg       (cfg_addr_increment_cfg),
    .cfg_fill_data        (cfg_fill_data),
    .cfg_read_trigger_cfg   (cfg_read_trigger_cfg),
    .cfg_write_trigger_cfg   (cfg_write_trigger_cfg),
    .cfg_trigger_out_cfg     (cfg_trigger_out_cfg),
    .cfg_next_cmd_addr          (cfg_next_cmd_addr),
    .cfg_line_stride    (cfg_line_stride),
    .cfg_y_transfer_count          (cfg_y_transfer_count),
    .cfg_auto_restart_config        (cfg_auto_restart_config),
    .cfg_read_template_data       (cfg_read_template_data),
    .cfg_write_template_data       (cfg_write_template_data),
    .cfg_template_config       (cfg_template_config),
    .chn_autocfg_wr_en_o   (chn_autocfg_wr_en_o),
    .chn_srctmplt_wr_en_o  (chn_srctmplt_wr_en_o),
    .chn_destmplt_wr_en_o  (chn_destmplt_wr_en_o),
    .chn_tmpltcfg_wr_en_o  (chn_tmpltcfg_wr_en_o),
    .chn_cmd_wr_en_o       (chn_cmd_wr_en_o),
    .chn_stat_wr_en_o      (chn_stat_wr_en_o),
    .chn_intren_wr_en_o    (chn_intren_wr_en_o),
    .chn_ctrl_wr_en_o      (chn_ctrl_wr_en_o),
    .chn_read_base_addr_wr_en_o   (chn_read_base_addr_wr_en_o),
    .chn_write_base_addr_wr_en_o   (chn_write_base_addr_wr_en_o),
    .chn_x_transfer_count_wr_en_o     (chn_x_transfer_count_wr_en_o),
    .chn_srctrans_wr_en_o  (chn_srctrans_wr_en_o),
    .chn_destrans_wr_en_o  (chn_destrans_wr_en_o),
    .chn_xaddrinc_wr_en_o  (chn_xaddrinc_wr_en_o),
    .chn_fillval_wr_en_o   (chn_fillval_wr_en_o),
    .chn_srctrigin_wr_en_o (chn_srctrigin_wr_en_o),
    .chn_destrigin_wr_en_o (chn_destrigin_wr_en_o),
    .chn_trigout_wr_en_o   (chn_trigout_wr_en_o),
        .chn_work_reg_pointer_wr_en_o(chn_work_reg_pointer_wr_en_o),
    .chn_next_cmd_addr_wr_en_o  (chn_next_cmd_addr_wr_en_o),
    .chn_y_transfer_count_wr_en_o(chn_y_transfer_count_wr_en_o),
    .chn_yaddrestride_wr_en_o(chn_yaddrestride_wr_en_o),
    .y_transfer_count_UPDATED(y_transfer_count_UPDATED),
    .enable_cmd_to_apb(enable_cmd_to_apb),
    // AXI Read Address/Data (General/Descriptor)
    .ARID               (ARID),
    .ARADDR             (ARADDR),
    .ARLEN              (ARLEN),
    .ARSIZE             (ARSIZE),
    .ARBURST            (ARBURST),
    .ARVALID            (ARVALID),
    .ARREADY            (ARREADY),
    
    .RID                (RID),
    .RDATA_I            (RDATA_I),
    .RRESP              (RRESP),
    .RLAST              (RLAST),
    .RVALID             (RVALID),
    .RREADY             (RREADY),

//    .RID_D                (RID_D),
//    .RDATA_I_D            (RDATA_I_D),
//    .RRESP_D              (RRESP_D),
//    .RLAST_D              (RLAST_D),
//    .RVALID_D             (RVALID_D),
//    .ARREADY_D             (ARREADY_D),

    // AXI Read Master (Data Specific - _D)
//    .ARID_D             (ARID_D),
//    .ARADDR_D           (ARADDR_D),
//    .ARLEN_D            (ARLEN_D),
//    .ARSIZE_D           (ARSIZE_D),
//    .ARBURST_D          (ARBURST_D),
//    .ARVALID_D          (ARVALID_D),
//    .RREADY_D           (RREADY_D),

    // AXI Write Master (Data Specific - _D)
    .AWID_D             (AWID_D),
    .AWADDR_D           (AWADDR_D),
    .AWLEN_D            (AWLEN_D),
    .AWSIZE_D           (AWSIZE_D),
    .AWBURST_D          (AWBURST_D),
    .AWVALID_D          (AWVALID_D),
    .AWREADY            (AWREADY),
    
    .WDATA_D            (WDATA_D),
    .WVALID_D           (WVALID_D),
    .WLAST_D            (WLAST_D),
    .WREADY             (WREADY),
    .WSTRB(WSTRB),
    
    .BID                (BID),
    .BVALID             (BVALID),
    .BRESP              (BRESP),
    .BREADY_D           (BREADY_D),

    // Trigger and Control Signals
  //  .data_done          (data_done),
   // .next_cmd_addren         (next_cmd_addren),
    .SRCTRIGINSELERR    (SRCTRIGINSELERR),
    .DESTRIGINSELERR    (DESTRIGINSELERR),
    .TRIGOUTSELERR      (TRIGOUTSELERR),

    // Source Trigger Interface
    .src_trig_req       (src_trig_req),
    .src_trig_req_type  (src_trig_req_type),
    .ch_src_ack         (ch_src_ack),
    .ch_src_ack_type    (ch_src_ack_type),
   .use_src_trigin     (use_src_trigin),
   .src_trigin_type    (src_trigin_type),
   .src_trigin_sel     (src_trigin_sel),

    // Destination Trigger Interface
    .des_trig_req       (des_trig_req),
    .des_trig_req_type  (des_trig_req_type),
    .ch_des_ack         (ch_des_ack),
   .ch_des_ack_type    (ch_des_ack_type),
    .use_des_trigin     (use_des_trigin),
    .des_trigin_type    (des_trigin_type),
    .des_trigin_sel     (des_trigin_sel),

    // Trigger Out Interface
    .ch_trigout_req     (ch_trigout_req),
    .ch_trigout_ack     (ch_trigout_ack),
    .use_trigout        (use_trigout),
    .trigout_type       (trigout_type),
    .trigout_sel        (trigout_sel),
    .src_des_x_transfer_count_updated(src_des_x_transfer_count_updated),
    .wrkregval_rd(wrkregval_rd),
    .cfg_work_reg_pointer(cfg_work_reg_pointer),
    .stop_cmd_apb(stop_cmd_apb),
	.read_base_addr_UPDATED(read_base_addr_UPDATED),
	.write_base_addr_UPDATED(write_base_addr_UPDATED),
	.x_transfer_count_UPDATED(x_transfer_count_UPDATED) );
    
    
        trigger_matrix dut1(
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
    .use_des_trigin(use_des_trigin),
    .des_trigin_type(des_trigin_type),   
    .des_trigin_sel(des_trigin_sel),
    .use_trigout(use_trigout),
    .trigout_type(trigout_type), 
    .trigout_sel(trigout_sel),
    
    .src_trig_req(src_trig_req),
    .src_trig_req_type(src_trig_req_type),
    .des_trig_req(des_trig_req),
    .des_trig_req_type(des_trig_req_type),
    .ch_src_ack(ch_src_ack), 
    .ch_src_ack_type(ch_src_ack_type),
    .ch_des_ack(ch_des_ack),
    .ch_des_ack_type(ch_des_ack_type),
    .ch_trigout_req(ch_trigout_req),
    .ch_trigout_ack(ch_trigout_ack),
    .SRCTRIGINSELERR(SRCTRIGINSELERR), 
    .DESTRIGINSELERR(DESTRIGINSELERR), 
    .TRIGOUTSELERR(TRIGOUTSELERR)
    );
    
     apb_reg #(.DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
         .STRB_WIDTH (STRB_WIDTH),
         .WIDTH (WIDTH))
     dut2 (
     
	.read_base_addr_UPDATED(read_base_addr_UPDATED),
	.write_base_addr_UPDATED(write_base_addr_UPDATED),
	.x_transfer_count_UPDATED(x_transfer_count_UPDATED),
    .clk        (clk),
    .resetn     (resetn),
//    .PCLK       (clk),     // single clock
//    .PRESETn    (resetn),
    .PADDR      (PADDR),
    .PWRITE     (PWRITE),
    .PSEL       (PSEL),
    .PENABLE    (PENABLE),
    .PWDATA     (PWDATA),
    .PSTRB      (PSTRB),
    .PRDATA     (PRDATA),
    .PREADY     (PREADY),
    .PSLVERR    (PSLVERR),
    .chn_reg_in (chn_reg_out),
//   .reg_wr_en (reg_wr_en),
.y_transfer_count_UPDATED(y_transfer_count_UPDATED),
      .cfg_channel_start            (cfg_channel_start),
    .cfg_channel_status         (cfg_channel_status),
    .cfg_interrupt_enable         (cfg_interrupt_enable),
    .cfg_control_config           (cfg_control_config),
    .cfg_read_base_addr        (cfg_read_base_addr),
    .cfg_write_base_addr        (cfg_write_base_addr),
    .cfg_x_transfer_count          (cfg_x_transfer_count),
    .cfg_read_transfer_cfg    (cfg_read_transfer_cfg),
    .cfg_write_transfer_cfg    (cfg_write_transfer_cfg),
    .cfg_addr_increment_cfg       (cfg_addr_increment_cfg),
    .cfg_fill_data        (cfg_fill_data),
    .cfg_read_trigger_cfg   (cfg_read_trigger_cfg),
    .cfg_write_trigger_cfg   (cfg_write_trigger_cfg),
    .cfg_trigger_out_cfg     (cfg_trigger_out_cfg),
    .cfg_next_cmd_addr          (cfg_next_cmd_addr),
    .cfg_read_template_data(cfg_read_template_data),
    .cfg_line_stride    (cfg_line_stride),
    .cfg_y_transfer_count          (cfg_y_transfer_count),
        .cfg_write_template_data(cfg_write_template_data),
        .cfg_template_config(cfg_template_config),
        .cfg_auto_restart_config(cfg_auto_restart_config),
    .chn_autocfg_wr_en_o(chn_autocfg_wr_en_o),
.chn_srctmplt_wr_en_o(chn_srctmplt_wr_en_o),
        .chn_destmplt_wr_en_o(chn_destmplt_wr_en_o),
        .chn_tmpltcfg_wr_en_o(chn_tmpltcfg_wr_en_o),
    .chn_cmd_wr_en_o       (chn_cmd_wr_en_o),
    .chn_stat_wr_en_o      (chn_stat_wr_en_o),
    .chn_intren_wr_en_o    (chn_intren_wr_en_o),
    .chn_ctrl_wr_en_o      (chn_ctrl_wr_en_o),
    .chn_read_base_addr_wr_en_o   (chn_read_base_addr_wr_en_o),
    .chn_write_base_addr_wr_en_o   (chn_write_base_addr_wr_en_o),
    .chn_x_transfer_count_wr_en_o     (chn_x_transfer_count_wr_en_o),
    .chn_srctrans_wr_en_o  (chn_srctrans_wr_en_o),
    .chn_destrans_wr_en_o  (chn_destrans_wr_en_o),
    .chn_xaddrinc_wr_en_o  (chn_xaddrinc_wr_en_o),
    .chn_fillval_wr_en_o   (chn_fillval_wr_en_o),
    .chn_srctrigin_wr_en_o (chn_srctrigin_wr_en_o),
    .chn_destrigin_wr_en_o (chn_destrigin_wr_en_o),
    .chn_trigout_wr_en_o   (chn_trigout_wr_en_o),
    .chn_next_cmd_addr_wr_en_o  (chn_next_cmd_addr_wr_en_o),
    .chn_work_reg_pointer_wr_en_o(chn_work_reg_pointer_wr_en_o),
    .chn_y_transfer_count_wr_en_o(chn_y_transfer_count_wr_en_o),
    .chn_yaddrestride_wr_en_o(chn_yaddrestride_wr_en_o),
    .src_des_x_transfer_count_updated(src_des_x_transfer_count_updated),
    .wrkregval_rd(wrkregval_rd),
    .cfg_work_reg_pointer(cfg_work_reg_pointer),
    .stop_cmd_apb(stop_cmd_apb),
    .enable_cmd_to_apb(enable_cmd_to_apb)
  );
    
    
endmodule 

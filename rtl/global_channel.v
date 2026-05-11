module global_channel#(parameter WIDTH = 32,
  parameter ADDR_W = 32,
    parameter DATA_W = 128,
     parameter ID_W   = 4,
     parameter DEPTH = 145
      )
   (//clk reset
    input wire clk,
    input wire resetn,
    //IRQ
    output  wire IRQ,
    //Boot interface
    input wire boot_en,
    input wire [29:0] boot_addr, 

    //AXI signals 
    //peripheral signals
    //AR
     input wire ARREADY,
     output wire [3:0] ARQOS,
     output wire [ID_W -1 : 0] ARID,
     output wire [7:0] ARLEN,
     output wire[2:0] ARSIZE,
     output wire [1:0] ARBURST,
     output wire ARVALID,
     output wire [ADDR_W-1:0]ARADDR,
     //R
     input wire [ID_W -1 : 0]RID,
     input wire [DATA_W-1 : 0]RDATA_I,
     input wire [1:0]RRESP,
     input wire RLAST,
     input wire RVALID,
     output wire RREADY,      
     //AW
     input wire AWREADY,
     output wire [3:0] AWQOS,
     output wire [ID_W -1 : 0] AWID_D,
     output wire [7:0] AWLEN_D,
     output wire[2:0] AWSIZE_D,
     output wire [1:0] AWBURST_D,
     output wire AWVALID_D,
     output wire [ADDR_W-1:0]AWADDR_D,
     //W
     input wire WREADY,
     output wire [(DATA_W/8)-1:0] WSTRB,
     output wire WVALID_D,
     output wire [DATA_W -1 :0] WDATA_D,
     output wire WLAST_D,
     //B
     input wire [ID_W-1 : 0] BID,
     input wire BVALID,
     input wire [1:0] BRESP,
     output wire BREADY_D,
     

     
    
    // CH0_apb_reg IO'S
    
    input wire [31:0] cfg_work_reg_pointer_ch0,
    input wire [WIDTH-1 : 0] cfg_channel_start_ch0,
    input wire [WIDTH-1 : 0] cfg_channel_status_ch0,
    input wire [WIDTH-1 : 0] cfg_interrupt_enable_ch0,
    input wire [WIDTH-1 : 0] cfg_control_config_ch0,
    input wire [WIDTH-1 : 0] cfg_read_base_addr_ch0,
    input wire [WIDTH-1 : 0] cfg_write_base_addr_ch0,
    input wire [WIDTH-1 : 0] cfg_x_transfer_count_ch0,
    input wire [WIDTH-1 : 0] cfg_read_transfer_cfg_ch0,
    input wire [WIDTH-1 : 0] cfg_write_transfer_cfg_ch0,
    input wire [WIDTH-1 : 0] cfg_addr_increment_cfg_ch0,
    input wire [WIDTH-1 : 0] cfg_fill_data_ch0,
    input wire [WIDTH-1 : 0] cfg_read_trigger_cfg_ch0,
    input wire [WIDTH-1 : 0] cfg_write_trigger_cfg_ch0,
    input wire [WIDTH-1 : 0] cfg_trigger_out_cfg_ch0,
    input wire [WIDTH-1 : 0] cfg_auto_restart_config_ch0,
    input wire [WIDTH-1 : 0] cfg_next_cmd_addr_ch0,
    input wire [31:0] cfg_line_stride_ch0,
    input wire [31:0] cfg_y_transfer_count_ch0,
    input wire [31:0] cfg_read_template_data_ch0,
    input wire [31:0] cfg_write_template_data_ch0,
    input wire [31:0] cfg_template_config_ch0,
    input wire [WIDTH-1:0] wrkregval_rd_ch0,
    
    input wire chn_autocfg_wr_en_o_ch0,
    input wire chn_yaddrestride_wr_en_o_ch0,
    input wire chn_y_transfer_count_wr_en_o_ch0,
    input wire chn_srctmplt_wr_en_o_ch0,
    input wire chn_destmplt_wr_en_o_ch0,
    input wire chn_tmpltcfg_wr_en_o_ch0,
    input wire chn_work_reg_pointer_wr_en_o_ch0,
    input wire chn_cmd_wr_en_o_ch0,
    input wire chn_stat_wr_en_o_ch0,
    input wire chn_intren_wr_en_o_ch0,
    input wire chn_ctrl_wr_en_o_ch0,
    input wire chn_read_base_addr_wr_en_o_ch0,
    input wire chn_write_base_addr_wr_en_o_ch0,
    input wire chn_x_transfer_count_wr_en_o_ch0,
    input wire chn_srctrans_wr_en_o_ch0,
    input wire chn_destrans_wr_en_o_ch0,
    input wire chn_xaddrinc_wr_en_o_ch0,
    input wire chn_fillval_wr_en_o_ch0,
    input wire chn_srctrigin_wr_en_o_ch0,
    input wire chn_destrigin_wr_en_o_ch0,
    input wire chn_trigout_wr_en_o_ch0,
    input wire chn_next_cmd_addr_wr_en_o_ch0, 
    
    output wire enable_cmd_to_apb_ch0,
    output wire [(WIDTH*18)-1 : 0] chn_reg_out_ch0,
    output wire reg_wr_en_ch0,
    output wire stat_err_ch0,
    output wire [31:0] y_transfer_count_UPDATED_ch0,
    output wire [(WIDTH*3)-1 : 0] src_des_x_transfer_count_updated_ch0,
    output wire stop_cmd_apb_ch0,
    output wire [31:0] read_base_addr_UPDATED_ch0,
    output wire [31:0] write_base_addr_UPDATED_ch0,
    output wire [31:0] x_transfer_count_UPDATED_ch0,
     // CH1_apb_reg IO'S
    
    
    input wire [31:0] cfg_work_reg_pointer_ch1,
    input wire [WIDTH-1 : 0] cfg_channel_start_ch1,
    input wire [WIDTH-1 : 0] cfg_channel_status_ch1,
    input wire [WIDTH-1 : 0] cfg_interrupt_enable_ch1,
    input wire [WIDTH-1 : 0] cfg_control_config_ch1,
    input wire [WIDTH-1 : 0] cfg_read_base_addr_ch1,
    input wire [WIDTH-1 : 0] cfg_write_base_addr_ch1,
    input wire [WIDTH-1 : 0] cfg_x_transfer_count_ch1,
    input wire [WIDTH-1 : 0] cfg_read_transfer_cfg_ch1,
    input wire [WIDTH-1 : 0] cfg_write_transfer_cfg_ch1,
    input wire [WIDTH-1 : 0] cfg_addr_increment_cfg_ch1,
    input wire [WIDTH-1 : 0] cfg_fill_data_ch1,
    input wire [WIDTH-1 : 0] cfg_read_trigger_cfg_ch1,
    input wire [WIDTH-1 : 0] cfg_write_trigger_cfg_ch1,
    input wire [WIDTH-1 : 0] cfg_trigger_out_cfg_ch1,
    input wire [WIDTH-1 : 0] cfg_auto_restart_config_ch1,
    input wire [WIDTH-1 : 0] cfg_next_cmd_addr_ch1,
    input wire [31:0] cfg_line_stride_ch1,
    input wire [31:0] cfg_y_transfer_count_ch1,
    input wire [31:0] cfg_read_template_data_ch1,
    input wire [31:0] cfg_write_template_data_ch1,
    input wire [31:0] cfg_template_config_ch1,
    input wire [WIDTH-1:0] wrkregval_rd_ch1,
    
    input wire chn_autocfg_wr_en_o_ch1,
    input wire chn_yaddrestride_wr_en_o_ch1,
    input wire chn_y_transfer_count_wr_en_o_ch1,
    input wire chn_srctmplt_wr_en_o_ch1,
    input wire chn_destmplt_wr_en_o_ch1,
    input wire chn_tmpltcfg_wr_en_o_ch1,
    input wire chn_work_reg_pointer_wr_en_o_ch1,
    input wire chn_cmd_wr_en_o_ch1,
    input wire chn_stat_wr_en_o_ch1,
    input wire chn_intren_wr_en_o_ch1,
    input wire chn_ctrl_wr_en_o_ch1,
    input wire chn_read_base_addr_wr_en_o_ch1,
    input wire chn_write_base_addr_wr_en_o_ch1,
    input wire chn_x_transfer_count_wr_en_o_ch1,
    input wire chn_srctrans_wr_en_o_ch1,
    input wire chn_destrans_wr_en_o_ch1,
    input wire chn_xaddrinc_wr_en_o_ch1,
    input wire chn_fillval_wr_en_o_ch1,
    input wire chn_srctrigin_wr_en_o_ch1,
    input wire chn_destrigin_wr_en_o_ch1,
    input wire chn_trigout_wr_en_o_ch1,
    input wire chn_next_cmd_addr_wr_en_o_ch1,
    
    output wire enable_cmd_to_apb_ch1,
    output wire [(WIDTH*18)-1 : 0] chn_reg_out_ch1,
    output wire reg_wr_en_ch1,
    output wire stat_err_ch1,
    output wire [31:0] y_transfer_count_UPDATED_ch1,
    output wire [(WIDTH*3)-1 : 0] src_des_x_transfer_count_updated_ch1,
    output wire stop_cmd_apb_ch1,
    output wire [31:0] read_base_addr_UPDATED_ch1,
    output wire [31:0] write_base_addr_UPDATED_ch1,
    output wire [31:0] x_transfer_count_UPDATED_ch1,
    
   // CH2_apb_reg IO'S
    input wire [31:0] cfg_work_reg_pointer_ch2,
    input wire [WIDTH-1 : 0] cfg_channel_start_ch2,
    input wire [WIDTH-1 : 0] cfg_channel_status_ch2,
    input wire [WIDTH-1 : 0] cfg_interrupt_enable_ch2,
    input wire [WIDTH-1 : 0] cfg_control_config_ch2,
    input wire [WIDTH-1 : 0] cfg_read_base_addr_ch2,
    input wire [WIDTH-1 : 0] cfg_write_base_addr_ch2,
    input wire [WIDTH-1 : 0] cfg_x_transfer_count_ch2,
    input wire [WIDTH-1 : 0] cfg_read_transfer_cfg_ch2,
    input wire [WIDTH-1 : 0] cfg_write_transfer_cfg_ch2,
    input wire [WIDTH-1 : 0] cfg_addr_increment_cfg_ch2,
    input wire [WIDTH-1 : 0] cfg_fill_data_ch2,
    input wire [WIDTH-1 : 0] cfg_read_trigger_cfg_ch2,
    input wire [WIDTH-1 : 0] cfg_write_trigger_cfg_ch2,
    input wire [WIDTH-1 : 0] cfg_trigger_out_cfg_ch2,
    input wire [WIDTH-1 : 0] cfg_auto_restart_config_ch2,
    input wire [WIDTH-1 : 0] cfg_next_cmd_addr_ch2,
    input wire [31:0] cfg_line_stride_ch2,
    input wire [31:0] cfg_y_transfer_count_ch2,
    input wire [31:0] cfg_read_template_data_ch2,
    input wire [31:0] cfg_write_template_data_ch2,
    input wire [31:0] cfg_template_config_ch2,
    input wire [WIDTH-1:0] wrkregval_rd_ch2,
    
    input wire chn_autocfg_wr_en_o_ch2,
    input wire chn_yaddrestride_wr_en_o_ch2,
    input wire chn_y_transfer_count_wr_en_o_ch2,
    input wire chn_srctmplt_wr_en_o_ch2,
    input wire chn_destmplt_wr_en_o_ch2,
    input wire chn_tmpltcfg_wr_en_o_ch2,
    input wire chn_work_reg_pointer_wr_en_o_ch2,
    input wire chn_cmd_wr_en_o_ch2,
    input wire chn_stat_wr_en_o_ch2,
    input wire chn_intren_wr_en_o_ch2,
    input wire chn_ctrl_wr_en_o_ch2,
    input wire chn_read_base_addr_wr_en_o_ch2,
    input wire chn_write_base_addr_wr_en_o_ch2,
    input wire chn_x_transfer_count_wr_en_o_ch2,
    input wire chn_srctrans_wr_en_o_ch2,
    input wire chn_destrans_wr_en_o_ch2,
    input wire chn_xaddrinc_wr_en_o_ch2,
    input wire chn_fillval_wr_en_o_ch2,
    input wire chn_srctrigin_wr_en_o_ch2,
    input wire chn_destrigin_wr_en_o_ch2,
    input wire chn_trigout_wr_en_o_ch2,
    input wire chn_next_cmd_addr_wr_en_o_ch2,
    
    output wire enable_cmd_to_apb_ch2,
    output wire [(WIDTH*18)-1 : 0] chn_reg_out_ch2,
    output wire reg_wr_en_ch2,
    output wire stat_err_ch2,
    output wire [31:0] y_transfer_count_UPDATED_ch2,
    output wire [(WIDTH*3)-1 : 0] src_des_x_transfer_count_updated_ch2,
    output wire stop_cmd_apb_ch2,
    output wire [31:0] read_base_addr_UPDATED_ch2,
    output wire [31:0] write_base_addr_UPDATED_ch2,
    output wire [31:0] x_transfer_count_UPDATED_ch2,
     // trigger
   input wire [2:0]SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR,
   input wire [2:0]src_trig_req,
   input wire [5:0]  src_trig_req_type,
   input wire [2:0]des_trig_req,
   input wire [5:0]  des_trig_req_type,
   output wire [2:0]       ch_src_ack,
   output wire [5:0]  ch_src_ack_type,
   output wire [2:0]       ch_des_ack,
   output wire [5:0]  ch_des_ack_type,
   output wire [2:0]       ch_trigout_req,
   output wire [2:0]ch_trigout_ack,
    
    
    
    // from channel to trigger matrix
   output wire [2:0]       use_src_trigin,
   output wire [5:0]  src_trigin_type,   // 2'b10 = HW
   output wire [23:0]  src_trigin_sel,  // 0 = trig0, 1 = trig1  for peripheral 1 and 2 respectively
   output wire [2:0]       use_des_trigin,
   output wire [5:0]  des_trigin_type,   // 2'b10 = HW
   output wire [23:0]  des_trigin_sel,   // 0 = trig0, 1 = trig1
   output wire [2:0]       use_trigout,
   output wire [5:0]  trigout_type,    // 2'b10 = HW
   output wire [17:0]  trigout_sel      // 0 = trig0, 1 = trig1    
   );
   
   // ==========================
// CH0 AXI MASTER SIGNALS
// ==========================

// AR Channel
wire [ID_W-1:0]     ARID_ch0;
wire [7:0]          ARLEN_ch0;
wire [2:0]          ARSIZE_ch0;
wire [1:0]          ARBURST_ch0;
wire                ARVALID_ch0;
wire [ADDR_W-1:0]   ARADDR_ch0;
wire [3:0]          ARQOS_ch0;
wire                ARREADY_ch0;

// R Channel
wire [ID_W-1:0]     RID_ch0;
wire [DATA_W-1:0]   RDATA_I_ch0;
wire [1:0]          RRESP_ch0;
wire                RLAST_ch0;
wire                RVALID_ch0;
wire                RREADY_ch0;

// AW Channel
wire [ID_W-1:0]     AWID_ch0;
wire [7:0]          AWLEN_ch0;
wire [2:0]          AWSIZE_ch0;
wire [1:0]          AWBURST_ch0;
wire                AWVALID_ch0;
wire [ADDR_W-1:0]   AWADDR_ch0;
wire [3:0]          AWQOS_ch0;
wire                AWREADY_ch0;

// W Channel
wire [DATA_W-1:0]     WDATA_ch0;
wire [(DATA_W/8)-1:0] WSTRB_ch0;
wire                  WVALID_ch0;
wire                  WLAST_ch0;
wire                  WREADY_ch0;

// B Channel
wire [ID_W-1:0]     BID_ch0;
wire [1:0]          BRESP_ch0;
wire                BVALID_ch0;
wire                BREADY_ch0;


// ==========================
// CH1 AXI MASTER SIGNALS
// ==========================

// AR Channel
wire [ID_W-1:0]     ARID_ch1;
wire [7:0]          ARLEN_ch1;
wire [2:0]          ARSIZE_ch1;
wire [1:0]          ARBURST_ch1;
wire                ARVALID_ch1;
wire [ADDR_W-1:0]   ARADDR_ch1;
wire [3:0]          ARQOS_ch1;
wire                ARREADY_ch1;

// R Channel
wire [ID_W-1:0]     RID_ch1;
wire [DATA_W-1:0]   RDATA_I_ch1;
wire [1:0]          RRESP_ch1;
wire                RLAST_ch1;
wire                RVALID_ch1;
wire                RREADY_ch1;

// AW Channel
wire [ID_W-1:0]     AWID_ch1;
wire [7:0]          AWLEN_ch1;
wire [2:0]          AWSIZE_ch1;
wire [1:0]          AWBURST_ch1;
wire                AWVALID_ch1;
wire [ADDR_W-1:0]   AWADDR_ch1;
wire [3:0]          AWQOS_ch1;
wire                AWREADY_ch1;

// W Channel
wire [DATA_W-1:0]     WDATA_ch1;
wire [(DATA_W/8)-1:0] WSTRB_ch1;
wire                  WVALID_ch1;
wire                  WLAST_ch1;
wire                  WREADY_ch1;

// B Channel
wire [ID_W-1:0]     BID_ch1;
wire [1:0]          BRESP_ch1;
wire                BVALID_ch1;
wire                BREADY_ch1;


// ==========================
// CH2 AXI MASTER SIGNALS
// ==========================

// AR Channel
wire [ID_W-1:0]     ARID_ch2;
wire [7:0]          ARLEN_ch2;
wire [2:0]          ARSIZE_ch2;
wire [1:0]          ARBURST_ch2;
wire                ARVALID_ch2;
wire [ADDR_W-1:0]   ARADDR_ch2;
wire [3:0]          ARQOS_ch2;
wire                ARREADY_ch2;

// R Channel
wire [ID_W-1:0]     RID_ch2;
wire [DATA_W-1:0]   RDATA_I_ch2;
wire [1:0]          RRESP_ch2;
wire                RLAST_ch2;
wire                RVALID_ch2;
wire                RREADY_ch2;

// AW Channel
wire [ID_W-1:0]     AWID_ch2;
wire [7:0]          AWLEN_ch2;
wire [2:0]          AWSIZE_ch2;
wire [1:0]          AWBURST_ch2;
wire                AWVALID_ch2;
wire [ADDR_W-1:0]   AWADDR_ch2;
wire [3:0]          AWQOS_ch2;
wire                AWREADY_ch2;

// W Channel
wire [DATA_W-1:0]     WDATA_ch2;
wire [(DATA_W/8)-1:0] WSTRB_ch2;
wire                  WVALID_ch2;
wire                  WLAST_ch2;
wire                  WREADY_ch2;

// B Channel
wire [ID_W-1:0]     BID_ch2;
wire [1:0]          BRESP_ch2;
wire                BVALID_ch2;
wire                BREADY_ch2;
    
    
//     wire [2:0]SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR;
//     wire [2:0]src_trig_req;
//    wire [5:0]  src_trig_req_type;
//    wire [2:0]des_trig_req;
//    wire [5:0]  des_trig_req_type;
//    wire [2:0]       ch_src_ack;
//    wire [5:0]  ch_src_ack_type;
//    wire [2:0]       ch_des_ack;
//    wire [1:0]  ch_des_ack_type;
//    wire [2:0]       ch_trigout_req;
//    wire [2:0]ch_trigout_ack;
    
    
    
//    // from channel to trigger matrix
//   wire [2:0]       use_src_trigin;
//   wire [5:0]  src_trigin_type;   // 2'b10 = HW
//   wire [23:0]  src_trigin_sel;  // 0 = trig0, 1 = trig1  for peripheral 1 and 2 respectively
//   wire [2:0]       use_des_trigin;
//   wire [5:0]  des_trigin_type;   // 2'b10 = HW
//   wire [23:0]  des_trigin_sel;   // 0 = trig0, 1 = trig1
//   wire [2:0]       use_trigout;
//   wire [5:0]  trigout_type;    // 2'b10 = HW
//   wire [17:0]  trigout_sel;      // 0 = trig0, 1 = trig1
//wire [(WIDTH*3)-1 : 0]  src_des_x_transfer_count_updated;
// wire stop_cmd_apb_ch0;
// wire stop_cmd_apb_ch1;
// wire stop_cmd_apb_ch2;
//    wire [95:0] read_base_addr_UPDATED;
// wire [95:0]  write_base_addr_UPDATED;
// wire [95:0]  x_transfer_count_UPDATED;  
   //channel 0
  dma_channel #(
    .WIDTH(WIDTH),
    .DATA_W(DATA_W),
    .ID_W(ID_W),
    .DEPTH(DEPTH),
    .ADDR_W(ADDR_W)
) dut_ch0 (
    // Clock and Reset
    .clk                (clk),
    .resetn             (resetn),
      .boot_addr(boot_addr),
  .boot_en(boot_en),
    // Configuration Interface
    .chn_reg_out        (chn_reg_out_ch0),
    .reg_wr_en (reg_wr_en_ch0),
    .IRQ                (IRQ_ch0),
    .ARQOS(ARQOS_ch0),
    .AWQOS(AWQOS_ch0),
    .stat_err (stat_err_ch0),
    .cfg_channel_start            (cfg_channel_start_ch0),
    .cfg_channel_status         (cfg_channel_status_ch0),
    .cfg_interrupt_enable         (cfg_interrupt_enable_ch0),
    .cfg_control_config           (cfg_control_config_ch0),
    .cfg_read_base_addr        (cfg_read_base_addr_ch0),
    .cfg_write_base_addr        (cfg_write_base_addr_ch0),
    .cfg_x_transfer_count          (cfg_x_transfer_count_ch0),
    .cfg_read_transfer_cfg    (cfg_read_transfer_cfg_ch0),
    .cfg_write_transfer_cfg    (cfg_write_transfer_cfg_ch0),
    .cfg_addr_increment_cfg       (cfg_addr_increment_cfg_ch0),
    .cfg_fill_data        (cfg_fill_data_ch0),
    .cfg_read_trigger_cfg   (cfg_read_trigger_cfg_ch0),
    .cfg_write_trigger_cfg   (cfg_write_trigger_cfg_ch0),
    .cfg_trigger_out_cfg     (cfg_trigger_out_cfg_ch0),
    .cfg_next_cmd_addr          (cfg_next_cmd_addr_ch0),
    .cfg_line_stride    (cfg_line_stride_ch0),
    .cfg_y_transfer_count          (cfg_y_transfer_count_ch0),
    .cfg_auto_restart_config        (cfg_auto_restart_config_ch0),
    .cfg_read_template_data       (cfg_read_template_data_ch0),
    .cfg_write_template_data       (cfg_write_template_data_ch0),
    .cfg_template_config       (cfg_template_config_ch0),
    .chn_autocfg_wr_en_o   (chn_autocfg_wr_en_o_ch0),
    .chn_srctmplt_wr_en_o  (chn_srctmplt_wr_en_o_ch0),
    .chn_destmplt_wr_en_o  (chn_destmplt_wr_en_o_ch0),
    .chn_tmpltcfg_wr_en_o  (chn_tmpltcfg_wr_en_o_ch0),
    .chn_cmd_wr_en_o       (chn_cmd_wr_en_o_ch0),
    .chn_stat_wr_en_o      (chn_stat_wr_en_o_ch0),
    .chn_intren_wr_en_o    (chn_intren_wr_en_o_ch0),
    .chn_ctrl_wr_en_o      (chn_ctrl_wr_en_o_ch0),
    .chn_read_base_addr_wr_en_o   (chn_read_base_addr_wr_en_o_ch0),
    .chn_write_base_addr_wr_en_o   (chn_write_base_addr_wr_en_o_ch0),
    .chn_x_transfer_count_wr_en_o     (chn_x_transfer_count_wr_en_o_ch0),
    .chn_srctrans_wr_en_o  (chn_srctrans_wr_en_o_ch0),
    .chn_destrans_wr_en_o  (chn_destrans_wr_en_o_ch0),
    .chn_xaddrinc_wr_en_o  (chn_xaddrinc_wr_en_o_ch0),
    .chn_fillval_wr_en_o   (chn_fillval_wr_en_o_ch0),
    .chn_srctrigin_wr_en_o (chn_srctrigin_wr_en_o_ch0),
    .chn_destrigin_wr_en_o (chn_destrigin_wr_en_o_ch0),
    .chn_trigout_wr_en_o   (chn_trigout_wr_en_o_ch0),
        .chn_work_reg_pointer_wr_en_o(chn_work_reg_pointer_wr_en_o_ch0),
    .chn_next_cmd_addr_wr_en_o  (chn_next_cmd_addr_wr_en_o_ch0),
    .chn_y_transfer_count_wr_en_o(chn_y_transfer_count_wr_en_o_ch0),
    .chn_yaddrestride_wr_en_o(chn_yaddrestride_wr_en_o_ch0),
    .y_transfer_count_UPDATED(y_transfer_count_UPDATED_ch0),
    .enable_cmd_to_apb(enable_cmd_to_apb_ch0),
    // AXI Read Address/Data (General/Descriptor)
    .ARID               (ARID_ch0),
    .ARADDR             (ARADDR_ch0),
    .ARLEN              (ARLEN_ch0),
    .ARSIZE             (ARSIZE_ch0),
    .ARBURST            (ARBURST_ch0),
    .ARVALID            (ARVALID_ch0),
    .ARREADY            (ARREADY_ch0),
    
    .RID                (RID_ch0),
    .RDATA_I            (RDATA_I_ch0),
    .RRESP              (RRESP_ch0),
    .RLAST              (RLAST_ch0),
    .RVALID             (RVALID_ch0),
    .RREADY             (RREADY_ch0),

    .AWID_D             (AWID_ch0),
    .AWADDR_D           (AWADDR_ch0),
    .AWLEN_D            (AWLEN_ch0),
    .AWSIZE_D           (AWSIZE_ch0),
    .AWBURST_D          (AWBURST_ch0),
    .AWVALID_D          (AWVALID_ch0),
    .AWREADY            (AWREADY_ch0),
    
    .WDATA_D            (WDATA_ch0),
    .WVALID_D           (WVALID_ch0),
    .WLAST_D            (WLAST_ch0),
    .WREADY             (WREADY_ch0),
    .WSTRB(WSTRB_ch0),
    
    .BID                (BID_ch0),
    .BVALID             (BVALID_ch0),
    .BRESP              (BRESP_ch0),
    .BREADY_D           (BREADY_ch0),

    // Trigger and Control Signals

    .SRCTRIGINSELERR    (SRCTRIGINSELERR[0]),
    .DESTRIGINSELERR    (DESTRIGINSELERR[0]),
    .TRIGOUTSELERR      (TRIGOUTSELERR[0]),

    // Source Trigger Interface
    .src_trig_req       (src_trig_req[0]),
    .src_trig_req_type  (src_trig_req_type[1:0]),
    .ch_src_ack         (ch_src_ack[0]),
    .ch_src_ack_type    (ch_src_ack_type[1:0]),
   .use_src_trigin     (use_src_trigin[0]),
   .src_trigin_type    (src_trigin_type[1:0]),
   .src_trigin_sel     (src_trigin_sel[7:0]),

    // Destination Trigger Interface
    .des_trig_req       (des_trig_req[0]),
    .des_trig_req_type  (des_trig_req_type[1:0]),
    .ch_des_ack         (ch_des_ack[0]),
   .ch_des_ack_type    (ch_des_ack_type[1:0]),
    .use_des_trigin     (use_des_trigin[0]),
    .des_trigin_type    (des_trigin_type[1:0]),
    .des_trigin_sel     (des_trigin_sel[7:0]),

    // Trigger Out Interface
    .ch_trigout_req     (ch_trigout_req[0]),
    .ch_trigout_ack     (ch_trigout_ack[0]),
    .use_trigout        (use_trigout[0]),
    .trigout_type       (trigout_type[1:0]),
    .trigout_sel        (trigout_sel[5:0]),
    .src_des_x_transfer_count_updated(src_des_x_transfer_count_updated_ch0),
    .wrkregval_rd(wrkregval_rd_ch0),
    .cfg_work_reg_pointer(cfg_work_reg_pointer_ch0),
    .stop_cmd_apb(stop_cmd_apb_ch0),
 .read_base_addr_UPDATED(read_base_addr_UPDATED_ch0),
 .write_base_addr_UPDATED(write_base_addr_UPDATED_ch0),
 .x_transfer_count_UPDATED(x_transfer_count_UPDATED_ch0) );
   
   
   //channel 1
   
  dma_channel #(
    .WIDTH(WIDTH),
    .DATA_W(DATA_W),
    .ID_W(ID_W),
    .DEPTH(DEPTH),
    .ADDR_W(ADDR_W)
) dut_ch1 (
    // Clock and Reset
    .clk                (clk),
    .resetn             (resetn),
      .boot_addr(boot_addr),
  .boot_en(boot_en),
    // Configuration Interface
    .chn_reg_out        (chn_reg_out_ch1),
    .reg_wr_en (reg_wr_en_ch1),
    .IRQ                (IRQ_ch1),
    .ARQOS(ARQOS_ch1),
    .AWQOS(AWQOS_ch1),
    .stat_err (stat_err_ch1),
    .cfg_channel_start            (cfg_channel_start_ch1),
    .cfg_channel_status         (cfg_channel_status_ch1),
    .cfg_interrupt_enable         (cfg_interrupt_enable_ch1),
    .cfg_control_config           (cfg_control_config_ch1),
    .cfg_read_base_addr        (cfg_read_base_addr_ch1),
    .cfg_write_base_addr        (cfg_write_base_addr_ch1),
    .cfg_x_transfer_count          (cfg_x_transfer_count_ch1),
    .cfg_read_transfer_cfg    (cfg_read_transfer_cfg_ch1),
    .cfg_write_transfer_cfg    (cfg_write_transfer_cfg_ch1),
    .cfg_addr_increment_cfg       (cfg_addr_increment_cfg_ch1),
    .cfg_fill_data        (cfg_fill_data_ch1),
    .cfg_read_trigger_cfg   (cfg_read_trigger_cfg_ch1),
    .cfg_write_trigger_cfg   (cfg_write_trigger_cfg_ch1),
    .cfg_trigger_out_cfg     (cfg_trigger_out_cfg_ch1),
    .cfg_next_cmd_addr          (cfg_next_cmd_addr_ch1),
    .cfg_line_stride    (cfg_line_stride_ch1),
    .cfg_y_transfer_count          (cfg_y_transfer_count_ch1),
    .cfg_auto_restart_config        (cfg_auto_restart_config_ch1),
    .cfg_read_template_data       (cfg_read_template_data_ch1),
    .cfg_write_template_data       (cfg_write_template_data_ch1),
    .cfg_template_config       (cfg_template_config_ch1),
    .chn_autocfg_wr_en_o   (chn_autocfg_wr_en_o_ch1),
    .chn_srctmplt_wr_en_o  (chn_srctmplt_wr_en_o_ch1),
    .chn_destmplt_wr_en_o  (chn_destmplt_wr_en_o_ch1),
    .chn_tmpltcfg_wr_en_o  (chn_tmpltcfg_wr_en_o_ch1),
    .chn_cmd_wr_en_o     (chn_cmd_wr_en_o_ch1),
    .chn_stat_wr_en_o   (chn_stat_wr_en_o_ch1),
    .chn_intren_wr_en_o (chn_intren_wr_en_o_ch1),
    .chn_ctrl_wr_en_o      (chn_ctrl_wr_en_o_ch1),
    .chn_read_base_addr_wr_en_o   (chn_read_base_addr_wr_en_o_ch1),
    .chn_write_base_addr_wr_en_o   (chn_write_base_addr_wr_en_o_ch1),
    .chn_x_transfer_count_wr_en_o    (chn_x_transfer_count_wr_en_o_ch1),
    .chn_srctrans_wr_en_o  (chn_srctrans_wr_en_o_ch1),
    .chn_destrans_wr_en_o  (chn_destrans_wr_en_o_ch1),
    .chn_xaddrinc_wr_en_o  (chn_xaddrinc_wr_en_o_ch1),
    .chn_fillval_wr_en_o   (chn_fillval_wr_en_o_ch1),
    .chn_srctrigin_wr_en_o (chn_srctrigin_wr_en_o_ch1),
    .chn_destrigin_wr_en_o (chn_destrigin_wr_en_o_ch1),
    .chn_trigout_wr_en_o   (chn_trigout_wr_en_o_ch1),
        .chn_work_reg_pointer_wr_en_o(chn_work_reg_pointer_wr_en_o_ch1),
    .chn_next_cmd_addr_wr_en_o  (chn_next_cmd_addr_wr_en_o_ch1),
    .chn_y_transfer_count_wr_en_o(chn_y_transfer_count_wr_en_o_ch1),
    .chn_yaddrestride_wr_en_o(chn_yaddrestride_wr_en_o_ch1),
    .y_transfer_count_UPDATED(y_transfer_count_UPDATED_ch1),
    .enable_cmd_to_apb(_ch1enable_cmd_to_apb_ch1),
    // AXI Read Address/Data (General/Desc_ch1riptor)
    .ARID               (ARID_ch1_ch1),
    .ARADDR             (ARADDR_ch1),
    .ARLEN              (ARLEN_ch1),
    .ARSIZE             (ARSIZE_ch1),
    .ARBURST            (ARBURST_ch1),
    .ARVALID            (ARVALID_ch1),
    .ARREADY            (ARREADY_ch1),
    
    .RID                (RID_ch1),
    .RDATA_I            (RDATA_I_ch1),
    .RRESP              (RRESP_ch1),
    .RLAST              (RLAST_ch1),
    .RVALID             (RVALID_ch1),
    .RREADY             (RREADY_ch1),

    .AWID_D             (AWID_ch1),
    .AWADDR_D           (AWADDR_ch1),
    .AWLEN_D            (AWLEN_ch1),
    .AWSIZE_D           (AWSIZE_ch1),
    .AWBURST_D          (AWBURST_ch1),
    .AWVALID_D          (AWVALID_ch1),
    .AWREADY            (AWREADY_ch1),
    
    .WDATA_D            (WDATA_ch1),
    .WVALID_D           (WVALID_ch1),
    .WLAST_D            (WLAST_ch1),
    .WREADY             (WREADY_ch1),
    .WSTRB(WSTRB_ch1),
    
    .BID                (BID_ch1),
    .BVALID             (BVALID_ch1),
    .BRESP              (BRESP_ch1),
    .BREADY_D           (BREADY_ch1),

    // Trigger and Control Signals

    .SRCTRIGINSELERR    (SRCTRIGINSELERR[1]),
    .DESTRIGINSELERR    (DESTRIGINSELERR[1]),
    .TRIGOUTSELERR      (TRIGOUTSELERR[1]),

    // Source Trigger Interface
    .src_trig_req       (src_trig_req[1]),
    .src_trig_req_type  (src_trig_req_type[3:2]),
    .ch_src_ack         (ch_src_ack[1]),
    .ch_src_ack_type    (ch_src_ack_type[3:2]),
   .use_src_trigin     (use_src_trigin[1]),
   .src_trigin_type    (src_trigin_type[3:2]),
   .src_trigin_sel     (src_trigin_sel[15:8]),

    // Destination Trigger Interface
    .des_trig_req       (des_trig_req[1]),
    .des_trig_req_type  (des_trig_req_type[3:2]),
    .ch_des_ack         (ch_des_ack[1]),
   .ch_des_ack_type    (ch_des_ack_type[3:2]),
    .use_des_trigin     (use_des_trigin[1]),
    .des_trigin_type    (des_trigin_type[3:2]),
    .des_trigin_sel     (des_trigin_sel[15:8]),

    // Trigger Out Interface
    .ch_trigout_req     (ch_trigout_req[1]),
    .ch_trigout_ack     (ch_trigout_ack[1]),
    .use_trigout        (use_trigout[1]),
    .trigout_type       (trigout_type[3:2]),
    .trigout_sel        (trigout_sel[11:6]),
    .src_des_x_transfer_count_updated(src_des_x_transfer_count_updated_ch1),
    .wrkregval_rd(wrkregval_rd_ch1),
    .cfg_work_reg_pointer(cfg_work_reg_pointer_ch1),
    .stop_cmd_apb(stop_cmd_apb_ch1),
 .read_base_addr_UPDATED(read_base_addr_UPDATED_ch1),
 .write_base_addr_UPDATED(write_base_addr_UPDATED_ch1),
 .x_transfer_count_UPDATED(x_transfer_count_UPDATED_ch1) );  
   
   
   //channel 2
   
    dma_channel #(
    .WIDTH(WIDTH),
    .DATA_W(DATA_W),
    .ID_W(ID_W),
    .DEPTH(DEPTH),
    .ADDR_W(ADDR_W)
) dut_ch2 (
    // Clock and Reset
    .clk                (clk),
    .resetn             (resetn),
      .boot_addr(boot_addr),
  .boot_en(boot_en),
    // Configuration Interface
    .chn_reg_out        (chn_reg_out_ch2),
    .reg_wr_en (reg_wr_en_ch2),
    .IRQ                (IRQ_ch2),
    .ARQOS(ARQOS_ch2),
    .AWQOS(AWQOS_ch2),
    .stat_err (stat_err_ch2),
    .cfg_channel_start            (cfg_channel_start_ch2),
    .cfg_channel_status         (cfg_channel_status_ch2),
    .cfg_interrupt_enable         (cfg_interrupt_enable_ch2),
    .cfg_control_config           (cfg_control_config_ch2),
    .cfg_read_base_addr        (cfg_read_base_addr_ch2),
    .cfg_write_base_addr        (cfg_write_base_addr_ch2),
    .cfg_x_transfer_count          (cfg_x_transfer_count_ch2),
    .cfg_read_transfer_cfg    (cfg_read_transfer_cfg_ch2),
    .cfg_write_transfer_cfg    (cfg_write_transfer_cfg_ch2),
    .cfg_addr_increment_cfg       (cfg_addr_increment_cfg_ch2),
    .cfg_fill_data        (cfg_fill_data_ch2),
    .cfg_read_trigger_cfg   (cfg_read_trigger_cfg_ch2),
    .cfg_write_trigger_cfg   (cfg_write_trigger_cfg_ch2),
    .cfg_trigger_out_cfg     (cfg_trigger_out_cfg_ch2),
    .cfg_next_cmd_addr          (cfg_next_cmd_addr_ch2),
    .cfg_line_stride    (cfg_line_stride_ch2),
    .cfg_y_transfer_count          (cfg_y_transfer_count_ch2),
    .cfg_auto_restart_config        (cfg_auto_restart_config_ch2),
    .cfg_read_template_data       (cfg_read_template_data_ch2),
    .cfg_write_template_data       (cfg_write_template_data_ch2),
    .cfg_template_config       (cfg_template_config_ch2),
    .chn_autocfg_wr_en_o   (chn_autocfg_wr_en_o_ch2),
    .chn_srctmplt_wr_en_o  (chn_srctmplt_wr_en_o_ch2),
    .chn_destmplt_wr_en_o  (chn_destmplt_wr_en_o_ch2),
    .chn_tmpltcfg_wr_en_o  (chn_tmpltcfg_wr_en_o_ch2),
    .chn_cmd_wr_en_o       (chn_cmd_wr_en_o_ch2),
    .chn_stat_wr_en_o      (chn_stat_wr_en_o_ch2),
    .chn_intren_wr_en_o    (chn_intren_wr_en_o_ch2),
    .chn_ctrl_wr_en_o      (chn_ctrl_wr_en_o_ch2),
    .chn_read_base_addr_wr_en_o   (chn_read_base_addr_wr_en_o_ch2),
    .chn_write_base_addr_wr_en_o   (chn_write_base_addr_wr_en_o_ch2),
    .chn_x_transfer_count_wr_en_o     (chn_x_transfer_count_wr_en_o_ch2),
    .chn_srctrans_wr_en_o  (chn_srctrans_wr_en_o_ch2),
    .chn_destrans_wr_en_o  (chn_destrans_wr_en_o_ch2),
    .chn_xaddrinc_wr_en_o  (chn_xaddrinc_wr_en_o_ch2),
    .chn_fillval_wr_en_o   (chn_fillval_wr_en_o_ch2),
    .chn_srctrigin_wr_en_o (chn_srctrigin_wr_en_o_ch2),
    .chn_destrigin_wr_en_o (chn_destrigin_wr_en_o_ch2),
    .chn_trigout_wr_en_o   (chn_trigout_wr_en_o_ch2),
        .chn_work_reg_pointer_wr_en_o(chn_work_reg_pointer_wr_en_o_ch2),
    .chn_next_cmd_addr_wr_en_o  (chn_next_cmd_addr_wr_en_o_ch2),
    .chn_y_transfer_count_wr_en_o(chn_y_transfer_count_wr_en_o_ch2),
    .chn_yaddrestride_wr_en_o(chn_yaddrestride_wr_en_o_ch2),
    .y_transfer_count_UPDATED(y_transfer_count_UPDATED_ch2),
    .enable_cmd_to_apb(enable_cmd_to_apb_ch2),
    // AXI Read Address/Data (General/Descriptor)
    .ARID               (ARID_ch2),
    .ARADDR             (ARADDR_ch2),
    .ARLEN              (ARLEN_ch2),
    .ARSIZE             (ARSIZE_ch2),
    .ARBURST            (ARBURST_ch2),
    .ARVALID            (ARVALID_ch2),
    .ARREADY            (ARREADY_ch2),
    
    .RID                (RID_ch2),
    .RDATA_I            (RDATA_I_ch2),
    .RRESP              (RRESP_ch2),
    .RLAST              (RLAST_ch2),
    .RVALID             (RVALID_ch2),
    .RREADY             (RREADY_ch2),

    .AWID_D             (AWID_ch2),
    .AWADDR_D           (AWADDR_ch2),
    .AWLEN_D            (AWLEN_ch2),
    .AWSIZE_D           (AWSIZE_ch2),
    .AWBURST_D          (AWBURST_ch2),
    .AWVALID_D          (AWVALID_ch2),
    .AWREADY            (AWREADY_ch2),
    
    .WDATA_D            (WDATA_ch2),
    .WVALID_D           (WVALID_ch2),
    .WLAST_D            (WLAST_ch2),
    .WREADY             (WREADY_ch2),
    .WSTRB(WSTRB_ch2),
    
    .BID                (BID_ch2),
    .BVALID             (BVALID_ch2),
    .BRESP              (BRESP_ch2),
    .BREADY_D           (BREADY_ch2),

    // Trigger and Control Signals

    .SRCTRIGINSELERR    (SRCTRIGINSELERR[2]),
    .DESTRIGINSELERR    (DESTRIGINSELERR[2]),
    .TRIGOUTSELERR      (TRIGOUTSELERR[2]),

    // Source Trigger Interface
    .src_trig_req       (src_trig_req[2]),
    .src_trig_req_type  (src_trig_req_type[5:4]),
    .ch_src_ack         (ch_src_ack[2]),
    .ch_src_ack_type    (ch_src_ack_type[5:4]),
   .use_src_trigin     (use_src_trigin[2]),
   .src_trigin_type    (src_trigin_type[5:4]),
   .src_trigin_sel     (src_trigin_sel[23:16]),

    // Destination Trigger Interface
    .des_trig_req       (des_trig_req[2]),
    .des_trig_req_type  (des_trig_req_type[5:4]),
    .ch_des_ack         (ch_des_ack[2]),
   .ch_des_ack_type    (ch_des_ack_type[5:4]),
    .use_des_trigin     (use_des_trigin[2]),
    .des_trigin_type    (des_trigin_type[5:4]),
    .des_trigin_sel     (des_trigin_sel[23:16]),

    // Trigger Out Interface
    .ch_trigout_req     (ch_trigout_req[2]),
    .ch_trigout_ack     (ch_trigout_ack[2]),
    .use_trigout        (use_trigout[2]),
    .trigout_type       (trigout_type[5:4]),
    .trigout_sel        (trigout_sel[17:12]),
    .src_des_x_transfer_count_updated(src_des_x_transfer_count_updated_ch2),
    .wrkregval_rd(wrkregval_rd_ch2),
    .cfg_work_reg_pointer(cfg_work_reg_pointer_ch2),
    .stop_cmd_apb(stop_cmd_apb_ch2),
 .read_base_addr_UPDATED(read_base_addr_UPDATED_ch2),
 .write_base_addr_UPDATED(write_base_addr_UPDATED_ch2),
 .x_transfer_count_UPDATED(x_transfer_count_UPDATED_ch2) );
   
 
biu dut (
    .clk(clk),
    .rst_n(rst_n),
//AR PH
    .ARVALID(ARVALID),
    .ARADDR(ARADDR),
    .ARLEN(ARLEN),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),
    .ARREADY(ARREADY),
    .ARID(ARID),
    .ARQOS(ARQOS),
    //R PH
    .RID(RID),
    .RVALID(RVALID),
    .RDATA(RDATA),
    .RLAST(RLAST),
    .RREADY(RREADY),
    // AW PH
    .AWREADY(AWREADY),
    .AWVALID (AWVALID),
    .AWADDR  (AWADDR),
    .AWLEN   (AWLEN),
    .AWSIZE  (AWSIZE),
    .AWBURST (AWBURST),
    .AWID    (AWID),
    .AWQOS   (AWQOS),
//W PH
    .WREADY(WREADY),
    .WVALID (WVALID),
    .WDATA  (WDATA),
    .WLAST  (WLAST),
    .WSTRB  (WSTRB),
//B PH
    .BID    (BID),
    .BREADY (BREADY),
    .BVALID(BVALID),


    .rd_grant(rd_grant),
    .wr_grant(wr_grant),
//AR
    .ch0_ARVALID(ARVALID_ch0),
    .ch1_ARVALID(ARVALID_ch1),
    .ch2_ARVALID(ARVALID_ch2),

    .ch0_ARADDR(ARADDR_ch0),
    .ch1_ARADDR(ARADDR_ch1),
    .ch2_ARADDR(ARADDR_ch2),
    
    .ch0_ARLEN(ARLEN_ch0),
    .ch1_ARLEN(ARLEN_ch1),
    .ch2_ARLEN(ARLEN_ch2),
    
    .ch0_ARSIZE(ARSIZE_ch0),
    .ch1_ARSIZE(ARSIZE_ch1),
    .ch2_ARSIZE(ARSIZE_ch2),
    
    .ch0_ARBURST(ARBURST_ch0),
    .ch1_ARBURST(ARBURST_ch1),
    .ch2_ARBURST(ARBURST_ch2),
        
    .ch0_ARQOS(ARQOS_ch0),
    .ch1_ARQOS(ARQOS_ch1),
    .ch2_ARQOS(ARQOS_ch2),
    
    .ch0_ARREADY(ARREADY_ch0),
    .ch1_ARREADY(ARREADY_ch1),
    .ch2_ARREADY(ARREADY_ch2),
//R
    .ch0_RVALID(RVALID_ch0),
    .ch1_RVALID(RVALID_ch1),
    .ch2_RVALID(RVALID_ch2),
    
    .ch0_RDATA(RDATA_ch0),
    .ch1_RDATA(RDATA_ch1),
    .ch2_RDATA(RDATA_ch2),
    
    .ch0_RREADY(RREADY_ch0),
    .ch1_RREADY(RREADY_ch1),
    .ch2_RREADY(RREADY_ch2),
//AW
    .ch0_AWVALID(AWVALID_ch0),
    .ch1_AWVALID(AWVALID_ch1),
    .ch2_AWVALID(AWVALID_ch2),

    .ch0_AWADDR(AWADDR_ch0),
    .ch1_AWADDR(AWADDR_ch1),
    .ch2_AWADDR(AWADDR_ch2),

    .ch0_AWLEN(AWLEN_ch0),
    .ch1_AWLEN(AWLEN_ch1),
    .ch2_AWLEN(AWLEN_ch2),
    
    .ch0_AWSIZE(AWSIZE_ch0),
    .ch1_AWSIZE(AWSIZE_ch1),
    .ch2_AWSIZE(AWSIZE_ch2),
    
    .ch0_AWBURST(AWBURST_ch0),
    .ch1_AWBURST(AWBURST_ch1),
    .ch2_AWBURST(AWBURST_ch2),
    
    .ch0_AWQOS(AWQOS_ch0),
    .ch1_AWQOS(AWQOS_ch1),
    .ch2_AWQOS(AWQOS_ch2),
    
    .ch0_AWREADY(AWREADY_ch0),
    .ch1_AWREADY(AWREADY_ch1),
    .ch2_AWREADY(AWREADY_ch2),
//W
    .ch0_WVALID(WVALID_ch0),
    .ch1_WVALID(WVALID_ch1),
    .ch2_WVALID(WVALID_ch2),
    
    .ch0_WDATA(WDATA_ch0),
    .ch1_WDATA(WDATA_ch1),
    .ch2_WDATA(WDATA_ch2),
    
    .ch0_WLAST(WLAST_ch0),
    .ch1_WLAST(WLAST_ch1),
    .ch2_WLAST(WLAST_ch2),
    
    .ch0_WSTRB(WSTRB_ch0),
    .ch1_WSTRB(WSTRB_ch1),
    .ch2_WSTRB(WSTRB_ch2),
    
    .ch0_WREADY(WREADY_ch0),
    .ch1_WREADY(WREADY_ch1),
    .ch2_WREADY(WREADY_ch2),
//B
    .ch0_BREADY(BREADY_ch0),
    .ch1_BREADY(BREADY_ch1),
    .ch2_BREADY(BREADY_ch2),
    
    .ch0_BVALID(BVALID_ch0),
    .ch1_BVALID(BVALID_ch1),
    .ch2_BVALID(BVALID_ch2),
    
    .stop_cmd({stop_cmd_apb_ch2,stop_cmd_apb_ch1,stop_cmd_apb_ch0})
); 
   
   
   
endmodule

module top_mod_multi#(
parameter WIDTH = 32,
    parameter DATA_W = 128,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH =  DATA_WIDTH/8,
    parameter ID_W       =4,
    parameter DEPTH =145,
    parameter ADDR_W =32,
    parameter NUM_CH = 3  
)
    (// apb_reg interface
      input wire clk,
      input wire resetn,
      // boot interface
      input wire boot_en,
      input wire [29:0] boot_addr,
      //apb interface signals
      input wire [ ADDR_WIDTH-1 : 0 ] PADDR,
      input wire PWRITE,
      input wire PENABLE,
      input wire PSEL,
      input wire [DATA_WIDTH-1 : 0] PWDATA,
      input wire [STRB_WIDTH-1 : 0] PSTRB,
      //  back to cpu
      output wire [DATA_WIDTH-1 : 0] PRDATA,
      output wire PREADY,
      output wire PSLVERR,
      
   input  wire [5:0]      trig_req,
    input  wire [11:0]  trig_req_type,
    output wire  [5:0]   trig_ack,
    output wire  [11:0]  trig_ack_type,
    // External Trigger OUTPUTS (to peripherals)
    output wire   [5:0]  trig_out_req,
    input  wire  [5:0]  trig_out_ack,
    
      //AXI SIGNALS TO BIU
      input wire ARREADY,
      input wire [ID_W -1 : 0]RID,
      input wire [DATA_W-1 : 0]RDATA_I,
      input wire [1:0]RRESP,
      input wire RLAST,
      input wire RVALID,
      
      input wire WREADY,
      input wire AWREADY,
      input wire [ID_W-1 : 0] BID,
      input wire BVALID,
      input wire [1:0] BRESP,
      
      output wire [3:0] ARQOS,
      output wire [3:0] AWQOS,
      output wire [ID_W -1 : 0] ARID,
      output wire [7:0] ARLEN,
      output wire[2:0] ARSIZE,
      output wire [1:0] ARBURST,
      output wire ARVALID,
      output wire [ADDR_W-1:0]ARADDR,
      output wire RREADY, 
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
    
    // wires for connecting configutations from apb reg to global channel
    
    // ==========================
// CH0 APB REG SIGNALS
// ==========================
wire [31:0] cfg_work_reg_pointer_ch0;
wire [WIDTH-1 : 0] cfg_channel_start_ch0;
wire [WIDTH-1 : 0] cfg_channel_status_ch0;
wire [WIDTH-1 : 0] cfg_interrupt_enable_ch0;
wire [WIDTH-1 : 0] cfg_control_config_ch0;
wire [WIDTH-1 : 0] cfg_read_base_addr_ch0;
wire [WIDTH-1 : 0] cfg_write_base_addr_ch0;
wire [WIDTH-1 : 0] cfg_x_transfer_count_ch0;
wire [WIDTH-1 : 0] cfg_read_transfer_cfg_ch0;
wire [WIDTH-1 : 0] cfg_write_transfer_cfg_ch0;
wire [WIDTH-1 : 0] cfg_addr_increment_cfg_ch0;
wire [WIDTH-1 : 0] cfg_fill_data_ch0;
wire [WIDTH-1 : 0] cfg_read_trigger_cfg_ch0;
wire [WIDTH-1 : 0] cfg_write_trigger_cfg_ch0;
wire [WIDTH-1 : 0] cfg_trigger_out_cfg_ch0;
wire [WIDTH-1 : 0] cfg_auto_restart_config_ch0;
wire [WIDTH-1 : 0] cfg_next_cmd_addr_ch0;
wire [31:0] cfg_line_stride_ch0;
wire [31:0] cfg_y_transfer_count_ch0;
wire [31:0] cfg_read_template_data_ch0;
wire [31:0] cfg_write_template_data_ch0;
wire [31:0] cfg_template_config_ch0;
wire [WIDTH-1:0] wrkregval_rd_ch0;

wire chn_autocfg_wr_en_o_ch0;
wire chn_yaddrestride_wr_en_o_ch0;
wire chn_y_transfer_count_wr_en_o_ch0;
wire chn_srctmplt_wr_en_o_ch0;
wire chn_destmplt_wr_en_o_ch0;
wire chn_tmpltcfg_wr_en_o_ch0;
wire chn_work_reg_pointer_wr_en_o_ch0;
wire chn_cmd_wr_en_o_ch0;
wire chn_stat_wr_en_o_ch0;
wire chn_intren_wr_en_o_ch0;
wire chn_ctrl_wr_en_o_ch0;
wire chn_read_base_addr_wr_en_o_ch0;
wire chn_write_base_addr_wr_en_o_ch0;
wire chn_x_transfer_count_wr_en_o_ch0;
wire chn_srctrans_wr_en_o_ch0;
wire chn_destrans_wr_en_o_ch0;
wire chn_xaddrinc_wr_en_o_ch0;
wire chn_fillval_wr_en_o_ch0;
wire chn_srctrigin_wr_en_o_ch0;
wire chn_destrigin_wr_en_o_ch0;
wire chn_trigout_wr_en_o_ch0;
wire chn_next_cmd_addr_wr_en_o_ch0;

wire enable_cmd_to_apb_ch0;
wire [(WIDTH*18)-1 : 0] chn_reg_out_ch0;
wire reg_wr_en_ch0;
wire stat_err_ch0;
wire [31:0] y_transfer_count_UPDATED_ch0;
wire [(WIDTH*3)-1 : 0] src_des_x_transfer_count_updated_ch0;
wire stop_cmd_apb_ch0;
wire [31:0] read_base_addr_UPDATED_ch0;
wire [31:0] write_base_addr_UPDATED_ch0;
wire [31:0] x_transfer_count_UPDATED_ch0;


// ==========================
// CH1 APB REG SIGNALS
// ==========================
wire [31:0] cfg_work_reg_pointer_ch1;
wire [WIDTH-1 : 0] cfg_channel_start_ch1;
wire [WIDTH-1 : 0] cfg_channel_status_ch1;
wire [WIDTH-1 : 0] cfg_interrupt_enable_ch1;
wire [WIDTH-1 : 0] cfg_control_config_ch1;
wire [WIDTH-1 : 0] cfg_read_base_addr_ch1;
wire [WIDTH-1 : 0] cfg_write_base_addr_ch1;
wire [WIDTH-1 : 0] cfg_x_transfer_count_ch1;
wire [WIDTH-1 : 0] cfg_read_transfer_cfg_ch1;
wire [WIDTH-1 : 0] cfg_write_transfer_cfg_ch1;
wire [WIDTH-1 : 0] cfg_addr_increment_cfg_ch1;
wire [WIDTH-1 : 0] cfg_fill_data_ch1;
wire [WIDTH-1 : 0] cfg_read_trigger_cfg_ch1;
wire [WIDTH-1 : 0] cfg_write_trigger_cfg_ch1;
wire [WIDTH-1 : 0] cfg_trigger_out_cfg_ch1;
wire [WIDTH-1 : 0] cfg_auto_restart_config_ch1;
wire [WIDTH-1 : 0] cfg_next_cmd_addr_ch1;
wire [31:0] cfg_line_stride_ch1;
wire [31:0] cfg_y_transfer_count_ch1;
wire [31:0] cfg_read_template_data_ch1;
wire [31:0] cfg_write_template_data_ch1;
wire [31:0] cfg_template_config_ch1;
wire [WIDTH-1:0] wrkregval_rd_ch1;

wire chn_autocfg_wr_en_o_ch1;
wire chn_yaddrestride_wr_en_o_ch1;
wire chn_y_transfer_count_wr_en_o_ch1;
wire chn_srctmplt_wr_en_o_ch1;
wire chn_destmplt_wr_en_o_ch1;
wire chn_tmpltcfg_wr_en_o_ch1;
wire chn_work_reg_pointer_wr_en_o_ch1;
wire chn_cmd_wr_en_o_ch1;
wire chn_stat_wr_en_o_ch1;
wire chn_intren_wr_en_o_ch1;
wire chn_ctrl_wr_en_o_ch1;
wire chn_read_base_addr_wr_en_o_ch1;
wire chn_write_base_addr_wr_en_o_ch1;
wire chn_x_transfer_count_wr_en_o_ch1;
wire chn_srctrans_wr_en_o_ch1;
wire chn_destrans_wr_en_o_ch1;
wire chn_xaddrinc_wr_en_o_ch1;
wire chn_fillval_wr_en_o_ch1;
wire chn_srctrigin_wr_en_o_ch1;
wire chn_destrigin_wr_en_o_ch1;
wire chn_trigout_wr_en_o_ch1;
wire chn_next_cmd_addr_wr_en_o_ch1;

wire enable_cmd_to_apb_ch1;
wire [(WIDTH*18)-1 : 0] chn_reg_out_ch1;
wire reg_wr_en_ch1;
wire stat_err_ch1;
wire [31:0] y_transfer_count_UPDATED_ch1;
wire [(WIDTH*3)-1 : 0] src_des_x_transfer_count_updated_ch1;
wire stop_cmd_apb_ch1;
wire [31:0] read_base_addr_UPDATED_ch1;
wire [31:0] write_base_addr_UPDATED_ch1;
wire [31:0] x_transfer_count_UPDATED_ch1;


// ==========================
// CH2 APB REG SIGNALS
// ==========================
wire [31:0] cfg_work_reg_pointer_ch2;
wire [WIDTH-1 : 0] cfg_channel_start_ch2;
wire [WIDTH-1 : 0] cfg_channel_status_ch2;
wire [WIDTH-1 : 0] cfg_interrupt_enable_ch2;
wire [WIDTH-1 : 0] cfg_control_config_ch2;
wire [WIDTH-1 : 0] cfg_read_base_addr_ch2;
wire [WIDTH-1 : 0] cfg_write_base_addr_ch2;
wire [WIDTH-1 : 0] cfg_x_transfer_count_ch2;
wire [WIDTH-1 : 0] cfg_read_transfer_cfg_ch2;
wire [WIDTH-1 : 0] cfg_write_transfer_cfg_ch2;
wire [WIDTH-1 : 0] cfg_addr_increment_cfg_ch2;
wire [WIDTH-1 : 0] cfg_fill_data_ch2;
wire [WIDTH-1 : 0] cfg_read_trigger_cfg_ch2;
wire [WIDTH-1 : 0] cfg_write_trigger_cfg_ch2;
wire [WIDTH-1 : 0] cfg_trigger_out_cfg_ch2;
wire [WIDTH-1 : 0] cfg_auto_restart_config_ch2;
wire [WIDTH-1 : 0] cfg_next_cmd_addr_ch2;
wire [31:0] cfg_line_stride_ch2;
wire [31:0] cfg_y_transfer_count_ch2;
wire [31:0] cfg_read_template_data_ch2;
wire [31:0] cfg_write_template_data_ch2;
wire [31:0] cfg_template_config_ch2;
wire [WIDTH-1:0] wrkregval_rd_ch2;

wire chn_autocfg_wr_en_o_ch2;
wire chn_yaddrestride_wr_en_o_ch2;
wire chn_y_transfer_count_wr_en_o_ch2;
wire chn_srctmplt_wr_en_o_ch2;
wire chn_destmplt_wr_en_o_ch2;
wire chn_tmpltcfg_wr_en_o_ch2;
wire chn_work_reg_pointer_wr_en_o_ch2;
wire chn_cmd_wr_en_o_ch2;
wire chn_stat_wr_en_o_ch2;
wire chn_intren_wr_en_o_ch2;
wire chn_ctrl_wr_en_o_ch2;
wire chn_read_base_addr_wr_en_o_ch2;
wire chn_write_base_addr_wr_en_o_ch2;
wire chn_x_transfer_count_wr_en_o_ch2;
wire chn_srctrans_wr_en_o_ch2;
wire chn_destrans_wr_en_o_ch2;
wire chn_xaddrinc_wr_en_o_ch2;
wire chn_fillval_wr_en_o_ch2;
wire chn_srctrigin_wr_en_o_ch2;
wire chn_destrigin_wr_en_o_ch2;
wire chn_trigout_wr_en_o_ch2;
wire chn_next_cmd_addr_wr_en_o_ch2;

wire enable_cmd_to_apb_ch2;
wire [(WIDTH*18)-1 : 0] chn_reg_out_ch2;
wire reg_wr_en_ch2;
wire stat_err_ch2;
wire [31:0] y_transfer_count_UPDATED_ch2;
wire [(WIDTH*3)-1 : 0] src_des_x_transfer_count_updated_ch2;
wire stop_cmd_apb_ch2;
wire [31:0] read_base_addr_UPDATED_ch2;
wire [31:0] write_base_addr_UPDATED_ch2;
wire [31:0] x_transfer_count_UPDATED_ch2;

     wire [2:0]SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR;
     wire [2:0]src_trig_req;
    wire [5:0]  src_trig_req_type;
    wire [2:0]des_trig_req;
    wire [5:0]  des_trig_req_type;
    wire [2:0]       ch_src_ack;
    wire [5:0]  ch_src_ack_type;
    wire [2:0]       ch_des_ack;
    wire [5:0]  ch_des_ack_type;
    wire [2:0]       ch_trigout_req;
    wire [2:0]ch_trigout_ack;
    
    
    
    // from channel to trigger matrix
   wire [2:0]       use_src_trigin;
   wire [5:0]  src_trigin_type;   // 2'b10 = HW
   wire [23:0]  src_trigin_sel;  // 0 = trig0, 1 = trig1  for peripheral 1 and 2 respectively
   wire [2:0]       use_des_trigin;
   wire [5:0]  des_trigin_type;   // 2'b10 = HW
   wire [23:0]  des_trigin_sel;   // 0 = trig0, 1 = trig1
   wire [2:0]       use_trigout;
   wire [5:0]  trigout_type;    // 2'b10 = HW
   wire [17:0]  trigout_sel;      // 0 = trig0, 1 = trig1    


apb_reg #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .NUM_CH(NUM_CH),
    .WIDTH(WIDTH)
) dut_apb_reg (

    .clk(clk),
    .resetn(resetn),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL),
    .enable_cmd_to_apb(enable_cmd_to_apb),
    .chn_reg_in({chn_reg_out_ch2,chn_reg_out_ch1,chn_reg_out_ch0}),
    .PWDATA(PWDATA),
    .PSTRB(PSTRB),

    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
    
    
    // ==========================
    // CONFIG OUTPUTS
    // ==========================
    .cfg_channel_start        ({cfg_channel_start_ch2,        cfg_channel_start_ch1,        cfg_channel_start_ch0}),
    .cfg_channel_status       ({cfg_channel_status_ch2,       cfg_channel_status_ch1,       cfg_channel_status_ch0}),
    .cfg_interrupt_enable     ({cfg_interrupt_enable_ch2,     cfg_interrupt_enable_ch1,     cfg_interrupt_enable_ch0}),
    .cfg_control_config       ({cfg_control_config_ch2,       cfg_control_config_ch1,       cfg_control_config_ch0}),
    .cfg_read_base_addr       ({cfg_read_base_addr_ch2,       cfg_read_base_addr_ch1,       cfg_read_base_addr_ch0}),
    .cfg_write_base_addr      ({cfg_write_base_addr_ch2,      cfg_write_base_addr_ch1,      cfg_write_base_addr_ch0}),
    .cfg_x_transfer_count     ({cfg_x_transfer_count_ch2,     cfg_x_transfer_count_ch1,     cfg_x_transfer_count_ch0}),
    .cfg_read_transfer_cfg    ({cfg_read_transfer_cfg_ch2,    cfg_read_transfer_cfg_ch1,    cfg_read_transfer_cfg_ch0}),
    .cfg_write_transfer_cfg   ({cfg_write_transfer_cfg_ch2,   cfg_write_transfer_cfg_ch1,   cfg_write_transfer_cfg_ch0}),
    .cfg_addr_increment_cfg   ({cfg_addr_increment_cfg_ch2,   cfg_addr_increment_cfg_ch1,   cfg_addr_increment_cfg_ch0}),
    .cfg_fill_data            ({cfg_fill_data_ch2,            cfg_fill_data_ch1,            cfg_fill_data_ch0}),
    .cfg_read_trigger_cfg     ({cfg_read_trigger_cfg_ch2,     cfg_read_trigger_cfg_ch1,     cfg_read_trigger_cfg_ch0}),
    .cfg_write_trigger_cfg    ({cfg_write_trigger_cfg_ch2,    cfg_write_trigger_cfg_ch1,    cfg_write_trigger_cfg_ch0}),
    .cfg_trigger_out_cfg      ({cfg_trigger_out_cfg_ch2,      cfg_trigger_out_cfg_ch1,      cfg_trigger_out_cfg_ch0}),
    .cfg_next_cmd_addr        ({cfg_next_cmd_addr_ch2,        cfg_next_cmd_addr_ch1,        cfg_next_cmd_addr_ch0}),
    .cfg_auto_restart_config  ({cfg_auto_restart_config_ch2,  cfg_auto_restart_config_ch1,  cfg_auto_restart_config_ch0}),
    .cfg_work_reg_pointer     ({cfg_work_reg_pointer_ch2,     cfg_work_reg_pointer_ch1,     cfg_work_reg_pointer_ch0}),
    .cfg_line_stride          ({cfg_line_stride_ch2,          cfg_line_stride_ch1,          cfg_line_stride_ch0}),
    .cfg_y_transfer_count     ({cfg_y_transfer_count_ch2,     cfg_y_transfer_count_ch1,     cfg_y_transfer_count_ch0}),
    
    // ==========================
    // TEMPLATE SIGNALS
    // ==========================
    .cfg_read_template_data   ({cfg_read_template_data_ch2,   cfg_read_template_data_ch1,   cfg_read_template_data_ch0}),
    .cfg_write_template_data  ({cfg_write_template_data_ch2,  cfg_write_template_data_ch1,  cfg_write_template_data_ch0}),
    .cfg_template_config      ({cfg_template_config_ch2,      cfg_template_config_ch1,      cfg_template_config_ch0}),
    
    // ==========================
    // WRITE ENABLE SIGNALS
    // ==========================
    .chn_cmd_wr_en_o              ({chn_cmd_wr_en_o_ch2,              chn_cmd_wr_en_o_ch1,              chn_cmd_wr_en_o_ch0}),
    .chn_stat_wr_en_o             ({chn_stat_wr_en_o_ch2,             chn_stat_wr_en_o_ch1,             chn_stat_wr_en_o_ch0}),
    .chn_intren_wr_en_o           ({chn_intren_wr_en_o_ch2,           chn_intren_wr_en_o_ch1,           chn_intren_wr_en_o_ch0}),
    .chn_ctrl_wr_en_o             ({chn_ctrl_wr_en_o_ch2,             chn_ctrl_wr_en_o_ch1,             chn_ctrl_wr_en_o_ch0}),
    .chn_read_base_addr_wr_en_o   ({chn_read_base_addr_wr_en_o_ch2,   chn_read_base_addr_wr_en_o_ch1,   chn_read_base_addr_wr_en_o_ch0}),
    .chn_write_base_addr_wr_en_o  ({chn_write_base_addr_wr_en_o_ch2,  chn_write_base_addr_wr_en_o_ch1,  chn_write_base_addr_wr_en_o_ch0}),
    .chn_x_transfer_count_wr_en_o ({chn_x_transfer_count_wr_en_o_ch2, chn_x_transfer_count_wr_en_o_ch1, chn_x_transfer_count_wr_en_o_ch0}),
    .chn_srctrans_wr_en_o         ({chn_srctrans_wr_en_o_ch2,         chn_srctrans_wr_en_o_ch1,         chn_srctrans_wr_en_o_ch0}),
    .chn_destrans_wr_en_o         ({chn_destrans_wr_en_o_ch2,         chn_destrans_wr_en_o_ch1,         chn_destrans_wr_en_o_ch0}),
    .chn_xaddrinc_wr_en_o         ({chn_xaddrinc_wr_en_o_ch2,         chn_xaddrinc_wr_en_o_ch1,         chn_xaddrinc_wr_en_o_ch0}),
    .chn_fillval_wr_en_o          ({chn_fillval_wr_en_o_ch2,          chn_fillval_wr_en_o_ch1,          chn_fillval_wr_en_o_ch0}),
    .chn_srctrigin_wr_en_o        ({chn_srctrigin_wr_en_o_ch2,        chn_srctrigin_wr_en_o_ch1,        chn_srctrigin_wr_en_o_ch0}),
    .chn_destrigin_wr_en_o        ({chn_destrigin_wr_en_o_ch2,        chn_destrigin_wr_en_o_ch1,        chn_destrigin_wr_en_o_ch0}),
    .chn_trigout_wr_en_o          ({chn_trigout_wr_en_o_ch2,          chn_trigout_wr_en_o_ch1,          chn_trigout_wr_en_o_ch0}),
    .chn_next_cmd_addr_wr_en_o    ({chn_next_cmd_addr_wr_en_o_ch2,    chn_next_cmd_addr_wr_en_o_ch1,    chn_next_cmd_addr_wr_en_o_ch0}),
    .chn_autocfg_wr_en_o          ({chn_autocfg_wr_en_o_ch2,          chn_autocfg_wr_en_o_ch1,          chn_autocfg_wr_en_o_ch0}),
    .chn_work_reg_pointer_wr_en_o ({chn_work_reg_pointer_wr_en_o_ch2, chn_work_reg_pointer_wr_en_o_ch1, chn_work_reg_pointer_wr_en_o_ch0}),
    .chn_tmpltcfg_wr_en_o         ({chn_tmpltcfg_wr_en_o_ch2,         chn_tmpltcfg_wr_en_o_ch1,         chn_tmpltcfg_wr_en_o_ch0}),
    .chn_destmplt_wr_en_o         ({chn_destmplt_wr_en_o_ch2,         chn_destmplt_wr_en_o_ch1,         chn_destmplt_wr_en_o_ch0}),
    .chn_srctmplt_wr_en_o         ({chn_srctmplt_wr_en_o_ch2,         chn_srctmplt_wr_en_o_ch1,         chn_srctmplt_wr_en_o_ch0}),
    .chn_yaddrestride_wr_en_o     ({chn_yaddrestride_wr_en_o_ch2,     chn_yaddrestride_wr_en_o_ch1,     chn_yaddrestride_wr_en_o_ch0}),
    .chn_y_transfer_count_wr_en_o ({chn_y_transfer_count_wr_en_o_ch2, chn_y_transfer_count_wr_en_o_ch1, chn_y_transfer_count_wr_en_o_ch0}),
    
    // ==========================
    // OTHER OUTPUTS
    // ==========================
    .stop_cmd_apb ({stop_cmd_apb_ch2, stop_cmd_apb_ch1, stop_cmd_apb_ch0}),
    
    // ==========================
    // INPUT BUS PACKING
    // ==========================
    .src_des_x_transfer_count_updated ({
        src_des_x_transfer_count_updated_ch2,
        src_des_x_transfer_count_updated_ch1,
        src_des_x_transfer_count_updated_ch0
    }),
    
    .wrkregval_rd ({
        wrkregval_rd_ch2,
        wrkregval_rd_ch1,
        wrkregval_rd_ch0
    }),
    
    .read_base_addr_UPDATED ({
        read_base_addr_UPDATED_ch2,
        read_base_addr_UPDATED_ch1,
        read_base_addr_UPDATED_ch0
    }),
    
    .write_base_addr_UPDATED ({
        write_base_addr_UPDATED_ch2,
        write_base_addr_UPDATED_ch1,
        write_base_addr_UPDATED_ch0
    }),
    
    .x_transfer_count_UPDATED ({
        x_transfer_count_UPDATED_ch2,
        x_transfer_count_UPDATED_ch1,
        x_transfer_count_UPDATED_ch0
    }),
    
    .y_transfer_count_UPDATED ({
        y_transfer_count_UPDATED_ch2,
        y_transfer_count_UPDATED_ch1,
        y_transfer_count_UPDATED_ch0
    })
    
);


global_channel #(
    .WIDTH(WIDTH),
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .ID_W(ID_W),
    .DEPTH(DEPTH)
) dut_global_channel (

    // ================= CLK / RESET =================
    .clk(clk),
    .resetn(resetn),
    .IRQ(IRQ),

    // ================= BOOT =================
    .boot_en(boot_en),
    .boot_addr(boot_addr),

    // ================= AXI =================
    .ARREADY(ARREADY),
    .ARQOS(ARQOS),
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

    .AWREADY(AWREADY),
    .AWQOS(AWQOS),
    .AWID_D(AWID_D),
    .AWLEN_D(AWLEN_D),
    .AWSIZE_D(AWSIZE_D),
    .AWBURST_D(AWBURST_D),
    .AWVALID_D(AWVALID_D),
    .AWADDR_D(AWADDR_D),

    .WREADY(WREADY),
    .WSTRB(WSTRB),
    .WVALID_D(WVALID_D),
    .WDATA_D(WDATA_D),
    .WLAST_D(WLAST_D),

    .BID(BID),
    .BVALID(BVALID),
    .BRESP(BRESP),
    .BREADY_D(BREADY_D),

    // ================= CH0 =================
    .cfg_work_reg_pointer_ch0(cfg_work_reg_pointer_ch0),
    .cfg_channel_start_ch0(cfg_channel_start_ch0),
    .cfg_channel_status_ch0(cfg_channel_status_ch0),
    .cfg_interrupt_enable_ch0(cfg_interrupt_enable_ch0),
    .cfg_control_config_ch0(cfg_control_config_ch0),
    .cfg_read_base_addr_ch0(cfg_read_base_addr_ch0),
    .cfg_write_base_addr_ch0(cfg_write_base_addr_ch0),
    .cfg_x_transfer_count_ch0(cfg_x_transfer_count_ch0),
    .cfg_read_transfer_cfg_ch0(cfg_read_transfer_cfg_ch0),
    .cfg_write_transfer_cfg_ch0(cfg_write_transfer_cfg_ch0),
    .cfg_addr_increment_cfg_ch0(cfg_addr_increment_cfg_ch0),
    .cfg_fill_data_ch0(cfg_fill_data_ch0),
    .cfg_read_trigger_cfg_ch0(cfg_read_trigger_cfg_ch0),
    .cfg_write_trigger_cfg_ch0(cfg_write_trigger_cfg_ch0),
    .cfg_trigger_out_cfg_ch0(cfg_trigger_out_cfg_ch0),
    .cfg_auto_restart_config_ch0(cfg_auto_restart_config_ch0),
    .cfg_next_cmd_addr_ch0(cfg_next_cmd_addr_ch0),
    .cfg_line_stride_ch0(cfg_line_stride_ch0),
    .cfg_y_transfer_count_ch0(cfg_y_transfer_count_ch0),
    .cfg_read_template_data_ch0(cfg_read_template_data_ch0),
    .cfg_write_template_data_ch0(cfg_write_template_data_ch0),
    .cfg_template_config_ch0(cfg_template_config_ch0),
    .wrkregval_rd_ch0(wrkregval_rd_ch0),

    .chn_autocfg_wr_en_o_ch0(chn_autocfg_wr_en_o_ch0),
    .chn_yaddrestride_wr_en_o_ch0(chn_yaddrestride_wr_en_o_ch0),
    .chn_y_transfer_count_wr_en_o_ch0(chn_y_transfer_count_wr_en_o_ch0),
    .chn_srctmplt_wr_en_o_ch0(chn_srctmplt_wr_en_o_ch0),
    .chn_destmplt_wr_en_o_ch0(chn_destmplt_wr_en_o_ch0),
    .chn_tmpltcfg_wr_en_o_ch0(chn_tmpltcfg_wr_en_o_ch0),
    .chn_work_reg_pointer_wr_en_o_ch0(chn_work_reg_pointer_wr_en_o_ch0),
    .chn_cmd_wr_en_o_ch0(chn_cmd_wr_en_o_ch0),
    .chn_stat_wr_en_o_ch0(chn_stat_wr_en_o_ch0),
    .chn_intren_wr_en_o_ch0(chn_intren_wr_en_o_ch0),
    .chn_ctrl_wr_en_o_ch0(chn_ctrl_wr_en_o_ch0),
    .chn_read_base_addr_wr_en_o_ch0(chn_read_base_addr_wr_en_o_ch0),
    .chn_write_base_addr_wr_en_o_ch0(chn_write_base_addr_wr_en_o_ch0),
    .chn_x_transfer_count_wr_en_o_ch0(chn_x_transfer_count_wr_en_o_ch0),
    .chn_srctrans_wr_en_o_ch0(chn_srctrans_wr_en_o_ch0),
    .chn_destrans_wr_en_o_ch0(chn_destrans_wr_en_o_ch0),
    .chn_xaddrinc_wr_en_o_ch0(chn_xaddrinc_wr_en_o_ch0),
    .chn_fillval_wr_en_o_ch0(chn_fillval_wr_en_o_ch0),
    .chn_srctrigin_wr_en_o_ch0(chn_srctrigin_wr_en_o_ch0),
    .chn_destrigin_wr_en_o_ch0(chn_destrigin_wr_en_o_ch0),
    .chn_trigout_wr_en_o_ch0(chn_trigout_wr_en_o_ch0),
    .chn_next_cmd_addr_wr_en_o_ch0(chn_next_cmd_addr_wr_en_o_ch0),

    .enable_cmd_to_apb_ch0(enable_cmd_to_apb_ch0),
    .chn_reg_out_ch0(chn_reg_out_ch0),
    .reg_wr_en_ch0(reg_wr_en_ch0),
    .stat_err_ch0(stat_err_ch0),
    .y_transfer_count_UPDATED_ch0(y_transfer_count_UPDATED_ch0),
    .src_des_x_transfer_count_updated_ch0(src_des_x_transfer_count_updated_ch0),
    .stop_cmd_apb_ch0(stop_cmd_apb_ch0),
    .read_base_addr_UPDATED_ch0(read_base_addr_UPDATED_ch0),
    .write_base_addr_UPDATED_ch0(write_base_addr_UPDATED_ch0),
    .x_transfer_count_UPDATED_ch0(x_transfer_count_UPDATED_ch0),

    // ================= CH1 =================
    .cfg_work_reg_pointer_ch1(cfg_work_reg_pointer_ch1),
    .cfg_channel_start_ch1(cfg_channel_start_ch1),
    .cfg_channel_status_ch1(cfg_channel_status_ch1),
    .cfg_interrupt_enable_ch1(cfg_interrupt_enable_ch1),
    .cfg_control_config_ch1(cfg_control_config_ch1),
    .cfg_read_base_addr_ch1(cfg_read_base_addr_ch1),
    .cfg_write_base_addr_ch1(cfg_write_base_addr_ch1),
    .cfg_x_transfer_count_ch1(cfg_x_transfer_count_ch1),
    .cfg_read_transfer_cfg_ch1(cfg_read_transfer_cfg_ch1),
    .cfg_write_transfer_cfg_ch1(cfg_write_transfer_cfg_ch1),
    .cfg_addr_increment_cfg_ch1(cfg_addr_increment_cfg_ch1),
    .cfg_fill_data_ch1(cfg_fill_data_ch1),
    .cfg_read_trigger_cfg_ch1(cfg_read_trigger_cfg_ch1),
    .cfg_write_trigger_cfg_ch1(cfg_write_trigger_cfg_ch1),
    .cfg_trigger_out_cfg_ch1(cfg_trigger_out_cfg_ch1),
    .cfg_auto_restart_config_ch1(cfg_auto_restart_config_ch1),
    .cfg_next_cmd_addr_ch1(cfg_next_cmd_addr_ch1),
    .cfg_line_stride_ch1(cfg_line_stride_ch1),
    .cfg_y_transfer_count_ch1(cfg_y_transfer_count_ch1),
    .cfg_read_template_data_ch1(cfg_read_template_data_ch1),
    .cfg_write_template_data_ch1(cfg_write_template_data_ch1),
    .cfg_template_config_ch1(cfg_template_config_ch1),
    .wrkregval_rd_ch1(wrkregval_rd_ch1),

    .chn_autocfg_wr_en_o_ch1(chn_autocfg_wr_en_o_ch1),
    .chn_yaddrestride_wr_en_o_ch1(chn_yaddrestride_wr_en_o_ch1),
    .chn_y_transfer_count_wr_en_o_ch1(chn_y_transfer_count_wr_en_o_ch1),
    .chn_srctmplt_wr_en_o_ch1(chn_srctmplt_wr_en_o_ch1),
    .chn_destmplt_wr_en_o_ch1(chn_destmplt_wr_en_o_ch1),
    .chn_tmpltcfg_wr_en_o_ch1(chn_tmpltcfg_wr_en_o_ch1),
    .chn_work_reg_pointer_wr_en_o_ch1(chn_work_reg_pointer_wr_en_o_ch1),
    .chn_cmd_wr_en_o_ch1(chn_cmd_wr_en_o_ch1),
    .chn_stat_wr_en_o_ch1(chn_stat_wr_en_o_ch1),
    .chn_intren_wr_en_o_ch1(chn_intren_wr_en_o_ch1),
    .chn_ctrl_wr_en_o_ch1(chn_ctrl_wr_en_o_ch1),
    .chn_read_base_addr_wr_en_o_ch1(chn_read_base_addr_wr_en_o_ch1),
    .chn_write_base_addr_wr_en_o_ch1(chn_write_base_addr_wr_en_o_ch1),
    .chn_x_transfer_count_wr_en_o_ch1(chn_x_transfer_count_wr_en_o_ch1),
    .chn_srctrans_wr_en_o_ch1(chn_srctrans_wr_en_o_ch1),
    .chn_destrans_wr_en_o_ch1(chn_destrans_wr_en_o_ch1),
    .chn_xaddrinc_wr_en_o_ch1(chn_xaddrinc_wr_en_o_ch1),
    .chn_fillval_wr_en_o_ch1(chn_fillval_wr_en_o_ch1),
    .chn_srctrigin_wr_en_o_ch1(chn_srctrigin_wr_en_o_ch1),
    .chn_destrigin_wr_en_o_ch1(chn_destrigin_wr_en_o_ch1),
    .chn_trigout_wr_en_o_ch1(chn_trigout_wr_en_o_ch1),
    .chn_next_cmd_addr_wr_en_o_ch1(chn_next_cmd_addr_wr_en_o_ch1),

    .enable_cmd_to_apb_ch1(enable_cmd_to_apb_ch1),
    .chn_reg_out_ch1(chn_reg_out_ch1),
    .reg_wr_en_ch1(reg_wr_en_ch1),
    .stat_err_ch1(stat_err_ch1),
    .y_transfer_count_UPDATED_ch1(y_transfer_count_UPDATED_ch1),
    .src_des_x_transfer_count_updated_ch1(src_des_x_transfer_count_updated_ch1),
    .stop_cmd_apb_ch1(stop_cmd_apb_ch1),
    .read_base_addr_UPDATED_ch1(read_base_addr_UPDATED_ch1),
    .write_base_addr_UPDATED_ch1(write_base_addr_UPDATED_ch1),
    .x_transfer_count_UPDATED_ch1(x_transfer_count_UPDATED_ch1),

    // ================= CH2 =================
    .cfg_work_reg_pointer_ch2(cfg_work_reg_pointer_ch2),
    .cfg_channel_start_ch2(cfg_channel_start_ch2),
    .cfg_channel_status_ch2(cfg_channel_status_ch2),
    .cfg_interrupt_enable_ch2(cfg_interrupt_enable_ch2),
    .cfg_control_config_ch2(cfg_control_config_ch2),
    .cfg_read_base_addr_ch2(cfg_read_base_addr_ch2),
    .cfg_write_base_addr_ch2(cfg_write_base_addr_ch2),
    .cfg_x_transfer_count_ch2(cfg_x_transfer_count_ch2),
    .cfg_read_transfer_cfg_ch2(cfg_read_transfer_cfg_ch2),
    .cfg_write_transfer_cfg_ch2(cfg_write_transfer_cfg_ch2),
    .cfg_addr_increment_cfg_ch2(cfg_addr_increment_cfg_ch2),
    .cfg_fill_data_ch2(cfg_fill_data_ch2),
    .cfg_read_trigger_cfg_ch2(cfg_read_trigger_cfg_ch2),
    .cfg_write_trigger_cfg_ch2(cfg_write_trigger_cfg_ch2),
    .cfg_trigger_out_cfg_ch2(cfg_trigger_out_cfg_ch2),
    .cfg_auto_restart_config_ch2(cfg_auto_restart_config_ch2),
    .cfg_next_cmd_addr_ch2(cfg_next_cmd_addr_ch2),
    .cfg_line_stride_ch2(cfg_line_stride_ch2),
    .cfg_y_transfer_count_ch2(cfg_y_transfer_count_ch2),
    .cfg_read_template_data_ch2(cfg_read_template_data_ch2),
    .cfg_write_template_data_ch2(cfg_write_template_data_ch2),
    .cfg_template_config_ch2(cfg_template_config_ch2),
    .wrkregval_rd_ch2(wrkregval_rd_ch2),

    .chn_autocfg_wr_en_o_ch2(chn_autocfg_wr_en_o_ch2),
    .chn_yaddrestride_wr_en_o_ch2(chn_yaddrestride_wr_en_o_ch2),
    .chn_y_transfer_count_wr_en_o_ch2(chn_y_transfer_count_wr_en_o_ch2),
    .chn_srctmplt_wr_en_o_ch2(chn_srctmplt_wr_en_o_ch2),
    .chn_destmplt_wr_en_o_ch2(chn_destmplt_wr_en_o_ch2),
    .chn_tmpltcfg_wr_en_o_ch2(chn_tmpltcfg_wr_en_o_ch2),
    .chn_work_reg_pointer_wr_en_o_ch2(chn_work_reg_pointer_wr_en_o_ch2),
    .chn_cmd_wr_en_o_ch2(chn_cmd_wr_en_o_ch2),
    .chn_stat_wr_en_o_ch2(chn_stat_wr_en_o_ch2),
    .chn_intren_wr_en_o_ch2(chn_intren_wr_en_o_ch2),
    .chn_ctrl_wr_en_o_ch2(chn_ctrl_wr_en_o_ch2),
    .chn_read_base_addr_wr_en_o_ch2(chn_read_base_addr_wr_en_o_ch2),
    .chn_write_base_addr_wr_en_o_ch2(chn_write_base_addr_wr_en_o_ch2),
    .chn_x_transfer_count_wr_en_o_ch2(chn_x_transfer_count_wr_en_o_ch2),
    .chn_srctrans_wr_en_o_ch2(chn_srctrans_wr_en_o_ch2),
    .chn_destrans_wr_en_o_ch2(chn_destrans_wr_en_o_ch2),
    .chn_xaddrinc_wr_en_o_ch2(chn_xaddrinc_wr_en_o_ch2),
    .chn_fillval_wr_en_o_ch2(chn_fillval_wr_en_o_ch2),
    .chn_srctrigin_wr_en_o_ch2(chn_srctrigin_wr_en_o_ch2),
    .chn_destrigin_wr_en_o_ch2(chn_destrigin_wr_en_o_ch2),
    .chn_trigout_wr_en_o_ch2(chn_trigout_wr_en_o_ch2),
    .chn_next_cmd_addr_wr_en_o_ch2(chn_next_cmd_addr_wr_en_o_ch2),

    .enable_cmd_to_apb_ch2(enable_cmd_to_apb_ch2),
    .chn_reg_out_ch2(chn_reg_out_ch2),
    .reg_wr_en_ch2(reg_wr_en_ch2),
    .stat_err_ch2(stat_err_ch2),
    .y_transfer_count_UPDATED_ch2(y_transfer_count_UPDATED_ch2),
    .src_des_x_transfer_count_updated_ch2(src_des_x_transfer_count_updated_ch2),
    .stop_cmd_apb_ch2(stop_cmd_apb_ch2),
    .read_base_addr_UPDATED_ch2(read_base_addr_UPDATED_ch2),
    .write_base_addr_UPDATED_ch2(write_base_addr_UPDATED_ch2),
    .x_transfer_count_UPDATED_ch2(x_transfer_count_UPDATED_ch2),
    
    
     // ---------------- ERROR ----------------
    .SRCTRIGINSELERR (SRCTRIGINSELERR),
    .DESTRIGINSELERR (DESTRIGINSELERR),
    .TRIGOUTSELERR   (TRIGOUTSELERR),

    // ---------------- SRC TRIG ----------------
    .src_trig_req        (src_trig_req),
    .src_trig_req_type   (src_trig_req_type),
    .ch_src_ack          (ch_src_ack),
    .ch_src_ack_type     (ch_src_ack_type),

    // ---------------- DEST TRIG ----------------
    .des_trig_req        (des_trig_req),
    .des_trig_req_type   (des_trig_req_type),
    .ch_des_ack          (ch_des_ack),
    .ch_des_ack_type     (ch_des_ack_type),

    // ---------------- TRIG OUT ----------------
    .ch_trigout_req      (ch_trigout_req),
    .ch_trigout_ack      (ch_trigout_ack),

    // ---------------- CONFIG FROM CHANNEL ----------------
    .use_src_trigin      (use_src_trigin),
    .src_trigin_type     (src_trigin_type),
    .src_trigin_sel      (src_trigin_sel),

    .use_des_trigin      (use_des_trigin),
    .des_trigin_type     (des_trigin_type),
    .des_trigin_sel      (des_trigin_sel),

    .use_trigout         (use_trigout),
    .trigout_type        (trigout_type),
    .trigout_sel         (trigout_sel)
);
   //////////////////////////////////////////////////////////////////////// 
    trigger_matrix_multi dut_trig_mtx (

    // -------- STATUS --------
    .STAT_ERR ({stat_err_ch0,stat_err_ch1,stat_err_ch2}),

    // -------- PERIPHERALS --------
    .trig_req        (trig_req),
    .trig_req_type   (trig_req_type),
    .trig_ack        (trig_ack),
    .trig_ack_type   (trig_ack_type),

    .trig_out_req    (trig_out_req),
    .trig_out_ack    (trig_out_ack),

    // -------- CHANNEL CONFIG --------
    .use_src_trigin  (use_src_trigin),
    .src_trigin_type (src_trigin_type),
    .src_trigin_sel  (src_trigin_sel),

    .use_des_trigin  (use_des_trigin),
    .des_trigin_type (des_trigin_type),
    .des_trigin_sel  (des_trigin_sel),

    .use_trigout     (use_trigout),
    .trigout_type    (trigout_type),
    .trigout_sel     (trigout_sel),

    // -------- TO CHANNEL --------
    .src_trig_req        (src_trig_req),
    .src_trig_req_type   (src_trig_req_type),
    .des_trig_req        (des_trig_req),
    .des_trig_req_type   (des_trig_req_type),

    // -------- FROM CHANNEL --------
    .ch_src_ack      (ch_src_ack),
    .ch_src_ack_type (ch_src_ack_type),
    .ch_des_ack      (ch_des_ack),
    .ch_des_ack_type (ch_des_ack_type),

    .ch_trigout_req  (ch_trigout_req),
    .ch_trigout_ack  (ch_trigout_ack),

    // -------- ERROR --------
    .SRCTRIGINSELERR (SRCTRIGINSELERR),
    .DESTRIGINSELERR (DESTRIGINSELERR),
    .TRIGOUTSELERR   (TRIGOUTSELERR)

);
    
endmodule

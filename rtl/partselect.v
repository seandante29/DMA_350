
module partselect (
// INTERNAL REGISTERS
    input  wire [31:0] control_config,
    input  wire [31:0] x_transfer_count,
    input  wire [31:0] CH_next_cmd_addr,
    input  wire [31:0] channel_start,
    input  wire [31:0] channel_status,
    //input  wire [31:0] ERROR_INFO,
    input  wire [31:0] addr_increment_cfg,
    input  wire [31:0] read_trigger_cfg,
    input  wire [31:0] write_trigger_cfg,
    input  wire [31:0] trigger_out_cfg,
    input  wire [31:0] read_base_addr,
    input  wire [31:0] write_base_addr,
    input  wire [31:0] fill_data,
     input wire [31:0] template_config,
     input wire [31:0]line_stride,
     input wire [31:0] y_transfer_count,
 input wire [31:0] read_template_data,
 input wire [31:0] write_template_data,
 input wire [31:0] write_transfer_cfg,
 input wire [31:0] read_transfer_cfg,
 input wire [31:0] auto_restart_config,
// CONTROL / CONFIG OUTPUTS
    output wire        use_trigout,
    output wire        use_des_trigin,
    output wire        use_src_trigin,
    output wire [2:0]  x_type,y_type,
    output wire [2:0]  transize,
    output wire [15:0] srcx_transfer_count,
    output wire [15:0] desx_transfer_count,
    output wire [31:0] next_cmd_addr,
    output wire        next_cmd_addren,
    output wire [4:0] des_tmplt_size,
    output wire [4:0] src_tmplt_size,
    output wire [31:0] des_tmplt,
    output wire [31:0] src_tmplt,
// COMMAND OUTPUTS
    output wire        enable_cmd,
    output wire        disable_cmd,
    output wire        pause_cmd,
    output wire        resume_cmd,
    output wire        stop_cmd,
    output wire        src_trigin_sw,
    output wire [1:0]  src_trigin_sw_type,
    output wire        des_trigin_sw,
    output wire [1:0]  des_trigin_sw_type,
    output wire        trigout_ack_sw,
// TRIGGER CONFIG OUTPUTS
    output wire [1:0]  src_trigin_mode,
    output wire [1:0]  src_trigin_type,
    output wire [7:0]  src_trigin_sel,
    output wire [1:0]  des_trigin_mode,
    output wire [1:0]  des_trigin_type,
    output wire [7:0]  des_trigin_sel,
    output wire [1:0]  trigout_type,
    output wire [5:0]  trigout_sel,
// ADDRESS / FILL
    output wire [31:0] src_addr,
    output wire [31:0] des_addr,
    output wire [31:0] fillval,
// ADDRESS INC
    output wire [15:0] src_xaddr_inc,
    output wire [15:0] des_xaddr_inc,
    output wire [7:0]des_trigin_blk_size,
    output wire [7:0]src_trigin_blk_size,
// STATUS / ERROR
    output wire        stat_done,
    output wire        stat_err,
    output wire [3:0] src_max_burst_len,
    output wire [3:0] des_max_burst_len,
        
    output [15:0] src_yaddr_stride,
    output [15:0] des_yaddr_stride,
    output [15:0] src_y_transfer_count,
    output [15:0] des_y_transfer_count,
    output wire done_pause_en,
    output wire cmd_restart_en,//
    output wire [15:0] cmd_restart_cnt,//
    output wire [2:0] reg_reload_type,// 
    output wire [2:0] done_type
//    output wire        stat_disable_part,
//    output wire         stat_stop_part
    /*,
    output wire        cfgconflerr,
    output wire        regvalerr,
    output wire        linkderr,
    output wire        axirdpoiserr,
    output wire        axiwrresperr,
    output wire        axirdresperr,
    output wire        trigoutselerr,
    output wire        destrigin_selerr,
    output wire        srctrigin_selerr,
    output wire        cfgerr,
    output wire        buserr */
);
// control_config
assign use_trigout     = control_config[27];
assign use_des_trigin  = control_config[26];
assign use_src_trigin  = control_config[25];
assign x_type          = control_config[11:9];
assign y_type          = control_config[14:12]; 
assign transize        = control_config[2:0];
// x_transfer_count
assign desx_transfer_count = x_transfer_count[31:16];
assign srcx_transfer_count = x_transfer_count[15:0];
assign src_yaddr_stride = line_stride[15:0];
assign des_yaddr_stride = line_stride[31:16];
assign src_y_transfer_count = y_transfer_count[15:0];
assign des_y_transfer_count = y_transfer_count[31:16];

    
// CH_next_cmd_addr
assign next_cmd_addr   = {2'b00,CH_next_cmd_addr[31:2]};
assign next_cmd_addren = CH_next_cmd_addr[0];
// channel_start
assign trigout_ack_sw      = channel_start[24];
assign des_trigin_sw_type  = channel_start[22:21];
assign des_trigin_sw       = channel_start[20];
assign src_trigin_sw_type  = channel_start[18:17];
assign src_trigin_sw       = channel_start[16];
assign resume_cmd          = channel_start[5];
assign pause_cmd           = channel_start[4];
assign stop_cmd              = channel_start[3];
assign disable_cmd         = channel_start[2];
assign enable_cmd          = channel_start[0];
// channel_status
assign stat_err  = channel_status[17];
assign stat_done = channel_status[16];
//assign stat_disable_part = channel_status [18];
//assign stat_stop_part = channel_status [19];

// addr_increment_cfg
assign des_xaddr_inc = addr_increment_cfg[31:16];
assign src_xaddr_inc = addr_increment_cfg[15:0];
// read_trigger_cfg
assign src_trigin_mode = read_trigger_cfg[11:10];
assign src_trigin_type = read_trigger_cfg[9:8];
assign src_trigin_sel  = read_trigger_cfg[7:0];
// write_trigger_cfg
assign des_trigin_mode = write_trigger_cfg[11:10];
assign des_trigin_type = write_trigger_cfg[9:8];
assign des_trigin_sel  = write_trigger_cfg[7:0];
// trigger_out_cfg
assign trigout_type = trigger_out_cfg[9:8];
assign trigout_sel  = trigger_out_cfg[5:0];
// ADDRESSES / FILL
assign src_addr = read_base_addr;
assign des_addr = write_base_addr;
assign fillval  = fill_data;

assign src_tmplt = read_template_data;
assign des_tmplt = write_template_data;
assign src_tmplt_size = template_config[12:8];
assign des_tmplt_size =  template_config [20:16];

assign src_trigin_blk_size = read_trigger_cfg[23:16];
assign des_trigin_blk_size = write_trigger_cfg[23:16];

assign des_max_burst_len = write_transfer_cfg[19:16];
assign src_max_burst_len = read_transfer_cfg[19:16];

assign cmd_restart_en = auto_restart_config [16];
assign cmd_restart_cnt = auto_restart_config [15:0];
assign reg_reload_type = control_config[20:18];
assign done_type = control_config[23:21];
assign done_pause_en = control_config [24];
// ERROR_INFO
/*
assign cfgconflerr        = ERROR_INFO[26];
assign regvalerr          = ERROR_INFO[25];
assign linkderr           = ERROR_INFO[24];
assign axirdpoiserr       = ERROR_INFO[18];
assign axiwrresperr       = ERROR_INFO[17];
assign axirdresperr       = ERROR_INFO[16];
assign trigoutselerr      = ERROR_INFO[4];
assign destrigin_selerr   = ERROR_INFO[3];
assign srctrigin_selerr   = ERROR_INFO[2];
assign cfgerr             = ERROR_INFO[1];
assign buserr             = ERROR_INFO[0];
*/
endmodule
 

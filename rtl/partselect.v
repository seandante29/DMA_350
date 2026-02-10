
module partselect (
    // INTERNAL REGISTERS
    input  wire [31:0] CH_CTRL,
    input  wire [31:0] CH_XSIZE,
    input  wire [31:0] CH_LINKADDR,
    input  wire [31:0] CH_CMD,
    input  wire [31:0] CH_STATUS,
    input  wire [31:0] CH_XADDRINC,
    input  wire [31:0] CH_SRCTRIGINCFG,
    input  wire [31:0] CH_DESTRIGINCFG,
    input  wire [31:0] CH_TRIGOUTCFG,
    input  wire [31:0] CH_SRCADDR,
    input  wire [31:0] CH_DESADDR,
    input  wire [31:0] CH_FILLVAL,
    // CONTROL / CONFIG OUTPUTS
    output wire        use_trigout,
    output wire        use_des_trigin,
    output wire        use_src_trigin,
    output wire [2:0]  x_type,
    output wire [2:0]  transize,
    output wire [15:0] srcxsize,
    output wire [15:0] desxsize,
    output wire [31:2] linkaddr,
    output wire        linkaddren,
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
    // STATUS / ERROR
    output wire        stat_done,
    output wire        stat_err 
);

    // CH_CTRL
    assign use_trigout     = CH_CTRL[27];
    assign use_des_trigin  = CH_CTRL[26];
    assign use_src_trigin  = CH_CTRL[25];
    assign x_type          = CH_CTRL[11:9];
    assign transize        = CH_CTRL[2:0];
    // CH_XSIZE
    assign desxsize = CH_XSIZE[31:16];
    assign srcxsize = CH_XSIZE[15:0];
    // CH_LINKADDR
    assign linkaddr   = CH_LINKADDR[31:2];
    assign linkaddren = CH_LINKADDR[0];
    // CH_CMD
    assign trigout_ack_sw      = CH_CMD[24];
    assign des_trigin_sw_type  = CH_CMD[22:21];
    assign des_trigin_sw       = CH_CMD[20];
    assign src_trigin_sw_type  = CH_CMD[18:17];
    assign src_trigin_sw       = CH_CMD[16];
    assign resume_cmd          = CH_CMD[5];
    assign pause_cmd           = CH_CMD[4];
    assign stop_cmd              = CH_CMD[3];
    assign disable_cmd         = CH_CMD[2];
    assign enable_cmd          = CH_CMD[0];
    // CH_STATUS
    assign stat_err  = CH_STATUS[17];
    assign stat_done = CH_STATUS[16];
    // CH_XADDRINC
    assign des_xaddr_inc = CH_XADDRINC[31:16];
    assign src_xaddr_inc = CH_XADDRINC[15:0];
    // CH_SRCTRIGINCFG
    assign src_trigin_mode = CH_SRCTRIGINCFG[11:10];
    assign src_trigin_type = CH_SRCTRIGINCFG[9:8];
    assign src_trigin_sel  = CH_SRCTRIGINCFG[7:0];
    // CH_DESTRIGINCFG
    assign des_trigin_mode = CH_DESTRIGINCFG[11:10];
    assign des_trigin_type = CH_DESTRIGINCFG[9:8];
    assign des_trigin_sel  = CH_DESTRIGINCFG[7:0];
    // CH_TRIGOUTCFG
    assign trigout_type = CH_TRIGOUTCFG[9:8];
    assign trigout_sel  = CH_TRIGOUTCFG[5:0];
    // ADDRESSES / FILL
    assign src_addr = CH_SRCADDR;
    assign des_addr = CH_DESADDR;
    assign fillval  = CH_FILLVAL;
    
endmodule
 

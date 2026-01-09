`timescale 1ns / 1ps

module tb_partselect;

    // INTERNAL REGISTERS
    reg  [31:0] CH_CTRL;
    reg  [31:0] CH_XSIZE;
    reg  [31:0] CH_LINKADDR;
    reg  [31:0] CH_CMD;
    reg  [31:0] CH_STATUS;
    //reg  [31:0] ERROR_INFO;
    reg  [31:0] CH_XADDRINC;
    reg  [31:0] CH_SRCTRIGINCFG;
    reg  [31:0] CH_DESTRIGINCFG;
    reg  [31:0] CH_TRIGOUTCFG;
    reg  [31:0] CH_SRCADDR;
    reg  [31:0] CH_DESADDR;
    reg  [31:0] CH_FILLVAL;

    // OUTPUT WIRES
    wire        use_trigout;
    wire        use_des_trigin;
    wire        use_src_trigin;
    wire [2:0]  x_type;
    wire [2:0]  transize;
    wire [15:0] srcxsize;
    wire [15:0] desxsize;
    wire [31:2] linkaddr;
    wire        linkaddren;

    wire        enable_cmd;
    wire        disable_cmd;
    wire        pause_cmd;
    wire        resume_cmd;
    wire        src_trigin_sw;
    wire [1:0]  src_trigin_sw_type;
    wire        des_trigin_sw;
    wire [1:0]  des_trigin_sw_type;
    wire        trigout_ack_sw;

    wire [1:0]  src_trigin_mode;
    wire [1:0]  src_trigin_type;
    wire [7:0]  src_trigin_sel;
    wire [1:0]  des_trigin_mode;
    wire [1:0]  des_trigin_type;
    wire [7:0]  des_trigin_sel;
    wire [1:0]  trigout_type;
    wire [5:0]  trigout_sel;

    wire [31:0] src_addr;
    wire [31:0] des_addr;
    wire [31:0] fillval;

    wire [15:0] src_xaddr_inc;
    wire [15:0] des_xaddr_inc;

    wire        stat_done;
    wire        stat_err;
    /*wire        cfgconflerr;
    wire        regvalerr;
    wire        linkderr;
    wire        axirdpoiserr;
    wire        axiwrresperr;
    wire        axirdresperr;
    wire        trigoutselerr;
    wire        destrigin_selerr;
    wire        srctrigin_selerr;
    wire        cfgerr;
    wire        buserr;*/

    // DUT
partselect dut (
    // INTERNAL REGISTERS
    .CH_CTRL           (CH_CTRL),
    .CH_XSIZE          (CH_XSIZE),
    .CH_LINKADDR       (CH_LINKADDR),
    .CH_CMD            (CH_CMD),
    .CH_STATUS         (CH_STATUS),
    .CH_XADDRINC       (CH_XADDRINC),
    .CH_SRCTRIGINCFG   (CH_SRCTRIGINCFG),
    .CH_DESTRIGINCFG   (CH_DESTRIGINCFG),
    .CH_TRIGOUTCFG     (CH_TRIGOUTCFG),
    .CH_SRCADDR        (CH_SRCADDR),
    .CH_DESADDR        (CH_DESADDR),
    .CH_FILLVAL        (CH_FILLVAL),
    .use_trigout       (use_trigout),
    .use_des_trigin    (use_des_trigin),
    .use_src_trigin    (use_src_trigin),
    .x_type            (x_type),
    .transize          (transize),
    .srcxsize          (srcxsize),
    .desxsize          (desxsize),
    .linkaddr          (linkaddr),
    .linkaddren        (linkaddren),
    .enable_cmd        (enable_cmd),
    .disable_cmd       (disable_cmd),
    .pause_cmd         (pause_cmd),
    .resume_cmd        (resume_cmd),
    .src_trigin_sw     (src_trigin_sw),
    .src_trigin_sw_type(src_trigin_sw_type),
    .des_trigin_sw     (des_trigin_sw),
    .des_trigin_sw_type(des_trigin_sw_type),
    .trigout_ack_sw    (trigout_ack_sw),
    .src_trigin_mode   (src_trigin_mode),
    .src_trigin_type   (src_trigin_type),
    .src_trigin_sel    (src_trigin_sel),
    .des_trigin_mode   (des_trigin_mode),
    .des_trigin_type   (des_trigin_type),
    .des_trigin_sel    (des_trigin_sel),
    .trigout_type      (trigout_type),
    .trigout_sel       (trigout_sel),
    .src_addr          (src_addr),
    .des_addr          (des_addr),
    .fillval           (fillval),
    .src_xaddr_inc     (src_xaddr_inc),
    .des_xaddr_inc     (des_xaddr_inc),
    .stat_done         (stat_done),
    .stat_err          (stat_err)
);


    initial begin
        // CH_CTRL: use_trigout=1, use_des_trigin=1, use_src_trigin=1, x_type=1, transize=5
        CH_CTRL = 32'h0E00_0205;

        // CH_XSIZE: desxsize=16, srcxsize=8
        CH_XSIZE = 32'h0010_0008;

        // CH_LINKADDR: linkaddr=0x8000_0000, linkaddren=1
        CH_LINKADDR = 32'h8000_0001;

        // CH_CMD: trigout_ack_sw=1, des_sw_trig type=2, src_sw_trig type=1, enable_cmd=1
        CH_CMD = 32'h0152_0031;

        // CH_STATUS: stat_err=1, stat_done=1
        CH_STATUS = 32'h0003_0000;

        // CH_XADDRINC: des_xaddr_inc=1, src_xaddr_inc=1
        CH_XADDRINC = 32'h0001_0001;

        // CH_SRCTRIGINCFG: mode=0, type=2(HW), sel=0x82
        CH_SRCTRIGINCFG = 32'h0000_0282;

        // CH_DESTRIGINCFG: mode=0, type=2(HW), sel=0x81
        CH_DESTRIGINCFG = 32'h0000_0281;

        // CH_TRIGOUTCFG: type=2(HW), sel=3
        CH_TRIGOUTCFG = 32'h0000_0203;

        // SOURCE ADDRESS
        CH_SRCADDR = 32'h1000_0000;

        // DESTINATION ADDRESS
        CH_DESADDR = 32'h2000_0000;

        // FILL VALUE
        CH_FILLVAL = 32'hDEAD_BEEF;

        // ERROR_INFO: cfgconflerr, trigoutselerr, srctrigin_selerr, buserr
       // ERROR_INFO = 32'h0400_0015;

        #10;
        $stop;
    end

endmodule
 

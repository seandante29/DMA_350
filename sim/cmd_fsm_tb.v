`timescale 1ns / 1ps

module tb_cmd_fsm;

  reg clk;
  reg resetn;
  reg STAT_ERROR;
  reg  [31:0] LINKADDR;
  reg         link_enable;
  reg         data_done;

  reg         ARREADY;
  reg         RID;
  reg  [31:0] RDATA_I;
  reg  [1:0]  RRESP;
  reg         RLAST;
  reg         RVALID;

  wire [3:0]  ARID;
  wire [3:0]  ARLEN;
  wire [2:0]  ARSIZE;
  wire [1:0]  ARBURST;
  wire        ARVALID;
  wire [31:0] ARADDR;

  wire        LINKHDRERR;
  wire        RREADY;
  wire [31:0] RDATA_O;
  wire [31:0] LINK_HEADER;

  wire CMD_DONE;
  wire AXIRDRESPERR;
  wire AXIRDPOISERR;
  wire BUSERR;

  // DUT
  cmd_fsm dut (
    .clk(clk),
    .resetn(resetn),
    .LINKADDR(LINKADDR),
    .link_enable(link_enable),
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

    .LINKHDRERR(LINKHDRERR),
    .RREADY(RREADY),
    .RDATA_O(RDATA_O),
    .LINK_HEADER(LINK_HEADER),

    .CMD_DONE(CMD_DONE),
    .AXIRDRESPERR(AXIRDRESPERR),
    .AXIRDPOISERR(AXIRDPOISERR),
    .BUSERR(BUSERR),
    .STAT_ERROR(STAT_ERROR)
  );

  // Clock
  always #5 clk = ~clk;

  initial begin
    // ---------------- INIT ----------------
    clk = 0;
    resetn = 0;
    LINKADDR = 32'h1000_0000;
    link_enable = 0;
    data_done = 0;
    ARREADY = 0;
    RVALID = 0;
    RLAST = 0;
    RDATA_I = 0;
    RRESP = 2'b00;
    RID = 0;
    STAT_ERROR = 0;

    // ---------------- RESET ----------------
    #20 resetn = 1;

    // ---------------- START COMMAND ----------------
    #10 link_enable = 1;
        data_done   = 1;

    // ---------------- AR FOR LINK HEADER ----------------
    #20 ARREADY = 1;
    #10 ARREADY = 0;

    // ---------------- R : LINK HEADER ----------------
    #20 RVALID  = 1;
        RLAST   = 1;
       // RDATA_I = 32'hABCD_0005;   // header (count = 5)
        RDATA_I = 32'd0;
        RRESP   = 2'b00;

    #10 RVALID = 0;
        RLAST  = 0;

    // ---------------- AR FOR DATA BURST ----------------
    #30 ARREADY = 1;
    #10 ARREADY = 0;
STAT_ERROR = 1;
#20 STAT_ERROR = 0;
    // ---------------- R : BURST DATA (5 beats) ----------------
    #20 RVALID = 1; RDATA_I = 32'h1111_0001; RLAST = 0;
    #10        RDATA_I = 32'h1111_0002;
    #10        RDATA_I = 32'h1111_0003;
    #10        RDATA_I = 32'h1111_0004;
    #10 begin
              RDATA_I = 32'h1111_0005;
              RLAST   = 1;
         end

    #10 RVALID = 0;
        RLAST  = 0;

    // ---------------- END ----------------
    #50 $finish;
  end

endmodule
 

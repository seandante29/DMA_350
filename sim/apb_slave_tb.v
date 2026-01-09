`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.01.2026 10:43:27
// Design Name: 
// Module Name: tb_apb_slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_apb_slave;

  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 8;
  localparam STRB_WIDTH = DATA_WIDTH/8;

  // APB signals
  reg  PCLK;
  reg  PRESETn;
  reg  [ADDR_WIDTH-1:0] PADDR;
  reg  PWRITE;
  reg  PSEL;
  reg  PENABLE;
  reg  [DATA_WIDTH-1:0] PWDATA;
  reg  [STRB_WIDTH-1:0] PSTRB;
  wire [DATA_WIDTH-1:0] PRDATA;
  wire PREADY;
  wire PSLVERR;

  // Register-bank interface (NO model)
  reg  [DATA_WIDTH-1:0] cfg_rdata;
  wire [DATA_WIDTH-1:0] cfg_wdata;
  wire [ADDR_WIDTH-1:0] cfg_addr;
  wire cfg_wr_en;
  wire cfg_rd_en;

  // DUT
  apb_slave dut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .PSTRB(PSTRB),
    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),
    .cfg_rdata(cfg_rdata),
    .cfg_wdata(cfg_wdata),
    .cfg_addr(cfg_addr),
    .cfg_wr_en(cfg_wr_en),
    .cfg_rd_en(cfg_rd_en)
  );

  // Clock (only always block)
  always #5 PCLK = ~PCLK;

  initial begin
    // ---------------- RESET ----------------
    PCLK     = 0;
    PRESETn  = 0;
    PSEL     = 0;
    PENABLE  = 0;
    PWRITE   = 0;
    PADDR    = 0;
    PWDATA   = 0;
    PSTRB    = 4'hF;
    cfg_rdata = 32'h0;

    #20;
    PRESETn = 1;

    // ==================================================
    // CASE 1: WRITE @ 0x04
    // ==================================================
    #30;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 8'h04;
    PWDATA  = 32'hAAAA_1111;
    PSTRB   = 4'hF;
    PENABLE = 0;   // SETUP

    #10;
    PENABLE = 1;   // ACCESS

    #30;
    PSEL    = 0;
    PENABLE = 0;

    // ==================================================
    // CASE 2: WRITE @ 0x08
    // ==================================================
    #20;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 8'h08;
    PWDATA  = 32'hBBBB_2222;
    PSTRB   = 4'hF;
    PENABLE = 0;

    #10;
    PENABLE = 1;

    #10;
  //  PSEL    = 0;
    PENABLE = 0;

    // ==================================================
    // CASE 3: READ @ 0x04
    // ==================================================
    #20;
    cfg_rdata = 32'hAAAA_1111;   // data returned by regbank
    PSEL      = 1;
    PWRITE    = 0;
    PADDR     = 8'h04;
    PENABLE   = 0;

    #10;
    PENABLE = 1;

    #10;
  //  PSEL    = 0;
    PENABLE = 0;

    // ==================================================
    // CASE 4: READ @ 0x08
    // ==================================================
    #20;
    cfg_rdata = 32'hBBBB_2222;
    PSEL      = 1;
    PWRITE    = 0;
    PADDR     = 8'h08;
    //PENABLE   = 0;

    #10;
    PENABLE = 1;

    #30;
  //  PSEL    = 0;
    //PENABLE = 0;

    // ==================================================
    // CASE 5: WRITE with BAD STROBE (PSLVERR)
    // ==================================================
    #20;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 8'h0C;
    PWDATA  = 32'hDEAD_BEEF;
    PSTRB   = 4'b0011;   // ❌ invalid
    PENABLE = 0;

    #10;
    PENABLE = 1;

    #10;
   // PSEL    = 0;
   // PENABLE = 0;
    PSTRB   = 4'hF;

    #30;
    $finish;
  end

endmodule
 

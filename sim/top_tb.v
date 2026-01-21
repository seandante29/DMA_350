`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2026 03:38:10 PM
// Design Name: 
// Module Name: top_tb
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

module top_tb ;

    parameter WIDTH = 32;
    parameter DATA_W = 128;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter STRB_WIDTH =  DATA_WIDTH/8;
// -------------------------------------------------
// clocks & resets (inputs → reg)
// -------------------------------------------------
reg clk;
reg resetn;
reg PCLK;
reg PRESETn;

// -------------------------------------------------
// APB interface (inputs → reg)
// -------------------------------------------------
reg  [31:0] PADDR;
reg         PWRITE;
reg         PENABLE;
reg         PSEL;
reg  [31:0] PWDATA;
reg  [3:0]  PSTRB;

// APB outputs (outputs → wire)
wire [31:0] PRDATA;
wire        PREADY;
wire        PSLVERR;

// -------------------------------------------------
// trigger matrix (inputs → reg, outputs → wire)
// -------------------------------------------------
reg         trig0_req;
reg  [1:0]  trig0_req_type;
wire        trig0_ack;
wire [1:0]  trig0_ack_type;

reg         trig1_req;
reg  [1:0]  trig1_req_type;
wire        trig1_ack;
wire [1:0]  trig1_ack_type;

wire        trig0_out_req;
reg         trig0_out_ack;
wire        trig1_out_req;
reg         trig1_out_ack;

// -------------------------------------------------
// AXI read inputs (inputs → reg)
// -------------------------------------------------
reg         ARREADY;
reg         RID;
reg [127:0] RDATA_I;
reg [1:0]   RRESP;
reg         RLAST;
reg         RVALID;

reg         ARREADY_D;
reg         RID_D;
reg [127:0] RDATA_I_D;
reg [1:0]   RRESP_D;
reg         RLAST_D;
reg         RVALID_D;

// -------------------------------------------------
// AXI write inputs (inputs → reg)
// -------------------------------------------------
reg         WREADY;
reg         AWREADY;
reg         BVALID;
reg [1:0]   BRESP;

// -------------------------------------------------
// AXI outputs (outputs → wire)
// -------------------------------------------------
wire [3:0]  ARID;
wire [3:0]  ARLEN;
wire [2:0]  ARSIZE;
wire [1:0]  ARBURST;
wire        ARVALID;
wire [31:0] ARADDR;
wire        RREADY;

wire [3:0]  ARID_D;
wire [3:0]  ARLEN_D;
wire [2:0]  ARSIZE_D;
wire [1:0]  ARBURST_D;
wire        ARVALID_D;
wire [31:0] ARADDR_D;
wire        RREADY_D;

wire [3:0]  AWID_D;
wire [3:0]  AWLEN_D;
wire [2:0]  AWSIZE_D;
wire [1:0]  AWBURST_D;
wire        AWVALID_D;
wire [31:0] AWADDR_D;
wire        WVALID_D;
wire [127:0] WDATA_D;
wire        WLAST_D;
wire        BREADY_D;

// -------------------------------------------------
// Interrupt
// -------------------------------------------------
wire IRQ;


top_mod #(
    .WIDTH       (32),
    .DATA_W      (128),
    .DATA_WIDTH  (32),
    .ADDR_WIDTH  (32),
    .STRB_WIDTH  (32/8)
) u_top_mod (
    // clocks & resets
    .clk            (clk),
    .resetn         (resetn),
    .PCLK           (PCLK),
    .PRESETn        (PRESETn),

    // APB interface
    .PADDR          (PADDR),
    .PWRITE         (PWRITE),
    .PENABLE        (PENABLE),
    .PSEL           (PSEL),
    .PWDATA         (PWDATA),
    .PSTRB          (PSTRB),
    .PRDATA         (PRDATA),
    .PREADY         (PREADY),
    .PSLVERR        (PSLVERR),

    // trigger matrix
    .trig0_req          (trig0_req),
    .trig0_req_type     (trig0_req_type),
    .trig0_ack          (trig0_ack),
    .trig0_ack_type     (trig0_ack_type),

    .trig1_req          (trig1_req),
    .trig1_req_type     (trig1_req_type),
    .trig1_ack          (trig1_ack),
    .trig1_ack_type     (trig1_ack_type),

    .trig0_out_req      (trig0_out_req),
    .trig0_out_ack      (trig0_out_ack),
    .trig1_out_req      (trig1_out_req),
    .trig1_out_ack      (trig1_out_ack),

    // AXI read (main)
    .ARREADY        (ARREADY),
    .RID            (RID),
    .RDATA_I        (RDATA_I),
    .RRESP          (RRESP),
    .RLAST          (RLAST),
    .RVALID         (RVALID),

    // AXI read (D)
    .ARREADY_D      (ARREADY_D),
    .RID_D          (RID_D),
    .RDATA_I_D      (RDATA_I_D),
    .RRESP_D        (RRESP_D),
    .RLAST_D        (RLAST_D),
    .RVALID_D       (RVALID_D),

    // AXI write responses
    .WREADY         (WREADY),
    .AWREADY        (AWREADY),
    .BVALID         (BVALID),
    .BRESP          (BRESP),

    // AXI read address outputs
    .ARID           (ARID),
    .ARLEN          (ARLEN),
    .ARSIZE         (ARSIZE),
    .ARBURST        (ARBURST),
    .ARVALID        (ARVALID),
    .ARADDR         (ARADDR),
    .RREADY         (RREADY),

    // AXI read address outputs (D)
    .ARID_D         (ARID_D),
    .ARLEN_D        (ARLEN_D),
    .ARSIZE_D       (ARSIZE_D),
    .ARBURST_D      (ARBURST_D),
    .ARVALID_D      (ARVALID_D),
    .ARADDR_D       (ARADDR_D),
    .RREADY_D       (RREADY_D),

    // AXI write address/data (D)
    .AWID_D         (AWID_D),
    .AWLEN_D        (AWLEN_D),
    .AWSIZE_D       (AWSIZE_D),
    .AWBURST_D      (AWBURST_D),
    .AWVALID_D      (AWVALID_D),
    .AWADDR_D       (AWADDR_D),
    .WVALID_D       (WVALID_D),
    .WDATA_D        (WDATA_D),
    .WLAST_D        (WLAST_D),
    .BREADY_D       (BREADY_D),

    // interrupt
    .IRQ            (IRQ)
);


  // ------------- Clock -------------
  always #5 clk = ~clk;

  // ------------- Test --------------
  initial begin
    // Init
    clk        = 0;
    resetn     = 0;
    PRESETn    = 0;
    PADDR      = 0;
    PWRITE     = 0;
    PSEL       = 0;
    PENABLE    = 0;
    PWDATA     = 0;
    PSTRB      = 4'b0000;
    //ch_wr_en_i = 0;

    // Reset
    #20;
    PRESETn = 1;
    resetn     = 1;

    // -------- APB WRITE --------
    // link addr
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h78;
    PWDATA  = 32'h0000ABCF;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
#10;
    PENABLE = 1;
 #20;
    PENABLE = 0;
    
    // CH_TRIGOUT CFG
    #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h54;
    PWDATA  = 32'h0;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
        
      // CH_DESTRIGINCFG 
    #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h50;
    PWDATA  = 32'h0;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
    //CH_SRCTIRGINCFG
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h4C;
    PWDATA  = 32'h0;
    PSTRB   = 4'b1111;
    PENABLE = 0;
        #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
        
    //FILLVAL
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h38;
    PWDATA  = 32'h1234;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
        
       //XADDRINC 
     #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h30;
    PWDATA  = 32'h00010001;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;      
        
    //CH_DESTRANSCFG
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h2C;
    PWDATA  = 32'h0;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
     //CH_SRCTRANSCFG
        
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h28;
    PWDATA  = 32'h0;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
        
     //XSIZE   
      #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h20;
    PWDATA  = 32'h00040004;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;      
    //DESADDR    
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h18;
    PWDATA  = 32'h6084;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;    
        //SRCADDR
            #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h10;
    PWDATA  = 32'h1612;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
        
        //CH_CTRL
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h0C;
    PWDATA  = 32'h0E001200;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;    
        
    //CH_INTREN
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h08;
    PWDATA  = 32'h70F;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;  
        
        //CH_CMD
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h00;
    PWDATA  = 32'h01110001;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;  
        
                //CH_CMD
        #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h01;
    PWDATA  = 32'h01110000;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;  
        
        
 # 10;
 #10 ARREADY_D = 'b1;
#30 ARREADY_D = 'b0;

#10 
RRESP_D = 'b01;
RVALID_D = 'b1;
RDATA_I_D = 'hABC0;
#10
RDATA_I_D = 'hABC1;
#10
RDATA_I_D = 'hABC2;
#10
RDATA_I_D = 'hABC3;
RLAST_D = 'b1;
#10 RLAST_D = 'b0;
RVALID_D = 'b0;
#20;

AWREADY = 'b1;
#30 AWREADY = 'b0;

WREADY = 'b1;
#80;

BVALID = 1'b1;
BRESP = 'b00;
#20 BVALID = 'b0;

#20;

// comand descriptor1
  #10;
    ARREADY = 1'b1;
    #10 ARREADY = 1'b0;
     RRESP='b00;
    RID = 'b0;
     #10
    RVALID =1;
     RDATA_I = 'h40385D5D;
     RLAST = 1;
     #10 RVALID =0; RLAST=0;
   
    ARREADY = 1'b1;
    #30 ARREADY = 1'b0;
        RVALID =1;
       #10 RDATA_I = 32'h70F; #10//intren
        RDATA_I = 32'h0E001200;#10//ctrl
        RDATA_I = 32'h1234;#10//src addr
        RDATA_I = 32'h5687;#10//des addr
        RDATA_I=32'h00060006;#10//xsize
        RDATA_I=32'h0;#10//trans cfg
        RDATA_I=32'h0;#10//
        RDATA_I=32'h00010001;#10//xaddr inc
        RDATA_I=32'h1234;#10//fill val
        RDATA_I = 32'h00000201 ;#10//srctrig
        RDATA_I = 32'h00000200;#10//destrig
        RDATA_I = 32'h00000200;#10//trigout
        RDATA_I = 32'h0001ABCF; //link addr
        RLAST = 1;
        #10 RLAST= 0;
        RVALID=0;
     
          #30;
          
        trig0_req = 1;
        trig1_req = 1;
        #10;
     ARREADY_D = 1;
     #40
     ARREADY_D = 0;
     
     
     RVALID_D = 1;
     RRESP_D = 'b00;
  
     RDATA_I_D = 'hABC4;
    #10
    RDATA_I_D = 'hABC5;
    #10
    RDATA_I_D = 'hABC6;
    #10
    RDATA_I_D = 'hABC7;
    #10
    RDATA_I_D = 'hABC8;
    #10
    RDATA_I_D = 'hABC9;
    RLAST_D = 'b1;
    #10 RLAST_D = 'b0;
    RVALID_D = 'b0;
    #20;

    AWREADY = 'b1;
    #30 AWREADY = 'b0;
    
    WREADY = 'b1;
    #80;
    
    BVALID = 1'b1;
    BRESP = 'b00;
    #20 BVALID = 'b0;
    
    trig0_out_ack = 'b1;
    #20 trig0_out_ack = 'b0;


#20;

// comand descriptor1
  #10;
    ARREADY = 1'b1;
    #10 ARREADY = 1'b0;
     RRESP='b00;
    RID = 'b0;
     #10
    RVALID =1;
     RDATA_I = 'h40385D5D;
     RLAST = 1;
     #10 RVALID =0; RLAST=0;
   
    ARREADY = 1'b1;
    #30 ARREADY = 1'b0;
        RVALID =1;
       #10 RDATA_I = 32'h70F; #10//intren
        RDATA_I = 32'h0E001E00;#10//ctrl
        RDATA_I = 32'h1234;#10//src addr
        RDATA_I = 32'h5687;#10//des addr
        RDATA_I=32'h00060006;#10//xsize
        RDATA_I=32'h0;#10//trans cfg
        RDATA_I=32'h0;#10//
        RDATA_I=32'h00010001;#10//xaddr inc
        RDATA_I=32'h1234;#10//fill val
        RDATA_I = 32'h00000201 ;#10//srctrig
        RDATA_I = 32'h00000200;#10//destrig
        RDATA_I = 32'h00000200;#10//trigout
        RDATA_I = 32'h0001ABCF; //link addr
        RLAST = 1;
        #10 RLAST= 0;
        RVALID=0;
     
          #30;
          
        trig0_req = 1;
        trig1_req = 1;
        #10;
     ARREADY_D = 1;
     #40
     ARREADY_D = 0;
     
     
     RVALID_D = 1;
     RRESP_D = 'b00;
  
     RDATA_I_D = 'hABC4;
    #10
    RDATA_I_D = 'hABC5;
    #10
    RDATA_I_D = 'hABC6;
    #10
    RDATA_I_D = 'hABC7;
    #10
    RDATA_I_D = 'hABC8;
    #10
    RDATA_I_D = 'hABC9;
    RLAST_D = 'b1;
    #10 RLAST_D = 'b0;
    RVALID_D = 'b0;
    #20;

    AWREADY = 'b1;
    #30 AWREADY = 'b0;
    
    WREADY = 'b1;
    #80;
    
    BVALID = 1'b1;
    BRESP = 'b00;
    #20 BVALID = 'b0;
    
    trig0_out_ack = 'b1;
    #20 trig0_out_ack = 'b0;

       #10;
    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h04;
    PWDATA  = 32'h00020000;
    PSTRB   = 4'b1111;
    PENABLE = 0;
    
    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;  

        #500;
    $finish;
  end

endmodule
 

`timescale 1ns / 1ps

module apb_slave_error_tb ;

    parameter WIDTH = 32;
    parameter DATA_W = 128;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter STRB_WIDTH =  DATA_WIDTH/8;
    // clocks & resets (inputs → reg)
    reg clk;
    reg resetn;
    reg PCLK;
    reg PRESETn;
    
    // APB interface (inputs → reg)
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
    
    // trigger matrix (inputs → reg, outputs → wire)
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
    
    // AXI read inputs (inputs → reg)
    reg         ARREADY;
    reg         RID;
    reg [127:0] RDATA_I;
    reg [1:0]   RRESP;
    reg         RLAST;
    reg         RVALID;
    
    // AXI write inputs (inputs → reg)
    reg         WREADY;
    reg         AWREADY;
    reg         BVALID;
    reg [1:0]   BRESP;
    
    // AXI outputs (outputs → wire)
    wire [3:0]  ARID;
    wire [3:0]  ARLEN;
    wire [2:0]  ARSIZE;
    wire [1:0]  ARBURST;
    wire        ARVALID;
    wire [31:0] ARADDR;
    wire        RREADY;
    
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
    
    // Interrupt
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
        #10;
        PADDR   = 32'h78;
        PWRITE  = 1;
        PSEL    = 1;
        PWDATA  = 32'h0000ABC1;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        // CH_TRIGOUT CFG
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h54;
        PWDATA  = 32'h0000000;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        // CH_DESTRIGINCFG 
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h50;
        PWDATA  = 32'h0;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        //-------------pstrb error 
         //CH_SRCTIRGINCFG
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h4C;
        PWDATA  = 32'h0;
        PSTRB   = 4'b1110;
        PENABLE = 0;
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        
        //CH_SRCTIRGINCFG
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h4C;
        PWDATA  = 32'h0;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        //FILLVAL
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h38;
        PWDATA  = 32'h1234;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        //XADDRINC 
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h30;
        PWDATA  = 32'h00010001;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;      
        
        //CH_DESTRANSCFG
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h2C;
        PWDATA  = 32'h0;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        ///-- checking for pslave error for read only access type 
        //CH_ERRINFO
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h90;
        PWDATA  = 32'h1;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0; 
        
        
        //------ address out of range error 
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'd147;
        PWDATA  = 32'h80000000;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        
        //CH_SRCTRANSCFG
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h28;
        PWDATA  = 32'h00000000;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        //XSIZE   
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h20;
        PWDATA  = 32'h00050005;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;      
        
        //DESADDR    
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h18;
        PWDATA  = 32'h6084;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;    
        
        //SRCADDR
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h10;
        PWDATA  = 32'h1612;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;
        
        
        //CH_CTRL
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h0C;
        PWDATA  = 32'h0E001402;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;    
        
        //CH_INTREN
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h08;
        PWDATA  = 32'h70F;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;  
        
        
        //CH_CMD
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h00;
        PWDATA  = 32'h01110001;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0;  
        
        
        #100;
        ARREADY = 'b1;
        #30 ARREADY = 'b0;
        
        #10 
        RRESP = 'b01;
        RVALID = 'b1;
        RDATA_I = 'hABC0;
        #10
        RDATA_I = 'hABC1;
        #10
        RDATA_I = 'hABC2;
        #10
        RDATA_I = 'hABC3;
        #10
        RDATA_I = 'hABC4;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;
        
        AWREADY = 'b1;
        #30 AWREADY = 'b0;
        
        WREADY = 'b1;
        #100;
        WREADY = 'b0;
        BVALID = 1'b1;
        BRESP = 'b00;
        #20 BVALID = 'b0;   

        #500;
        $finish;
    end

endmodule
 

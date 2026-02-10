`timescale 1ns / 1ps

module pause_resume_cmd_tb ;

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
        PWDATA  = 32'h00050005;    // case 4
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
        
        # 100;
        
        
        // comand descriptor1
        
        #10;
        ARREADY = 1'b1;
        #20 ARREADY = 1'b0;
        
        
        #10
        RRESP='b00;
        RID = 'b0;
        RVALID =1;
        RDATA_I = 'h40385D5D;
        RLAST = 1;
        #10 RVALID =0; RLAST=0;
        #30;
        ARREADY = 1'b1;
        #30 ARREADY = 1'b0;
        RVALID =1;
        RDATA_I = 32'h70F; #10//intren
        RDATA_I = 32'h0E001600;#10//ctrl
        RDATA_I = 32'h1234;#10//src addr
        RDATA_I = 32'h5687;#10//des addr
        RDATA_I=32'h00070000;#10//xsize
        RDATA_I=32'h0;#10//trans cfg
        RDATA_I=32'h0;#10//
        RDATA_I=32'h00010001;#10//xaddr inc
        RDATA_I=32'h1234;#10//fill val
        RDATA_I = 32'h00000201 ;#10//srctrig
        RDATA_I = 32'h00000200;#10//destrig
        RDATA_I = 32'h00000200;#10//trigout
        RDATA_I = 32'h0001ABC1; //link addr
        RLAST = 1;
        #10 RLAST= 0;
        RVALID=0;
        
        #100;
        //#50;
        
        trig0_req = 1;
        trig1_req = 1;
        #10;
        trig0_req = 0;
        trig1_req = 0;
        ARREADY = 1;
        #30
        ARREADY = 0;
        
        
        RVALID = 1;
        RRESP = 'b00;
        
        RDATA_I = 'hABC4;
        #10
        RDATA_I = 'hABC5;
        #10
        RDATA_I = 'hABC6;
        #10
        RDATA_I = 'hABC7;
        #10
        RDATA_I = 'hABC8;
        #10
        RDATA_I = 'hABC9;
        #10
        RDATA_I = 'hABCa;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;
        #100;
        AWREADY = 'b1;
        #40 AWREADY = 'b0;
        
        WREADY = 'b1;
        #120;
        WREADY = 'b0;    
        BVALID = 1'b1;
        BRESP = 'b00;
        #20 BVALID = 'b0;
        
        trig0_out_ack = 'b1;
        #20 trig0_out_ack = 'b0;
        
        
        // comand descriptor2
        
        #30;
        ARREADY = 1'b1;
        #20 ARREADY = 1'b0;
        
        
        #10
        RRESP='b00;
        RID = 'b0;
        RVALID =1;
        RDATA_I = 'h40385D5D;
        RLAST = 1;
        #10 RVALID =0; RLAST=0;
        #30;
        ARREADY = 1'b1;
        #30 ARREADY = 1'b0;
        RVALID =1;
        RDATA_I = 32'h70F; #10//intren
        RDATA_I = 32'h0E001600;#10//ctrl
        RDATA_I = 32'h1234;#10//src addr
        RDATA_I = 32'h5687;#10//des addr
        RDATA_I=32'h00070007;#10//xsize
        RDATA_I=32'h0;#10//trans cfg
        RDATA_I=32'h0;#10//
        RDATA_I=32'h00010001;#10//xaddr inc
        RDATA_I=32'h1234;#10//fill val
        RDATA_I = 32'h00000201 ;#10//srctrig
        RDATA_I = 32'h00000200;#10//destrig
        RDATA_I = 32'h00000200;#10//trigout
        RDATA_I = 32'h0002ABC1; //link addr
        RLAST = 1;
        #10 RLAST= 0;
        RVALID=0;
        
        #100;
        
        //CH_CMD(pause_cmd)
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h00;
        PWDATA  = 32'h01110010;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0; 
        #90;
        
        #10  trig0_req = 1;
        trig1_req = 1;
        #10;
        trig0_req = 0;
        trig1_req = 0;
        #400
        
                //CH_CMD(resume_cmd)
        
        PSEL    = 1;
        PWRITE  = 1;
        PADDR   = 32'h00;
        PWDATA  = 32'h01110020;
        PSTRB   = 4'b1111;
        PENABLE = 0;
        #10;
        PENABLE = 1;
        #10;
        PENABLE = 0; 
        #90;
        #10  trig0_req = 1;
        trig1_req = 1;
        #10;
        trig0_req = 0;
        trig1_req = 0;
        ARREADY = 1;
        #30
        ARREADY = 0;
        
        
        RVALID = 1;
        RRESP = 'b00;

        
        RDATA_I = 'hABC4;
        #10
        RDATA_I = 'hABC5;
        #10
        RDATA_I = 'hABC6;
        #10
        RDATA_I = 'hABC7;
        #10
        RDATA_I = 'hABC8;
        #10
        RDATA_I = 'hABC9;
        #10
        RDATA_I = 'hABCa;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;
        #160;
        
        AWREADY = 'b1;
        #40 AWREADY = 'b0;
        
        WREADY = 'b1;
        #120;
        WREADY = 'b0;   
        BVALID = 1'b1;
        BRESP = 'b00;
        #20 BVALID = 'b0;
        
        trig0_out_ack = 'b1;
        #20 trig0_out_ack = 'b0;
        
        
        
        // comand descriptor3
        
        #10;
        ARREADY = 1'b1;
        #20 ARREADY = 1'b0;
        
        
        #10
        RRESP='b00;
        RID = 'b0;
        RVALID =1;
        RDATA_I = 'h40385D5D;
        RLAST = 1;
        #10 RVALID =0; RLAST=0;
        #30;
        ARREADY = 1'b1;
        #30 ARREADY = 1'b0;
        RVALID =1;
        RDATA_I = 32'h70F; #10//intren
        RDATA_I = 32'h0E001600;#10//ctrl
        RDATA_I = 32'h1234;#10//src addr
        RDATA_I = 32'h5687;#10//des addr
        RDATA_I=32'h00070007;#10//xsize
        RDATA_I=32'h0;#10//trans cfg
        RDATA_I=32'h0;#10//
        RDATA_I=32'h00010001;#10//xaddr inc
        RDATA_I=32'h1234;#10//fill val
        RDATA_I = 32'h00000201 ;#10//srctrig
        RDATA_I = 32'h00000200;#10//destrig
        RDATA_I = 32'h00000200;#10//trigout
        RDATA_I = 32'h0001ABC1; //link addr
        RLAST = 1;
        #10 RLAST= 0;
        RVALID=0;
        
        #100;
        
        trig0_req = 1;
        trig1_req = 1;
        #10;
        trig0_req = 0;
        trig1_req = 0;
        ARREADY = 1;
        #30
        ARREADY = 0;
        
        
        RVALID = 1;
        RRESP = 'b00;
        
        RDATA_I = 'h1114;
        #10
        RDATA_I = 'h2225;
        #10
        RDATA_I = 'h3336;
        #10
        RDATA_I = 'h4447;
        #10
        RDATA_I = 'h5558;
        #10
        RDATA_I = 'h6669;
        #10
        RDATA_I = 'h777a;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;
        #100;
        AWREADY = 'b1;
        #40 AWREADY = 'b0;
        
        WREADY = 'b1;
        #120;
        WREADY = 'b0;    
        BVALID = 1'b1;
        BRESP = 'b00;
        #20 BVALID = 'b0;
        
        trig0_out_ack = 'b1;
        #20 trig0_out_ack = 'b0;
        
        
        
        #500;
        $finish;
  end

endmodule
 
        


module dma_2d_src_equal_des;

parameter WIDTH       = 32;
parameter DATA_W      = 32;
parameter DATA_WIDTH  = 32;
parameter ADDR_WIDTH  = 32;
parameter STRB_WIDTH  = DATA_WIDTH/8;
parameter ID_W        = 4;
parameter DEPTH       = 145;
parameter ADDR_W      = 32;

// -------------------------------------------------
// REG DECLARATIONS (Inputs to DUT)
// -------------------------------------------------

reg clk;
reg resetn;

reg  [ADDR_WIDTH-1:0] PADDR;
reg                   PWRITE;
reg                   PENABLE;
reg                   PSEL;

reg                   boot_en;
reg  [29:0]           boot_addr;

reg  [DATA_WIDTH-1:0] PWDATA;
reg  [STRB_WIDTH-1:0] PSTRB;

// Trigger interface
reg                   trig0_req;
reg  [1:0]            trig0_req_type;

reg                   trig1_req;
reg  [1:0]            trig1_req_type;

reg                   trig0_out_ack;
reg                   trig1_out_ack;

// AXI interface
reg                   ARREADY;
reg  [ID_W-1:0]       RID;
reg  [DATA_W-1:0]     RDATA_I;
reg  [1:0]            RRESP;
reg                   RLAST;
reg                   RVALID;

reg                   WREADY;
reg                   AWREADY;

reg  [ID_W-1:0]       BID;
reg                   BVALID;
reg  [1:0]            BRESP;


// -------------------------------------------------
// WIRE DECLARATIONS (Outputs from DUT)
// -------------------------------------------------

wire [DATA_WIDTH-1:0] PRDATA;
wire                  PREADY;
wire                  PSLVERR;

wire                  trig0_ack;
wire [1:0]            trig0_ack_type;

wire                  trig1_ack;
wire [1:0]            trig1_ack_type;

wire                  trig0_out_req;
wire                  trig1_out_req;

wire [3:0]            ARQOS;
wire [3:0]            AWQOS;

wire [ID_W-1:0]       ARID;
wire [7:0]            ARLEN;
wire [2:0]            ARSIZE;
wire [1:0]            ARBURST;
wire                  ARVALID;
wire [ADDR_W-1:0]     ARADDR;
wire                  RREADY;

wire [(DATA_W/8)-1:0] WSTRB;

wire [ID_W-1:0]       AWID_D;
wire [7:0]            AWLEN_D;
wire [2:0]            AWSIZE_D;
wire [1:0]            AWBURST_D;
wire                  AWVALID_D;
wire [ADDR_W-1:0]     AWADDR_D;

wire                  WVALID_D;
wire [DATA_W-1:0]     WDATA_D;
wire                  WLAST_D;

wire                  BREADY_D;

wire                  IRQ;


// -------------------------------------------------
// DUT INSTANTIATION
// -------------------------------------------------

top_mod #(
    .WIDTH(WIDTH),
    .DATA_W(DATA_W),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .ID_W(ID_W),
    .DEPTH(DEPTH),
    .ADDR_W(ADDR_W)
) dut (

    .clk(clk),
    .resetn(resetn),

    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL),

    .boot_en(boot_en),
    .boot_addr(boot_addr),

    .PWDATA(PWDATA),
    .PSTRB(PSTRB),

    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),

    .trig0_req(trig0_req),
    .trig0_req_type(trig0_req_type),
    .trig0_ack(trig0_ack),
    .trig0_ack_type(trig0_ack_type),

    .trig1_req(trig1_req),
    .trig1_req_type(trig1_req_type),
    .trig1_ack(trig1_ack),
    .trig1_ack_type(trig1_ack_type),

    .trig0_out_req(trig0_out_req),
    .trig0_out_ack(trig0_out_ack),

    .trig1_out_req(trig1_out_req),
    .trig1_out_ack(trig1_out_ack),

    .ARREADY(ARREADY),
    .RID(RID),
    .RDATA_I(RDATA_I),
    .RRESP(RRESP),
    .RLAST(RLAST),
    .RVALID(RVALID),

    .WREADY(WREADY),
    .AWREADY(AWREADY),

    .BID(BID),
    .BVALID(BVALID),
    .BRESP(BRESP),

    .ARQOS(ARQOS),
    .AWQOS(AWQOS),

    .ARID(ARID),
    .ARLEN(ARLEN),
    .ARSIZE(ARSIZE),
    .ARBURST(ARBURST),
    .ARVALID(ARVALID),
    .ARADDR(ARADDR),
    .RREADY(RREADY),

    .WSTRB(WSTRB),

    .AWID_D(AWID_D),
    .AWLEN_D(AWLEN_D),
    .AWSIZE_D(AWSIZE_D),
    .AWBURST_D(AWBURST_D),
    .AWVALID_D(AWVALID_D),
    .AWADDR_D(AWADDR_D),

    .WVALID_D(WVALID_D),
    .WDATA_D(WDATA_D),
    .WLAST_D(WLAST_D),

    .BREADY_D(BREADY_D),

    .IRQ(IRQ)
);


// -------------------------------------------------
// CLOCK GENERATION
// -------------------------------------------------

always #5 clk = ~clk;


// -------------------------------------------------
// INITIAL BLOCK
// -------------------------------------------------

initial begin

    clk             = 0;
    resetn          = 0;

    PADDR           = 0;
    PWRITE          = 0;
    PENABLE         = 0;
    PSEL            = 0;

    boot_en         = 0;
    boot_addr       = 0;

    PWDATA          = 0;
    PSTRB           = 0;

    trig0_req       = 0;
    trig0_req_type  = 0;

    trig1_req       = 0;
    trig1_req_type  = 0;

    trig0_out_ack   = 0;
    trig1_out_ack   = 0;

    ARREADY         = 0;
    RID             = 0;
    RDATA_I         = 0;
    RRESP           = 0;
    RLAST           = 0;
    RVALID          = 0;

    WREADY          = 0;
    AWREADY         = 0;

    BID             = 0;
    BVALID          = 0;
    BRESP           = 0;

    #20;
    resetn = 1;

     // -------- APB WRITE --------
    // link addr
    #10;
    PADDR   = 32'h1078;
    PWRITE  = 1;
    PSEL    = 1;
    PWDATA  = 32'h0000ABC1;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
    //autocfg
        PADDR   = 32'h1074;
    PWRITE  = 1;
    PSEL    = 1;
    PWDATA  = 32'h00000000;
    PSTRB   = 4'b1111;
    PENABLE = 0;

#10;
    PENABLE = 1;
#20;
    PENABLE = 0;
    // CH_TRIGOUT CFG

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1054;
    PWDATA  = 32'h0000000;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;

      // CH_DESTRIGINCFG 

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1050;
    PWDATA  = 32'h00050000;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
    //CH_SRCTIRGINCFG

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h104C;
    PWDATA  = 32'h00050000;
    PSTRB   = 4'b1111;
    PENABLE = 0;
        #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;

    //CH_DESTMPLT
     PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1048;
    PWDATA  = 32'h00000000;
    PSTRB   = 4'b1111;
    PENABLE = 0;
        #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
    //CH_SRCTMPLT
     PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1044;
    PWDATA  = 32'h00000000;
    PSTRB   = 4'b1111;
    PENABLE = 0;
        #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
    //CH_TMPLTCFG
     PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1040;
    PWDATA  = 32'h00000000;
    PSTRB   = 4'b1111;
    PENABLE = 0;
        #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
    //CH_YSIZE
     PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h103C;
    PWDATA  = 32'h00050005;
    PSTRB   = 4'b1111;
    PENABLE = 0;
        #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;



    //FILLVAL

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1038;
    PWDATA  = 32'h1234;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;
    //CH_YADDRSTRIDE

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1034;
    PWDATA  = 32'h10;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;

       //XADDRINC 

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1030;
    PWDATA  = 32'h00010001;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;      

    //CH_DESTRANSCFG

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h102C;
    PWDATA  = 32'h00030000;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;

//       

          //CH_SRCTRANSCFG

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1028;
    PWDATA  = 32'h00030000;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;

     //XSIZE   

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1020;
    PWDATA  = 32'h00050005;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;      
    //DESADDR    

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1018;
    PWDATA  = 32'h0F;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;    

        //SRCADDR

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1010;
    PWDATA  = 32'h0A;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;


        //CH_CTRL

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h100C;
    PWDATA  = 32'h0E002202;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;    

    //CH_INTREN

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1008;
    PWDATA  = 32'h70F;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;  


        //CH_CMD

    PSEL    = 1;
    PWRITE  = 1;
    PADDR   = 32'h1000;
    PWDATA  = 32'h01550001;
    PSTRB   = 4'b1111;
    PENABLE = 0;

    #10;
        PENABLE = 1;
     #20;
        PENABLE = 0;  

        #100;
        AWREADY = 'b1;


        WREADY = 'b1;

        //WREADY = 'b0;
        BVALID = 1'b1;
        BRESP = 'b00;
        //1
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
        RLAST = 'b1;
        #10 RLAST = 'b0;RVALID = 'b0;

        ARREADY = 'b1;
        #30 ARREADY = 'b0;
        RVALID = 'b1;
        RDATA_I = 'hABC4;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;

         //2
        ARREADY = 'b1;
        #30 ARREADY = 'b0;

        #10 
        RRESP = 'b01;
        RVALID = 'b1;
        RDATA_I = 'hABC5;
        #10
        RDATA_I = 'hABC6;
        #10
        RDATA_I = 'hABC7;
        #10
        RDATA_I = 'hABC8;
        RLAST = 'b1;
        #10 RLAST = 'b0;RVALID = 'b0;

        ARREADY = 'b1;
        #30 ARREADY = 'b0;
        RVALID = 'b1;
        RDATA_I = 'hABC9;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;

         //3
        ARREADY = 'b1;
        #30 ARREADY = 'b0;

        #10 
        RRESP = 'b01;
        RVALID = 'b1;
        RDATA_I = 'hABCa;
        #10
        RDATA_I = 'hABCb;
        #10
        RDATA_I = 'hABCc;
        #10
        RDATA_I = 'hABCd;
        RLAST = 'b1;
        #10 RLAST = 'b0;RVALID = 'b0;

        ARREADY = 'b1;
        #30 ARREADY = 'b0;
        RVALID = 'b1;
        RDATA_I = 'hABCe;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;

         //4
        ARREADY = 'b1;
        #30 ARREADY = 'b0;

        #10 
        RRESP = 'b01;
        RVALID = 'b1;
        RDATA_I = 'hABCf;
        #10
        RDATA_I = 'hABC10;
        #10
        RDATA_I = 'hABC11;
        #10
        RDATA_I = 'hABC12;
        RLAST = 'b1;
        #10 RLAST = 'b0;RVALID = 'b0;

        ARREADY = 'b1;
        #30 ARREADY = 'b0;
        RVALID = 'b1;
        RDATA_I = 'hABC13;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;

         //5
        ARREADY = 'b1;
        #30 ARREADY = 'b0;

        #10 
        RRESP = 'b01;
        RVALID = 'b1;
        RDATA_I = 'hABC14;
        #10
        RDATA_I = 'hABC15;
        #10
        RDATA_I = 'hABC16;
        #10
        RDATA_I = 'hABC17;
        RLAST = 'b1;
        #10 RLAST = 'b0;RVALID = 'b0;

        ARREADY = 'b1;
        #30 ARREADY = 'b0;
        RVALID = 'b1;
        RDATA_I = 'hABC18;
        RLAST = 'b1;
        #10 RLAST = 'b0;
        RVALID = 'b0;
        #20;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     
//    // comand descriptor1

  #230;
    ARREADY = 1'b1;
    #20 ARREADY = 1'b0;
          

     #10
          RRESP='b00;
    RID = 'b0;
    RVALID =1;
     RDATA_I = 'b0100_0000_0011_1111_1111_1101_0101_1101;
     RLAST = 1;
     #10 RVALID =0; RLAST=0;
     #30;
    ARREADY = 1'b1;
    #30 ARREADY = 1'b0;
        RVALID =1;
        RDATA_I = 32'h70F; #10//intren
        RDATA_I = 32'h0E001200;#10//ctrl
        RDATA_I = 32'h1234;#10//src addr
        RDATA_I = 32'h5687;#10//des addr
        RDATA_I=32'h00050005;#10//xsize
        RDATA_I=32'h00050000;#10//trans cfg
        RDATA_I=32'h00050000;#10//
        RDATA_I=32'h00010001;#10//xaddr inc
        RDATA_I=32'h000a000a;#10//yaddrstride
        RDATA_I=32'h1234;#10//fill val
        RDATA_I=32'h00030005;#10//ysize
        RDATA_I=32'h00000000;#10//tmpltcfg
        RDATA_I=32'h00000000;#10//srctmplt
        RDATA_I=32'h00000000;#10//destmplt
        RDATA_I = 32'h00000201 ;#10//srctrig
        RDATA_I = 32'h00000200;//destrig
         RLAST = 1;
        #10 RLAST= 0;
         RVALID =0;
         ARREADY = 1'b1;
        #30 ARREADY = 1'b0;
        RVALID = 1;
        RDATA_I = 32'h00000200;#10//trigout
        RDATA_I = 32'h0001ABC1; //link addr
        RLAST = 1;
        #10 RLAST= 0;
        RVALID=0;
     
    trig0_req       = 1;
    trig0_req_type  = 2;

    trig1_req       = 1;
    trig1_req_type  = 2;
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
  
     RDATA_I = 'hDEF0;
    #10
    RDATA_I = 'hDEF1;
    #10
    RDATA_I = 'hDEF2;
    #10
    RDATA_I = 'hDEF3;
    #10
    RDATA_I = 'hDEF4;
  
//    RDATA_I = 'hABC9;
//     #10
//    RDATA_I = 'hABCa;
    RLAST = 'b1;
    #10 RLAST = 'b0;
    RVALID = 'b0;
    #20;
    
     ARREADY = 1;
     #40
     ARREADY = 0;
     
     
     RVALID = 1;
     RRESP = 'b00;
  
     RDATA_I = 'hDEF0;
    #10
    RDATA_I = 'hDEF1;
    #10
    RDATA_I = 'hDEF2;
    #10
    RDATA_I = 'hDEF3;
    #10
    RDATA_I = 'hDEF4;
  
//    RDATA_I = 'hABC9;
//     #10
//    RDATA_I = 'hABCa;
    RLAST = 'b1;
    #10 RLAST = 'b0;
    
    RVALID = 'b0;
    
     ARREADY = 1;
     #40
     ARREADY = 0;
     
     
     RVALID = 1;
     RRESP = 'b00;
  
     RDATA_I = 'hDEF0;
    #10
    RDATA_I = 'hDEF1;
    #10
    RDATA_I = 'hDEF2;
    #10
    RDATA_I = 'hDEF3;
    #10
    RDATA_I = 'hDEF4;
  
//    RDATA_I = 'hABC9;
//     #10
//    RDATA_I = 'hABCa;
    RLAST = 'b1;
    #10 RLAST = 'b0;
    RVALID = 'b0;
    
    
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

  #230;
    ARREADY = 1'b1;
    #20 ARREADY = 1'b0;
          

     #10
          RRESP='b00;
    RID = 'b0;
    RVALID =1;
     RDATA_I = 'b0100_0000_0011_1111_1111_1101_0101_1101;
     RLAST = 1;
     #10 RVALID =0; RLAST=0;
     #30;
    ARREADY = 1'b1;
    #30 ARREADY = 1'b0;
        RVALID =1;
        RDATA_I = 32'h70E; #10//intren
        RDATA_I = 32'h0E001601;#10//ctrl
        RDATA_I = 32'h124;#10//src addr
        RDATA_I = 32'h567;#10//des addr
        RDATA_I=32'h00040004;#10//xsize
        RDATA_I=32'h00040000;#10//trans cfg
        RDATA_I=32'h00040000;#10//
        RDATA_I=32'h00010001;#10//xaddr inc
        RDATA_I=32'h00020002;#10//yaddrstride
        RDATA_I=32'h1;#10//fill val
        RDATA_I=32'h00020005;#10//ysize
        RDATA_I=32'h00000000;#10//tmpltcfg
        RDATA_I=32'h00000000;#10//srctmplt
        RDATA_I=32'h00000000;#10//destmplt
        RDATA_I = 32'h00000200 ;#10//srctrig
        RDATA_I = 32'h00000201;//destrig
         RLAST = 1;
        #10 RLAST= 0;
         RVALID =0;
         ARREADY = 1'b1;
        #30 ARREADY = 1'b0;
        RVALID = 1;
        RDATA_I = 32'h00000200;#10//trigout
        RDATA_I = 32'h0001ABA1; //link addr
        RLAST = 1;
        #10 RLAST= 0;
        RVALID=0;
     
    trig0_req       = 1;
    trig0_req_type  = 2;

    trig1_req       = 1;
    trig1_req_type  = 2;
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
  
     RDATA_I = 'haEF0;
    #10
    RDATA_I = 'haEF1;
    #10
    RDATA_I = 'haEF2;
    #10
    RDATA_I = 'haEF3;
    
  
//    RDATA_I = 'hABC9;
//     #10
//    RDATA_I = 'hABCa;
    RLAST = 'b1;
    #10 RLAST = 'b0;
    RVALID = 'b0;
    #20;
    
     ARREADY = 1;
     #40
     ARREADY = 0;
     
     
     RVALID = 1;
     RRESP = 'b00;
  
     RDATA_I = 'haEF0;
    #10
    RDATA_I = 'haEF1;
    #10
    RDATA_I = 'haEF2;
    #10
    RDATA_I = 'haEF3;
    
  
//    RDATA_I = 'hABC9;
//     #10
//    RDATA_I = 'hABCa;
  //  RLAST = 'b1;
    #10 RLAST = 'b0;
    
    RVALID = 'b0;
    

    
    
 #100;
    AWREADY = 'b1;
    #40;
    // AWREADY = 'b0;
    
    WREADY = 'b1;
    #120;
  // WREADY = 'b0;    
    BVALID = 1'b1;
    BRESP = 'b00;
    #20 
    //BVALID = 'b0;
    
    trig0_out_ack = 'b1;
    #20 
    //trig0_out_ack = 'b0;



    #1000;

    $finish;

end

endmodule

 

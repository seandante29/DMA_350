
module top_mod_multi_tb;

parameter WIDTH       = 32;
parameter DATA_W      = 128;
parameter DATA_WIDTH  = 32;
parameter ADDR_WIDTH  = 32;
parameter STRB_WIDTH  = DATA_WIDTH/8;
parameter ID_W        = 4;
parameter DEPTH       = 145;
parameter ADDR_W      = 32;
parameter NUM_CH      = 3;

// ======================================================
// CLOCK / RESET
// ======================================================

reg clk;
reg resetn;



// ======================================================
// APB INTERFACE
// ======================================================

reg  [ADDR_WIDTH-1:0] PADDR;
reg                   PWRITE;
reg                   PENABLE;
reg                   PSEL;
reg  [DATA_WIDTH-1:0] PWDATA;
reg  [STRB_WIDTH-1:0] PSTRB;

wire [DATA_WIDTH-1:0] PRDATA;
wire                  PREADY;
wire                  PSLVERR;

// ======================================================
// BOOT
// ======================================================

reg boot_en;
reg [29:0] boot_addr;

// ======================================================
// AXI READ CHANNEL
// ======================================================

reg                  ARREADY;
wire [ID_W-1:0]      ARID;
wire [7:0]           ARLEN;
wire [2:0]           ARSIZE;
wire [1:0]           ARBURST;
wire                 ARVALID;
wire [ADDR_W-1:0]    ARADDR;
wire [3:0]           ARQOS;

reg  [ID_W-1:0]      RID;
reg  [DATA_W-1:0]    RDATA_I;
reg  [1:0]           RRESP;
reg                  RLAST;
reg                  RVALID;
wire                 RREADY;

// ======================================================
// AXI WRITE CHANNEL
// ======================================================

reg                  AWREADY;
wire [3:0]           AWQOS;
wire [ID_W-1:0]      AWID_D;
wire [7:0]           AWLEN_D;
wire [2:0]           AWSIZE_D;
wire [1:0]           AWBURST_D;
wire                 AWVALID_D;
wire [ADDR_W-1:0]    AWADDR_D;

reg                  WREADY;
wire [(DATA_W/8)-1:0]WSTRB;
wire                 WVALID_D;
wire [DATA_W-1:0]    WDATA_D;
wire                 WLAST_D;

reg  [ID_W-1:0]      BID;
reg                  BVALID;
reg  [1:0]           BRESP;
wire                 BREADY_D;

// ======================================================
// TRIGGER SIGNALS
// ======================================================

reg  [5:0] trig_req;
reg  [11:0] trig_req_type;

wire [5:0] trig_ack;
wire [11:0] trig_ack_type;

wire  [5:0] trig_out_req;
reg [5:0] trig_out_ack;

// ======================================================
// IRQ
// ======================================================

wire IRQ;

// ======================================================
// DUT
// ======================================================

top_mod_multi #(
    .WIDTH(WIDTH),
    .DATA_W(DATA_W),
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .STRB_WIDTH(STRB_WIDTH),
    .ID_W(ID_W),
    .DEPTH(DEPTH),
    .ADDR_W(ADDR_W),
    .NUM_CH(NUM_CH)
) dut (

    .clk(clk),
    .resetn(resetn),

    .boot_en(boot_en),
    .boot_addr(boot_addr),

    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PSEL(PSEL),
    .PWDATA(PWDATA),
    .PSTRB(PSTRB),

    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR),

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

    .IRQ(IRQ),

    .trig_req(trig_req),
    .trig_req_type(trig_req_type),
    .trig_ack(trig_ack),
    .trig_ack_type(trig_ack_type),

    .trig_out_req(trig_out_req),
    .trig_out_ack(trig_out_ack)
);

// ----------------------
// Clock Generation
// ----------------------
always #5 clk = ~clk;

// ----------------------
// APB Write Task
// ----------------------
task apb_write(input [31:0] addr, input [31:0] data);
begin
    // SETUP phase
    @(posedge clk);
    PADDR   <= addr;
    PWDATA  <= data;
    PWRITE  <= 1;
    PSEL    <= 1;
    PENABLE <= 0;

    // ENABLE phase
    @(posedge clk);
    PENABLE <= 1;

    // WAIT for PREADY (important!)
    @(posedge clk);
    while (!PREADY) begin
        @(posedge clk);
    end

    // COMPLETE
    @(posedge clk);
    PSEL    <= 0;
    PENABLE <= 0;
    //PWRITE  <= 0;
end
endtask

// ----------------------
// APB Read Task
// ----------------------
task apb_read(input [31:0] addr);
begin
    @(posedge clk);
    PADDR   <= addr;
    PWRITE  <= 0;
    PSEL    <= 1;
    PENABLE <= 0;

    @(posedge clk);
    PENABLE <= 1;

    @(posedge clk);
    PSEL    <= 0;
    PENABLE <= 0;
end
endtask

// ----------------------
// Test Sequence
// ----------------------
initial begin
    // Init
    clk = 0;
    resetn = 0;

    PADDR = 0;
    PWRITE = 0;
    PENABLE = 0;
    PSEL = 0;
    PWDATA = 0;
    PSTRB = 4'hF;
    boot_addr = 0;
    boot_en = 0;

    // Reset release
    #20;
    resetn = 1;

    // ----------------------
    // Write transactions
    // ----------------------
    #10;//CH0
    apb_write(32'h1078, 32'hABC1);//LINK ADDR
   #20 apb_write(32'h1074, 32'h1);//AUTO CFG
   #20 apb_write(32'h1054, 32'h2);//TRIGOUT CFG
   #20 apb_write(32'h1050, 32'h00050000);//SRCTRIGIN
    apb_write(32'h104C, 32'h00050000);//DESTRIGIN
    apb_write(32'h1048, 32'h01101);//DESTMPLT
    apb_write(32'h1044, 32'h01101);//SRCTMPLt
    apb_write(32'h1040, 32'h00090000);//TMPLTCFG
    apb_write(32'h103C, 32'h00050005);//YSIZE
    apb_write(32'h1038, 32'h1234);//FILL VAL
    apb_write(32'h1034, 32'h000a000a);//YADDRSTRIDE
    apb_write(32'h1030, 32'h00010001);//XADDRINC
    apb_write(32'h102C, 32'h00030000);//DESTRANSCFG
    apb_write(32'h1028, 32'h00030000);//SRCTRANSCFG
    apb_write(32'h1020, 32'h00080008);//XSIZE
    apb_write(32'h1018, 32'h0F);//DESADDR
    apb_write(32'h1010, 32'h0A);//SRCADDR
    apb_write(32'h100C, 32'h0E043400);//CTRL
    apb_write(32'h1008, 32'h70F);//INTERN
    apb_write(32'h1000, 32'h01550001);//CMD
    
     #100;//CH1
    apb_write(32'h1178, 32'hABC1);//LINK ADDR
    apb_write(32'h1174, 32'h1);//AUTO CFG
    apb_write(32'h1154, 32'h2);//TRIGOUT CFG
    apb_write(32'h1150, 32'h00050000);//SRCTRIGIN
    apb_write(32'h114C, 32'h00050000);//DESTRIGIN
    apb_write(32'h1148, 32'h01101);//DESTMPLT
    apb_write(32'h1144, 32'h01101);//SRCTMPLt
    apb_write(32'h1140, 32'h00090000);//TMPLTCFG
    apb_write(32'h113C, 32'h00050005);//YSIZE
    apb_write(32'h1138, 32'h1234);//FILL VAL
    apb_write(32'h1134, 32'h000a000a);//YADDRSTRIDE
    apb_write(32'h1130, 32'h00010001);//XADDRINC
    apb_write(32'h112C, 32'h00030000);//DESTRANSCFG
    apb_write(32'h1128, 32'h00030000);//SRCTRANSCFG
    apb_write(32'h1120, 32'h00080008);//XSIZE
    apb_write(32'h1118, 32'h0F);//DESADDR
    apb_write(32'h1110, 32'h0A);//SRCADDR
    apb_write(32'h110C, 32'h0E043400);//CTRL
    apb_write(32'h1108, 32'h70F);//INTERN
    apb_write(32'h1100, 32'h01550001);//CMD
    
     #100;//CH2
    apb_write(32'h1278, 32'hABC1);//LINK ADDR
    apb_write(32'h1274, 32'h1);//AUTO CFG
    apb_write(32'h1254, 32'h2);//TRIGOUT CFG
    apb_write(32'h1250, 32'h00050000);//SRCTRIGIN
    apb_write(32'h124C, 32'h00050000);//DESTRIGIN
    apb_write(32'h1248, 32'h01101);//DESTMPLT
    apb_write(32'h1244, 32'h01101);//SRCTMPLt
    apb_write(32'h1240, 32'h00090000);//TMPLTCFG
    apb_write(32'h123C, 32'h00050005);//YSIZE
    apb_write(32'h1238, 32'h1234);//FILL VAL
    apb_write(32'h1234, 32'h000a000a);//YADDRSTRIDE
    apb_write(32'h1230, 32'h00010001);//XADDRINC
    apb_write(32'h122C, 32'h00030000);//DESTRANSCFG
    apb_write(32'h1228, 32'h00030000);//SRCTRANSCFG
    apb_write(32'h1220, 32'h00080008);//XSIZE
    apb_write(32'h1218, 32'h0F);//DESADDR
    apb_write(32'h1210, 32'h0A);//SRCADDR
    apb_write(32'h120C, 32'h0E043400);//CTRL
    apb_write(32'h1208, 32'h70F);//INTERN
    apb_write(32'h1200, 32'h01550001);//CMD
   
    #500;
    $finish;
        end

    endmodule 

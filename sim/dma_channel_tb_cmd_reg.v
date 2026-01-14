module dma_channel_tb(   );
parameter WIDTH = 32;
parameter DATA_W = 128;

     reg clk,resetn;                 
     reg [(WIDTH * 15) -1:0] reg_chn_in;


     reg ARREADY;
     reg RID;
     reg [31:0]RDATA_I;
     reg [1:0]RRESP;
     reg RLAST;
     reg RVALID;
     
     reg ARREADY_D;
     reg RID_D;
     reg [31:0]RDATA_I_D;
     reg [1:0]RRESP_D;
     reg RLAST_D;
     reg RVALID_D;
  //   reg data_done;
  //   reg linkaddren;
     reg WREADY;
     reg AWREADY;
     reg BVALID;
     reg [1:0] BRESP;
     
     reg SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR;
     reg src_trig_req;
     reg [1:0]  src_trig_req_type;
    
    reg         des_trig_req;
    reg  [1:0]  des_trig_req_type;
        
    reg ch_trigout_ack;
    
    wire        ch_src_ack;
    wire [1:0]  ch_src_ack_type;
    wire        ch_des_ack;
    wire [1:0]  ch_des_ack_type;
    wire        ch_trigout_req;
    
       wire [(WIDTH*2)-1 : 0] chn_reg_out;                       
       wire IRQ;
       wire [3:0] ARID;
       wire [3:0] ARLEN;
       wire[2:0] ARSIZE;
       wire [1:0] ARBURST;
       wire ARVALID;
       wire [31:0]ARADDR;
       wire RREADY;
       
        
      wire [3:0] ARID_D;
      wire [3:0] ARLEN_D;
      wire[2:0] ARSIZE_D;
      wire [1:0] ARBURST_D;
      wire ARVALID_D;
      wire [31:0]ARADDR_D;
      wire RREADY_D ;
      
      wire [3:0] AWID_D;
      wire [3:0] AWLEN_D;
      wire[2:0] AWSIZE_D;
      wire [1:0] AWBURST_D;
      wire AWVALID_D;
      wire [31:0]AWADDR_D;
      wire WVALID_D;
      wire [DATA_W -1 :0] WDATA_D;
      wire WLAST_D;
      wire BREADY_D;

    wire [1:0]  src_trigin_type;
    wire [7:0]  src_trigin_sel;
    wire [1:0]  des_trigin_type;
    wire [7:0]  des_trigin_sel;
    wire [1:0]  trigout_type;
    wire [5:0]  trigout_sel;
    wire        use_trigout;
    wire        use_des_trigin;
    wire        use_src_trigin;
        
        
dma_channel #(
    .WIDTH(WIDTH),
    .DATA_W(DATA_W)
) dut (
    // Clock and Reset
    .clk                (clk),
    .resetn             (resetn),

    // Configuration Interface
    .reg_chn_in         (reg_chn_in),
    .chn_reg_out        (chn_reg_out),
    .IRQ                (IRQ),

    // AXI Read Address/Data (General/Descriptor)
    .ARID               (ARID),
    .ARADDR             (ARADDR),
    .ARLEN              (ARLEN),
    .ARSIZE             (ARSIZE),
    .ARBURST            (ARBURST),
    .ARVALID            (ARVALID),
    .ARREADY            (ARREADY),
    
    .RID                (RID),
    .RDATA_I            (RDATA_I),
    .RRESP              (RRESP),
    .RLAST              (RLAST),
    .RVALID             (RVALID),
    .RREADY             (RREADY),

    .RID_D                (RID_D),
    .RDATA_I_D            (RDATA_I_D),
    .RRESP_D              (RRESP_D),
    .RLAST_D              (RLAST_D),
    .RVALID_D             (RVALID_D),
    .ARREADY_D             (ARREADY_D),

    // AXI Read Master (Data Specific - _D)
    .ARID_D             (ARID_D),
    .ARADDR_D           (ARADDR_D),
    .ARLEN_D            (ARLEN_D),
    .ARSIZE_D           (ARSIZE_D),
    .ARBURST_D          (ARBURST_D),
    .ARVALID_D          (ARVALID_D),
    .RREADY_D           (RREADY_D),

    // AXI Write Master (Data Specific - _D)
    .AWID_D             (AWID_D),
    .AWADDR_D           (AWADDR_D),
    .AWLEN_D            (AWLEN_D),
    .AWSIZE_D           (AWSIZE_D),
    .AWBURST_D          (AWBURST_D),
    .AWVALID_D          (AWVALID_D),
    .AWREADY            (AWREADY),
    
    .WDATA_D            (WDATA_D),
    .WVALID_D           (WVALID_D),
    .WLAST_D            (WLAST_D),
    .WREADY             (WREADY),
    
    .BVALID             (BVALID),
    .BRESP              (BRESP),
    .BREADY_D           (BREADY_D),

    // Trigger and Control Signals
  //  .data_done          (data_done),
   // .linkaddren         (linkaddren),
    .SRCTRIGINSELERR    (SRCTRIGINSELERR),
    .DESTRIGINSELERR    (DESTRIGINSELERR),
    .TRIGOUTSELERR      (TRIGOUTSELERR),

    // Source Trigger Interface
    .src_trig_req       (src_trig_req),
    .src_trig_req_type  (src_trig_req_type),
    .ch_src_ack         (ch_src_ack),
    .ch_src_ack_type    (ch_src_ack_type),
    .use_src_trigin     (use_src_trigin),
    .src_trigin_type    (src_trigin_type),
    .src_trigin_sel     (src_trigin_sel),

    // Destination Trigger Interface
    .des_trig_req       (des_trig_req),
    .des_trig_req_type  (des_trig_req_type),
    .ch_des_ack         (ch_des_ack),
    .ch_des_ack_type    (ch_des_ack_type),
    .use_des_trigin     (use_des_trigin),
    .des_trigin_type    (des_trigin_type),
    .des_trigin_sel     (des_trigin_sel),

    // Trigger Out Interface
    .ch_trigout_req     (ch_trigout_req),
    .ch_trigout_ack     (ch_trigout_ack),
    .use_trigout        (use_trigout),
    .trigout_type       (trigout_type),
    .trigout_sel        (trigout_sel)
); 
       
     
     always #5 clk = ~clk;
     
     
     initial begin
     
     $monitor (" cmd_data_in %h \n,concat_cmd %h\n,mux_out_reg %h",dut.dut3.cmd_data_in,dut.dut3.concat_cmd,dut.dut3.mux_out_reg);
     end
     initial 
     begin
     {SRCTRIGINSELERR, DESTRIGINSELERR, TRIGOUTSELERR} = 0;
     clk = 0;
     resetn = 0;
     #20 resetn = 1;
   //  data_done = 1;
    // linkaddren = 1;
     reg_chn_in = {32'h0000ABCF,32'h0,32'h0,32'h0,32'h1234,32'h00010001,32'h0,32'h0,32'h00040004,32'h6084,32'h1612,32'h0E001200,32'h70F,32'h0,32'h01110001};
    
     #20;
     ARREADY_D = 1;
     #40
     ARREADY_D = 0;
     RVALID_D = 1;
     RRESP_D = 'b00;
  
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


    #40
    reg_chn_in[48] = 1;
    
    // from cmd fsm
    
    
    ARREADY = 1'b1;
    #10 ARREADY = 1'b0;
     RRESP='b00;
    RID = 'b0;
    RVALID =1;
     RDATA_I = 'h40385D5D;
     RLAST = 1;
     #10 RVALID =0; RLAST=0;
    
    ARREADY = 1'b1;
    #10 ARREADY = 1'b0;
        RVALID =1;
        RDATA_I = 32'h70F; #10//intren
        RDATA_I = 32'h0E001200;#10//ctrl
        RDATA_I = 32'h1612;#10//src addr
        RDATA_I = 32'h6084;#10//des addr
        RDATA_I=32'h00040004;#10//xsize
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
     
          #20;
     ARREADY_D = 1;
     #40
     ARREADY_D = 0;
     RVALID_D = 1;
     RRESP_D = 'b00;
  
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


    #40
    reg_chn_in[48] = 1;
     
     #200 $finish;
     
     end
        
endmodule

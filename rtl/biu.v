module biu#(parameter ADDR_W = 32,
                      DATA_W = 32,
                      ID_W = 3 )(

    input  wire        clk,
    input  wire        rst_n,

  //  input  wire [2:0]  ch_arvalid,// ch0_ARVALID, ch1_ARVALID, ch2_ARVALID, 

// new signal logic

    input  wire        ARREADY,
    input  wire        RVALID,
    input  wire        RLAST,
    input wire [1:0] RRESP,
    input  wire        AWREADY,
    input  wire        WREADY,
    input  wire        BVALID,
    input wire [1:0] BRESP,
    
    input  wire [2:0]  ch_awvalid,

    input  wire [2:0]  ch_wlast,
   

    output reg [1:0]   rd_grant,
    output reg [1:0]   wr_grant,
 ////////////////////////////////
 // =========================
    // CHANNEL 0
    // =========================
    input  ch0_ARVALID,
    input  [ADDR_W-1:0] ch0_ARADDR,
    input  [7:0]  ch0_ARLEN,
    input  [2:0]  ch0_ARSIZE,
    input  [1:0]  ch0_ARBURST,
    input  [3:0]  ch0_ARQOS,
    output ch0_ARREADY,

    output ch0_RVALID,
    output [DATA_W-1:0] ch0_RDATA,
    output ch0_RLAST,
    output [1:0] ch0_RRESP,

    input  ch0_RREADY,
    

    input  ch0_AWVALID,
    input  [ADDR_W-1:0] ch0_AWADDR,
    input  [7:0] ch0_AWLEN,
    input  [2:0] ch0_AWSIZE,
    input  [1:0] ch0_AWBURST,
    input  [3:0] ch0_AWQOS,
    output ch0_AWREADY,

    input  ch0_WVALID,
    input  [DATA_W-1:0] ch0_WDATA,
    input  ch0_WLAST,
    input  [(DATA_W/8)-1:0] ch0_WSTRB,
    output ch0_WREADY,
    

    output ch0_BVALID,
    input  ch0_BREADY,
    output wire [1:0] ch0_BRESP,
    // =========================
    // CHANNEL 1
    // =========================
    input  ch1_ARVALID,
    input  [ADDR_W-1:0] ch1_ARADDR,
    input  [7:0]  ch1_ARLEN,
    input  [2:0]  ch1_ARSIZE,
    input  [1:0]  ch1_ARBURST,
    input  [3:0]  ch1_ARQOS,
    output ch1_ARREADY,

    output ch1_RVALID,
    output [DATA_W-1:0] ch1_RDATA,
    output ch1_RLAST,
    input  ch1_RREADY,
     output [1:0] ch1_RRESP,

    input  ch1_AWVALID,
    input  [ADDR_W-1:0] ch1_AWADDR,
    input  [7:0] ch1_AWLEN,
    input  [2:0] ch1_AWSIZE,
    input  [1:0] ch1_AWBURST,
    input  [3:0] ch1_AWQOS,
    output ch1_AWREADY,

    input  ch1_WVALID,
    input  [DATA_W-1:0] ch1_WDATA,
    input  ch1_WLAST,
    input  [(DATA_W/8)-1:0] ch1_WSTRB,
    output ch1_WREADY,

    output ch1_BVALID,
    input  ch1_BREADY,
     output [1:0] ch1_BRESP,
    // =========================
    // CHANNEL 2
    // =========================
    input  ch2_ARVALID,
    input  [ADDR_W-1:0] ch2_ARADDR,
    input  [7:0]  ch2_ARLEN,
    input  [2:0]  ch2_ARSIZE,
    input  [1:0]  ch2_ARBURST,
    input  [3:0]  ch2_ARQOS,
    output ch2_ARREADY,

    output ch2_RVALID,
    output [DATA_W-1:0] ch2_RDATA,
    output ch2_RLAST,
    input  ch2_RREADY,
     output [1:0] ch2_RRESP,
    
    input  ch2_AWVALID,
    input  [ADDR_W-1:0] ch2_AWADDR,
    input  [7:0] ch2_AWLEN,
    input  [2:0] ch2_AWSIZE,
    input  [1:0] ch2_AWBURST,
    input  [3:0] ch2_AWQOS,
    output ch2_AWREADY,

    input  ch2_WVALID,
    input  [DATA_W-1:0] ch2_WDATA,
    input  ch2_WLAST,
    input  [(DATA_W/8)-1:0] ch2_WSTRB,
    output ch2_WREADY,

    output ch2_BVALID,
    input  ch2_BREADY,
     output [1:0] ch2_BRESP,
//////////////////////////////////////////////////////


    // =========================
    // AXI MASTER (M0)
    // =========================
   // input  ARREADY,
    output reg ARVALID,
    output reg [ADDR_W-1:0] ARADDR,
    output reg [7:0] ARLEN,
    output reg [2:0] ARSIZE,
    output reg [1:0] ARBURST,
    output reg [ID_W-1:0] ARID,
    output reg [3:0] ARQOS,

    input  [ID_W-1:0] RID,
  //  input  RVALID,
    input  [DATA_W-1:0] RDATA,
  //  input  RLAST,
    output reg RREADY,

 //   input  AWREADY,
    output reg AWVALID,
    output reg [ADDR_W-1:0] AWADDR,
    output reg [7:0] AWLEN,
    output reg [2:0] AWSIZE,
    output reg [1:0] AWBURST,
    output reg [ID_W-1:0] AWID,
    output reg [3:0] AWQOS,

//    input  WREADY,
    output reg WVALID,
    output reg [DATA_W-1:0] WDATA,
    output WLAST,
    output [(DATA_W/8)-1:0] WSTRB,

    input  [ID_W-1:0] BID,
//    input  BVALID,
    output reg BREADY,
    input wire [2:0] stop_cmd

);

localparam RD_IDLE = 2'd0;
localparam RD_AR   = 2'd1;
localparam RD_R    = 2'd2;
localparam RD_WAIT    = 2'd3;


localparam WR_IDLE = 2'd0;
localparam WR_AW   = 2'd1;
localparam WR_W    = 2'd2;
localparam WR_B    = 2'd3;



reg [1:0] rd_state,rd_state_next;

reg [1:0] rd_last_grant;

reg [3:0] rd_max_qos;
reg [2:0] rd_mask;


reg [1:0] wr_state;
reg [1:0] wr_last_grant;

reg [3:0] wr_max_qos;
reg [2:0] wr_mask;

reg RLAST_reg;

/////////////////////////////////////////////////////
assign ch0_ARREADY = (rd_grant == 0 /*&& rd_state == RD_AR*/) ? ARREADY : 0;
assign ch1_ARREADY = (rd_grant == 1 /*&& rd_state == RD_AR*/) ? ARREADY : 0;
assign ch2_ARREADY = (rd_grant == 2 /*&& rd_state == RD_AR*/) ? ARREADY : 0;

assign ch0_RVALID = (RID == 0 && rd_state == RD_R) ? RVALID : 0;
assign ch1_RVALID = (RID == 1 && rd_state == RD_R) ? RVALID : 0;
assign ch2_RVALID = (RID == 2 && rd_state == RD_R) ? RVALID : 0;

assign ch0_RDATA  = RDATA;
assign ch1_RDATA  = RDATA;
assign ch2_RDATA  = RDATA;

assign ch0_RLAST  = RLAST;
assign ch1_RLAST  = RLAST;
assign ch2_RLAST  = RLAST;

assign ch0_RRESP  = RRESP;
assign ch1_RRESP  = RRESP;
assign ch2_RRESP  = RRESP;

//////////////////////////////////////////////////////////




always @(*) begin
    ARVALID = 0;
    ARADDR  = 0;
    ARSIZE  = 0;
    ARBURST = 0;
    ARLEN   = 0;
    ARQOS   = 0;
    ARID    = rd_grant;
    if (rd_state == RD_R) begin
    case (RID)
        0: RREADY = ch0_RREADY;
        1: RREADY = ch1_RREADY;
        2: RREADY = ch2_RREADY;
        default: RREADY = 0;
    endcase
 end
 else begin
 RREADY = 0;
 end
    case (rd_grant)
        0: begin
        if(rd_state == RD_AR)begin
            ARVALID = ch0_ARVALID;
            ARADDR  = ch0_ARADDR;
            ARSIZE  = ch0_ARSIZE;
            ARBURST = ch0_ARBURST;
            ARLEN   = ch0_ARLEN;
            ARQOS   = ch0_ARQOS;
        end
        else begin
             ARVALID = 0;
            ARADDR  = 0;
            ARSIZE  = 0;
            ARBURST = 0;
            ARLEN   = 0;
            ARQOS   = 0;
        end
        end

        1: begin
        if(rd_state == RD_AR)begin
            ARVALID = ch1_ARVALID;
            ARADDR  = ch1_ARADDR;
            ARSIZE  = ch1_ARSIZE;
            ARBURST = ch1_ARBURST;
            ARLEN   = ch1_ARLEN;
            ARQOS   = ch1_ARQOS;
        end
        else begin
          ARVALID = 0;
            ARADDR  = 0;
            ARSIZE  = 0;
            ARBURST = 0;
            ARLEN   = 0;
            ARQOS   = 0;
        end
        end

        2: begin
        if(rd_state == RD_AR)begin
            ARVALID = ch2_ARVALID;
            ARADDR  = ch2_ARADDR;
            ARSIZE  = ch2_ARSIZE;
            ARBURST = ch2_ARBURST;
            ARLEN   = ch2_ARLEN;
            ARQOS   = ch2_ARQOS;
        end
        else begin
          ARVALID = 0;
            ARADDR  = 0;
            ARSIZE  = 0;
            ARBURST = 0;
            ARLEN   = 0;
            ARQOS   = 0;
        end
        end
        default: begin
            ARVALID = 0;
            ARADDR  = 0;
            ARSIZE  = 0;
            ARBURST = 0;
            ARLEN   = 0;
            ARQOS   = 0;
        end
    endcase
end

always @(*) begin
    AWVALID = 0;
    AWADDR  = 0;
    AWSIZE  = 0;
    AWBURST = 0;
    AWLEN   = 0;
    AWQOS   = 0;
    AWID    = wr_grant;

    case (wr_grant)
        0: begin
        if(wr_state ==  WR_AW)begin
            AWVALID = ch0_AWVALID;
            AWADDR  = ch0_AWADDR;
            AWSIZE  = ch0_AWSIZE;
            AWBURST = ch0_AWBURST;
            AWLEN   = ch0_AWLEN;
            AWQOS   = ch0_AWQOS;
        end
        else
        begin
            AWVALID = 0;
            AWADDR  = 0;
            AWSIZE  = 0;
            AWBURST = 0;
            AWLEN   = 0;
            AWQOS   = 0;
        end
        end

        1: begin
         if(wr_state ==  WR_AW)begin
            AWVALID = ch1_AWVALID;
            AWADDR  = ch1_AWADDR;
            AWSIZE  = ch1_AWSIZE;
            AWBURST = ch1_AWBURST;
            AWLEN   = ch1_AWLEN;
            AWQOS   = ch1_AWQOS;
        end
         else
        begin
            AWVALID = 0;
            AWADDR  = 0;
            AWSIZE  = 0;
            AWBURST = 0;
            AWLEN   = 0;
            AWQOS   = 0;
        end
        end

        2: begin
          if(wr_state ==  WR_AW)begin
            AWVALID = ch2_AWVALID;
            AWADDR  = ch2_AWADDR;
            AWSIZE  = ch2_AWSIZE;
            AWBURST = ch2_AWBURST;
            AWLEN   = ch2_AWLEN;
            AWQOS   = ch2_AWQOS;
        end
         else
        begin
            AWVALID = 0;
            AWADDR  = 0;
            AWSIZE  = 0;
            AWBURST = 0;
            AWLEN   = 0;
            AWQOS   = 0;
        end
        end
         default: begin
            AWVALID = 0;
            AWADDR  = 0;
            AWSIZE  = 0;
            AWBURST = 0;
            AWLEN   = 0;
            AWQOS   = 0;
         end
    endcase
end

assign ch0_AWREADY = (wr_grant == 0) ? AWREADY : 0;
assign ch1_AWREADY = (wr_grant == 1) ? AWREADY : 0;
assign ch2_AWREADY = (wr_grant == 2) ? AWREADY : 0;

always @(*) begin
    case (BID)
        0: BREADY = ch0_BREADY;
        1: BREADY = ch1_BREADY;
        2: BREADY = ch2_BREADY;
        default: BREADY = 0;
    endcase
end
always @(*) begin
    WVALID = 0;
    WDATA  = 0;

//    case (BID)
//        0: BREADY = ch0_BREADY;
//        1: BREADY = ch1_BREADY;
//        2: BREADY = ch2_BREADY;
//        default: BREADY = 0;
//    endcase
if (wr_state == WR_W) begin
    case (wr_grant)
        0: begin
            WVALID = ch0_WVALID;
            WDATA  = ch0_WDATA;
        end

        1: begin
            WVALID = ch1_WVALID;
            WDATA  = ch1_WDATA;
        end

        2: begin
            WVALID = ch2_WVALID;
            WDATA  = ch2_WDATA;
        end
    endcase
    end
    else
    begin
     WVALID = 0;
     WDATA  = 0;
    end
    
end


assign WLAST = (wr_grant == 0) ? ch0_WLAST :
               (wr_grant == 1) ? ch1_WLAST :
                                ch2_WLAST;

assign WSTRB = (wr_grant == 0) ? ch0_WSTRB :
               (wr_grant == 1) ? ch1_WSTRB :
                                ch2_WSTRB;
     
     
assign ch0_WREADY = (wr_grant == 0) ? WREADY : 0;
assign ch1_WREADY = (wr_grant == 1) ? WREADY : 0;
assign ch2_WREADY = (wr_grant == 2) ? WREADY : 0;


assign ch0_BVALID = (BID == 0) ? BVALID : 0;
assign ch1_BVALID = (BID == 1) ? BVALID : 0;
assign ch2_BVALID = (BID == 2) ? BVALID : 0;

assign ch0_BRESP = (BID == 0) ? BRESP : 0;
assign ch1_BRESP = (BID == 1) ? BRESP : 0;
assign ch2_BRESP = (BID == 2) ? BRESP : 0;

always @(*) begin
    rd_max_qos = 0;

    if (ch0_ARVALID && ch0_ARQOS >= rd_max_qos)
        rd_max_qos = ch0_ARQOS;

    if (ch1_ARVALID && ch1_ARQOS >= rd_max_qos)
        rd_max_qos = ch1_ARQOS;

    if (ch2_ARVALID && ch2_ARQOS >= rd_max_qos)
        rd_max_qos = ch2_ARQOS;

    rd_mask[0] = ch0_ARVALID && (ch0_ARQOS == rd_max_qos);
    rd_mask[1] = ch1_ARVALID && (ch1_ARQOS == rd_max_qos);
    rd_mask[2] = ch2_ARVALID && (ch2_ARQOS == rd_max_qos);
end

always@(posedge clk or negedge rst_n) begin
if(!rst_n)
 rd_grant <= 0;
 else
 begin
if(rd_state == RD_IDLE ) begin
                if (ch0_ARVALID || ch1_ARVALID || ch2_ARVALID) begin

                if (rd_mask == 3'b001)
                    rd_grant <= 0;
                else if (rd_mask == 3'b010)
                    rd_grant <= 1;
                else if (rd_mask == 3'b100)
                    rd_grant <= 2;
                else begin
                    case (rd_last_grant)
                        0: rd_grant <= rd_mask[1] ? 1 :
                                       rd_mask[2] ? 2 : 0;
                        1: rd_grant <= rd_mask[2] ? 2 :
                                       rd_mask[0] ? 0 : 1;
                        2: rd_grant <= rd_mask[0] ? 0 :
                                       rd_mask[1] ? 1 : 2;
                    endcase
                end

               // rd_state = RD_AR;
            end
            end
          end 
          end
          
           
always@(posedge clk or negedge rst_n) begin
if(!rst_n)
RLAST_reg <= 0;
else
RLAST_reg <= RLAST;
end


always @(posedge clk or negedge rst_n) begin
      if(!rst_n)        
        rd_state <= 0;
     else
       rd_state <= rd_state_next;
end


always @(posedge clk or negedge rst_n) begin
      if(!rst_n)         
        rd_last_grant <= 0;
        else
        rd_last_grant <= (rd_state == RD_R && RLAST_reg && RREADY) ? rd_grant :  rd_last_grant;
        
end

always @( * ) begin

     begin
    
if((stop_cmd[0]&& rd_grant==0) || (stop_cmd[1] && rd_grant==1) || (stop_cmd[2] && rd_grant==2))
  rd_state_next = RD_IDLE;
        case (rd_state)
       RD_IDLE:begin

                rd_state_next = RD_AR;

        end

        RD_AR: begin
            if (ARREADY && ARVALID)
                rd_state_next = RD_R;
        end

        RD_R: begin
            if (/*RVALID &&*/ RLAST_reg && RREADY) begin   
                rd_state_next      = RD_WAIT;
            end
        end
        
        RD_WAIT : rd_state_next =RD_IDLE;
        endcase
    end
end






always @(*) begin
    wr_max_qos = 0;

    if (ch0_AWVALID && ch0_AWQOS >= wr_max_qos)
        wr_max_qos = ch0_AWQOS;

    if (ch1_AWVALID && ch1_AWQOS >= wr_max_qos)
        wr_max_qos = ch1_AWQOS;

    if (ch2_AWVALID && ch2_AWQOS >= wr_max_qos)
        wr_max_qos = ch2_AWQOS;

    wr_mask[0] = ch0_AWVALID && (ch0_AWQOS == wr_max_qos);
    wr_mask[1] = ch1_AWVALID && (ch1_AWQOS == wr_max_qos);
    wr_mask[2] = ch2_AWVALID && (ch2_AWQOS == wr_max_qos);
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_state      <= WR_IDLE;
        wr_grant      <= 0;
        wr_last_grant <= 0;
    end else begin
 if((stop_cmd[0]&& wr_grant==0) || (stop_cmd[1] && wr_grant==1) || (stop_cmd[2] && wr_grant==2))
  wr_state <= WR_IDLE;
        case (wr_state)

        WR_IDLE: begin
            if (ch0_AWVALID || ch1_AWVALID || ch2_AWVALID) begin

                if (wr_mask == 3'b001)
                    wr_grant <= 0;
                else if (wr_mask == 3'b010)
                    wr_grant <= 1;
                else if (wr_mask == 3'b100)
                    wr_grant <= 2;
                else begin
                    case (wr_last_grant)
                        0: wr_grant <= wr_mask[1] ? 1 :
                                       wr_mask[2] ? 2 : 0;
                        1: wr_grant <= wr_mask[2] ? 2 :
                                       wr_mask[0] ? 0 : 1;
                        2: wr_grant <= wr_mask[0] ? 0 :
                                       wr_mask[1] ? 1 : 2;
                    endcase
                end

                wr_state <= WR_AW;
            end
        end

        WR_AW: begin
            if (AWREADY)
                wr_state <= WR_W;
        end

        WR_W: begin
            if (((ch0_WLAST ==1)||(ch1_WLAST)||(ch2_WLAST)) && WREADY)
                wr_state <= WR_B;
        end

        WR_B: begin
            if (BVALID) begin
                wr_last_grant <= wr_grant;
                wr_state      <= WR_IDLE;
            end
        end

        endcase
    end
end

endmodule



 

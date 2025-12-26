`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2025 11:04:29 AM
// Design Name: 
// Module Name: data_fsm
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

module data_fsm #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter ID_W   = 4
)(
    input  wire              clk,
    input  wire              resetn,

    // Control
    input  wire              enable_cmd,
    input  wire              pause_cmd,
    input  wire              resume_cmd,
    input  wire              disable_cmd,

    // Triggers
    input  wire              src_trigin_sw,//
    input  wire              dst_trigin_sw,//
 input  wire              src_trigin,//
    input  wire              dst_trigin,//
 output reg               src_trigack,
 output reg               dst_trigack,
    output reg               trig_out_req,//
    input  wire              trig_out_ack,//

    // Config
    input  wire [ADDR_W-1:0] SRC_ADDR,
    input  wire [ADDR_W-1:0] DST_ADDR,
    input  wire [2:0]        transize,
    input  wire [15:0]       srcxsize,
    input  wire [15:0]       desxsize,
    input  wire [2:0]        x_type,     // 1=CONT, 2=WRAP, 3=FILL
    input  wire [DATA_W-1:0] fillval,
    input  wire [3:0]        srcmaxburstlen,//
    input  wire [3:0]        desmaxburstlen,//

    // FIFO
   // input  wire              fifo_almost_full,   //remove these ---------------
    //input  wire              fifo_almost_empty,  //remove these ---------------
    //output reg               fifo_wr_en,
    //output reg               fifo_rd_en,
    //output reg [DATA_W-1:0]  fifo_w_data,
    //input  wire [DATA_W-1:0] fifo_r_data,

    // AXI READ
    input  wire              ARREADY,
    output reg               ARVALID,
    output reg [ADDR_W-1:0]  ARADDR,
    output reg [2:0]         ARSIZE,
    output reg [1:0]         ARBURST,
    output reg [ID_W-1:0]    ARID,
    output reg [3:0]         ARLEN,

    input  wire              RVALID,
    input  wire [DATA_W-1:0] RDATA,
    input  wire [1:0]        RRESP,
    input  wire              RLAST,
    output reg               RREADY,

    // AXI WRITE
    input  wire              AWREADY,
    output reg               AWVALID,
    output reg [ADDR_W-1:0]  AWADDR,
    output reg [2:0]         AWSIZE,
    output reg [1:0]         AWBURST,
    output reg [ID_W-1:0]    AWID,

    input  wire              WREADY,
    output reg               WVALID,
    output reg [DATA_W-1:0]  WDATA,
    output reg               WLAST,

    input  wire              BVALID,
    input  wire [1:0]        BRESP,
    output reg               BREADY,

    // Status
    output reg               DONE,
    output reg               ERROR,

    // Error flags
    output reg               config_error,
    output reg               ard_error,
    output reg               arpoison_error,
    output reg               awr_error,
    output reg               bus_error
);

    // Internal counters
    reg [15:0] src_left, dst_left, fill_count;
   // reg [15:0] wrap_index;
    reg [15:0] wrap_rd_ptr;
    reg [2:0]  size_reg;

    // fifo memory----------------
    reg [7:0] fifo_mem [0:255];
 reg [7:0] fifo_wptr;
 reg [7:0] fifo_rptr;

    reg [ADDR_W-1:0] src_addr_reg, dst_addr_reg;

    localparam IDLE     = 4'd0,
               CONFIG   = 4'd1,
               WAIT_RD  = 4'd2,
               AR       = 4'd3,
               R        = 4'd4,
               WAIT_WR  = 4'd5,
               AW       = 4'd6,
               W        = 4'd7,
               B        = 4'd8,
               TRIG_OUT = 4'd9,
               PAUSED   = 4'd10,
               DONE_ST  = 4'd11,
               ERROR_ST = 4'd12,
      WRAP_FILL = 4'd13;

    reg [3:0] state, next;

    wire case1 = (srcxsize == 0 && desxsize == 0);
    wire case2 = (srcxsize == 0 && desxsize > 0);
    wire case3 = (srcxsize > 0 && desxsize == 0);
    wire case4 = (srcxsize == desxsize && srcxsize > 0);
    wire case5 = (srcxsize > desxsize);
    wire case6 = (srcxsize < desxsize);

   // wire [ADDR_W-1:0] beat_inc = (1 << size_reg);

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            state <= IDLE;
        else
            state <= next;
    end

    always @(*) begin
        next = state;
        case (state)

            IDLE:
                if (enable_cmd)// differentate between hw/sw
                    next = CONFIG;

            CONFIG: begin
                if (config_error)
                    next = ERROR_ST;
                else if (case1)
                    next = DONE_ST;
                else if (case2)
                    next = (x_type == 0) ? DONE_ST :
                           ((x_type == 3) ? R : ERROR_ST);
                else if (case3)
                    next = ERROR_ST;
                else if (case6)
                    next = (x_type == 0) ? DONE_ST : WAIT_RD;
                else
                    next = WAIT_RD;
            end

            WAIT_RD:
                if (pause_cmd)
                    next = PAUSED;
                else if (src_left == 0)
                    next = WAIT_WR;
    else if (src_trigin_sw)
                    next = AR;
                else if (src_trigin)
                    next = AR;

            AR:
                if (ARVALID && ARREADY)
                    next = R;
                else
                    next = AR;

            R:
                if ((RRESP == 2 || RRESP == 3) && RVALID)
                    next = ERROR_ST;
                else if (RVALID && RREADY && RLAST)
                    if(src_left > 1 || fill_count > 0)//tempo fix
                    next = WRAP_FILL;
                    else 
                     next = WAIT_RD;
                else
                    next = R;
   WRAP_FILL : 
    if(src_left == 0 && fill_count == 0)
     next = WAIT_WR;
    else
     next = WRAP_FILL;
     
            WAIT_WR:
                if (pause_cmd)
                    next = PAUSED;
                else if (dst_left == 0)
                    next = TRIG_OUT;
                else if (dst_trigin_sw)
                    next = AW;
    else if (dst_trigin)
                    next = AW;

            AW:
                if (AWVALID && AWREADY)
                    next = W;

            W:
                if (WREADY && WVALID && WLAST)
                    next = B;

            B:
                if (BVALID && BREADY)
                    next = (BRESP <= 1) ? WAIT_WR : ERROR_ST;

            TRIG_OUT:
                if (trig_out_ack)
                    next = DONE_ST;

            PAUSED:
                if (resume_cmd)
                    next = (src_left > 0) ? WAIT_RD : WAIT_WR;

            DONE_ST:
                if (disable_cmd)
                    next = IDLE;

            ERROR_ST:
                if (disable_cmd)
                    next = IDLE;

        endcase
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            {ARVALID, RREADY, AWVALID, WVALID, BREADY,
              DONE, ERROR,
             trig_out_req, config_error, ard_error,
             arpoison_error, awr_error, bus_error} <= 0;
   fifo_wptr  <= 0;
   fifo_rptr  <= 0;
            src_left   <= 0;
            dst_left   <= 0;
            //wrap_index <= 0;
            fill_count <= 0;
   wrap_rd_ptr <= 0;
   src_trigack <= 0;
   dst_trigack <= 0;
        end else begin
           
            ARVALID      <= 0;
            RREADY       <= 0;
            AWVALID      <= 0;
            WVALID       <= 0;
            BREADY       <= 0;

            trig_out_req <= 0;
   src_trigack <= 0;
   dst_trigack <= 0;

            case (state)

                IDLE: begin
                    config_error   <= 0;
                    ard_error      <= 0;
                    arpoison_error <= 0;
                    awr_error      <= 0;
                    bus_error      <= 0;
                   // wrap_index     <= 0;
     fifo_wptr      <= 0;
           fifo_rptr      <= 0; 
     wrap_rd_ptr    <= 0;
     fill_count     <= 0;
     ARLEN <= 0;
                end

                CONFIG: begin
                    size_reg      <= transize;
                    src_addr_reg  <= SRC_ADDR;
                    dst_addr_reg  <= DST_ADDR;
                    
                    ARLEN  <= srcxsize;
                    ARBURST <= 2'b01;
                    ARSIZE  <= transize;
                    ARID    <= 0;

                    AWBURST <= 2'b01;
                    AWSIZE  <= transize;
                    AWID    <= 0;

                    config_error <= (x_type > 3) ? 1 : 0;

                    if (case1) begin
                        src_left <= 0;
                        dst_left <= 0;
                    end else if (case2) begin //(srcxsize == 0 && desxsize > 0);
                        if (x_type == 3) begin
                            src_left <= 0;
                            dst_left <= desxsize - 1;
                        end else if (x_type == 0)
                            config_error <= 0;
                        else
                            config_error <= 1;
                    end else if (case3)//(srcxsize > 0 && desxsize == 0);
                        config_error <= 1;
                    else if (case4 || case5) begin //(srcxsize == desxsize && srcxsize > 0);  (srcxsize > desxsize);

                        src_left <= srcxsize;
                        dst_left <= desxsize;
                    end else if (case6) begin
                        case (x_type)
                            0: begin
                                src_left <= 0;
                                dst_left <= 0;
                            end
                            1: begin//continue
                                src_left <= srcxsize;
                                dst_left <= srcxsize;
                            end
                            2: begin//wrap
                                src_left <= desxsize;
                                dst_left <= desxsize;
                            end
                            3: begin//fill
                                src_left <= srcxsize;
                                dst_left <= desxsize;
                            end
                            default: config_error <= 1;
                        endcase
                    end

                    fill_count <= ((srcxsize < desxsize) && x_type == 3 && (case2 || case6)) ?
                                   (desxsize - srcxsize) : 0;
                end

    WAIT_RD:
    if(src_trigin == 1)
     src_trigack <= 1;
    
                AR: begin
                    ARVALID <= 1;
                    //if (x_type == 2 && case6)
                       // ARADDR <= SRC_ADDR + wrap_index * beat_inc;
                    //else
                        ARADDR <= src_addr_reg;
                end

                R: 
    begin
    if(fifo_wptr+1 != fifo_rptr)
     RREADY <= 1;
    else
     RREADY <= 0;
     
    if(RVALID && RREADY && src_left > 0) begin
     fifo_mem[fifo_wptr] <=  RDATA;
     fifo_wptr <= fifo_wptr + 1;
     src_left    <= src_left - 1;    
    end
    end
   
    WRAP_FILL :
    begin
     case (x_type)

      2: begin
       //if (desxsize - src_left <= srcxsize) begin
        //if (rvalid && rready) begin
        // fifo_mem[fifo_wptr] <= RDATA;
        // fifo_wptr           <= fifo_wptr + 1;
        // src_left            <= src_left - 1;
        //end
       //end
       //else
       if ((!(desxsize - src_left < srcxsize)) && src_left > 0) begin
        // add else and check
        fifo_mem[fifo_wptr] <= fifo_mem[wrap_rd_ptr];
        wrap_rd_ptr         <= (wrap_rd_ptr == srcxsize) ? 0 : wrap_rd_ptr + 1;
        fifo_wptr           <= fifo_wptr + 1;
        src_left            <= src_left - 1;
       end
      end

      3: begin
       //if (rvalid && rready) begin
       // // fill
       // if (src_left > 0) begin
       //  fifo_mem[fifo_wptr] <= RDATA;
       //  src_left            <= src_left - 1; // 2,1,0
       //  fifo_wptr           <= fifo_wptr + 1; // 0,1,2
       // end
        //else
        if (fill_count > 0 &&
           src_left == 0 &&
           x_type == 3 &&
           (case2 || case6)) begin
         // added xtype
         fifo_mem[fifo_wptr] <= fillval;
         fill_count          <= fill_count - 1; // 4,3,2,1
         fifo_wptr           <= fifo_wptr + 1;  // 3,4,5,6
        end
       end
     
      default : fifo_mem[fifo_wptr] <= fifo_mem[fifo_wptr] ;
     endcase
    end

    
    
    /*begin
                    RREADY <= 1;
                    if (RVALID && RREADY) begin
      if(fill_count > 0 && src_left == 0 && x_type == 3 && (case2 || case6))//added xtype
       begin
       fifo_mem[fifo_wptr] <= fillval;
       fill_count <= fill_count - 1;
       fifo_wptr <= fifo_wptr + 1;
       end
       
      else if ((x_type == 2 && case6 && wrap_rd_ptr < fifo_wptr && src_left > 0)) begin
       if (!fifo_full) begin // write logic for fifo full
        fifo_mem[fifo_wptr] <= (desxsize - src_left <= srcxsize)? RDATA: fifo_mem[wrap_rd_ptr];
        wrap_rd_ptr <= (wrap_rd_ptr == srcxsize-1) ? 0 : wrap_rd_ptr + 1;
        src_left    <= src_left - 1;
        fifo_wptr <= fifo_wptr + 1;
       end
      end
       
      else
      begin
       fifo_mem[fifo_wptr] <= RDATA;
       fifo_wptr <= fifo_wptr + 1;
       src_left <= src_left - 1;
      end
         
      if (RRESP == 2 && RLAST) begin
       arpoison_error <= 1;
       bus_error      <= 1;
      end

      if (RRESP == 3 && RLAST) begin
       ard_error <= 1;
       bus_error <= 1;
                    end
    else
     //fill and wrap cases
     
                end
                        //fifo_mem[] <= (fill_count > 0 && src_left == 0 && x_type == 3) ?//added xtype
                           //             fillval : RDATA;
                     
 
     
      //if (x_type == 2 && case6) begin
      // wrap_index <= (wrap_index == srcxsize - 1) ? 0 :
      //      wrap_index + 1;
      // src_left <= src_left - 1;
      //end else if ((src_left == 0) && (case2 || case6) && x_type == 3)//added x type
       //fill_count <= fill_count - 1;
      //else begin
       
       //src_addr_reg <= src_addr_reg + beat_inc;
      //end
     
      // */

    WAIT_WR:
    if(dst_trigin == 1)
     dst_trigack <= 1;
    
                AW: begin
                    AWVALID <= 1;
                    AWADDR  <= dst_addr_reg;
                end

                W: begin
                    WVALID <= 1;
     WLAST  <= (dst_left == 1); //1 or 0
                    if (WREADY && dst_left > 0) begin
                        WDATA       <= fifo_mem [fifo_rptr];
                        dst_left    <= dst_left - 1;
      fifo_rptr <= fifo_rptr + 1;
                    end
                end

                B: begin
                    BREADY <= 1;
                    if (BRESP >= 2) begin
                        awr_error <= 1;
                        bus_error <= 1;
                    end
                end

                TRIG_OUT: trig_out_req  <= 1;
                DONE_ST:  DONE          <= 1;
                ERROR_ST: ERROR         <= 1;

            endcase
        end
    end

endmodule




// trigger and difference b/w hw and sw 
// transistion from error to idle state
 


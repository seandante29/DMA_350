`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module data_fsm #(
    parameter ADDR_W = 32,
    parameter DATA_W = 1024,
    parameter ID_W   = 4
)(
    input  wire              clk,
    input  wire              resetn,
    input  wire              stat_error,
    input  wire              stat_done,
    input wire               link_en,// added
    // Control
    input  wire              enable_cmd,
    input  wire              pause_cmd,
    input  wire              resume_cmd,
    input  wire              disable_cmd,
    input  wire              cmd_done,

    // Triggers
    input  wire              use_src_trigin,
    input  wire [1:0]        src_trigin_type,
    input  wire [1:0]        src_trigin_mode,
    input  wire [7:0]        src_trigin_sel,

    input  wire              use_des_trigin,
    input  wire [1:0]        des_trigin_type,
    input  wire [1:0]        des_trigin_mode,
    input  wire [7:0]        des_trigin_sel,

    input  wire              use_trigout,
    input  wire [1:0]        trigout_type,
    input  wire [7:0]        trigout_sel,

    input  wire              src_trigin_sw,
    input  wire              des_trigin_sw,
    input  wire              trig_out_ack_sw,

    input  wire [1:0]        src_trigin_req_type,
    input  wire [1:0]        des_trigin_req_type,

    // To trigger matrix
    output reg  [1:0]        src_trigin_ack_type,
    output reg  [1:0]        des_trigin_ack_type,

    input  wire              SRCTRIGINSELERR,
    input  wire              DESTRIGINSELERR,
    input  wire              TRIGOUTSELERR,
    output wire              trig_err,

    input  wire              src_trigin,
    input  wire              des_trigin,
    output reg               src_trigack,
    output reg               des_trigack,
    output reg               trig_out_req,
    input  wire              trig_out_ack,

    // Config
    input  wire [ADDR_W-1:0] SRC_ADDR,
    input  wire [ADDR_W-1:0] des_ADDR,
    input  wire [2:0]        transize,
    input  wire [15:0]       srcxsize,
    input  wire [15:0]       desxsize,
    input  wire [2:0]        x_type,
    input  wire [DATA_W-1:0] fillval,
    input  wire [3:0]        srcmaxburstlen,
    input  wire [3:0]        desmaxburstlen,
    input  wire              src_xaddr_inc,
    input  wire              des_xaddr_inc,

    // AXI READ
    input  wire              ARREADY,
    output reg               ARVALID,
    output reg [ADDR_W-1:0]  ARADDR,
    output reg [2:0]         ARSIZE,
    output reg [1:0]         ARBURST,
    output reg [ID_W-1:0]    ARID,
    output reg [7:0]         ARLEN,

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
    output wire              ERROR,

    // Error flags
    output reg               config_error,
    output reg               ard_error,
    output reg               arpoison_error,
    output reg               awr_error,
    output reg               bus_error,
    output reg               regvalerr
);

    // Internal counters
    reg [15:0] src_left, des_left, fill_count;
    reg [15:0] wrap_rd_ptr;
    reg [2:0]  size_reg;
    reg [10:0] bits_per_beat;
    reg [DATA_W-1:0] wdata_mask;
    integer i;

    // FIFO memory
    reg [1023:0] fifo_mem [0:255];
    reg [7:0] fifo_wptr;
    reg [7:0] fifo_rptr;

    reg [ADDR_W-1:0] src_addr_reg, des_addr_reg;

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
    wire case5 = (srcxsize > desxsize && desxsize > 0);
    wire case6 = (srcxsize < desxsize && srcxsize > 0);

    assign ERROR   = config_error || ard_error || arpoison_error || awr_error || bus_error;
    assign trig_err = SRCTRIGINSELERR || DESTRIGINSELERR || TRIGOUTSELERR;

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
                if (enable_cmd && cmd_done && !ERROR && !DONE)
                    next = CONFIG;
                 else //added else part
                    next = IDLE;

            CONFIG: begin
                if (config_error)
                    next = ERROR_ST;
                 
                else if (case1 || x_type == 0 ) // added this
                    next = DONE_ST;
                else if (case2)
                    next = (x_type == 0) ? DONE_ST :
                           ((x_type == 3) ? WRAP_FILL : ERROR_ST);
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
              //  else if ((src_trigin_type == 2'b00 && src_trigin_sw) ||
                 //        (src_trigin_type == 2'b10 && src_trigin))
               else if ((src_trigin_type == 2'b00 && src_trigin_sw))
                    next = AR;
                else if((src_trigin_type == 2'b10 && src_trigin))
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
                    if (src_left > 1 || fill_count > 0)
                        next = WRAP_FILL;
                    else
                        next = WAIT_RD;
                else
                    next = R;

            WRAP_FILL:
                if (src_left == 0 && fill_count == 0)
                    next = WAIT_WR;
                else
                    next = WRAP_FILL;

            WAIT_WR:
                if (pause_cmd)
                    next = PAUSED;
                else if (des_left == 0)
                    next = TRIG_OUT;
              //  else if ((des_trigin_type == 2'b00 && des_trigin_sw) ||
                 //        (des_trigin_type == 2'b10 && des_trigin))
                 else if ((des_trigin_type == 2'b00 && des_trigin_sw))
                    next = AW;
                  else if ((des_trigin_type == 2'b10 && des_trigin))
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
                if (!use_trigout)
                    next = DONE_ST;
                else if (trigout_type == 2'b00 && trig_out_ack_sw)
                    next = DONE_ST;
                else if (trigout_type == 2'b10 && trig_out_ack)
                    next = DONE_ST;

            PAUSED:
                if (resume_cmd)
                    next = (src_left > 0) ? WAIT_RD : WAIT_WR;

            DONE_ST:
                if (disable_cmd || link_en)//link_en indicates there is command link
                    next = IDLE;

            ERROR_ST:
                if (stat_error == 0) // changed from disable to stat_error
                    next = IDLE;
                default : next = IDLE;
        endcase
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            {ARVALID, RREADY, AWVALID, WVALID, BREADY,
             DONE, trig_out_req, config_error, ard_error,
             arpoison_error, awr_error, bus_error} <= 0;

            fifo_wptr <= 0;
            fifo_rptr <= 0;
            src_left  <= 0;
            des_left  <= 0;
            fill_count <= 0;
            wrap_rd_ptr <= 0;
            src_trigack <= 0;
            des_trigack <= 0;
        end else begin

            ARVALID <= 0;
            RREADY  <= 0;
            AWVALID <= 0;
            WVALID  <= 0;
            BREADY  <= 0;

            trig_out_req <= 0;
            src_trigack  <= 0;
            des_trigack  <= 0;

            case (state)

                IDLE: begin
                    if (stat_error == 0) begin
                        config_error   <= 0;
                        ard_error      <= 0;
                        arpoison_error <= 0;
                        awr_error      <= 0;
                        bus_error      <= 0;
                        regvalerr      <= 0;
                    end
                    if (stat_done == 0)
                        DONE <= 0;

                    fifo_wptr   <= 0;
                    fifo_rptr   <= 0;
                    wrap_rd_ptr <= 0;
                    fill_count  <= 0;
                    ARLEN       <= 0;
                end

                CONFIG: begin
                    bits_per_beat <= (8'd1 << transize) << 3;

                    wdata_mask <= {DATA_W{1'b0}};
                    for (i = 0; i < DATA_W; i = i + 1) begin
                        if (i < ((8'd1 << transize) << 3))
                            wdata_mask[i] <= 1'b1;
                    end

                    size_reg     <= transize;
                    src_addr_reg <= SRC_ADDR;
                    des_addr_reg <= des_ADDR;

                    ARLEN   <= srcxsize;
                    ARBURST <= (src_xaddr_inc) ? 2'b01 : 2'b00;
                    ARSIZE  <= transize;
                    ARID    <= 0;

                    AWBURST <= (des_xaddr_inc) ? 2'b01 : 2'b00;
                    AWSIZE  <= transize;
                    AWID    <= 0;

                    if (use_src_trigin) begin
                        if ((src_trigin_type != 2'b00 && src_trigin_type != 2'b10) ||
                             src_trigin_mode != 2'b00) begin
                            config_error <= 1;
                            regvalerr    <= 1;
                        end
                    end

                    if (use_des_trigin) begin
                        if ((des_trigin_type != 2'b00 && des_trigin_type != 2'b10) ||
                             src_trigin_mode != 2'b00) begin
                            config_error <= 1;
                            regvalerr    <= 1;
                        end
                    end

                    if (use_trigout) begin
                        if (trigout_type != 2'b00 && trigout_type != 2'b10) begin
                            config_error <= 1;
                            regvalerr    <= 1;
                        end
                    end

                    config_error <= (x_type > 3) ? 1 : 0;
                  //  config_error <= (config_error | (x_type > 3) ? 1 : 0);//?

                    if (case1) begin
                        src_left <= 0;
                        des_left <= 0;
                    end else if (case2) begin
                        if (x_type == 3) begin
                            src_left <= 0;
                            des_left <= desxsize - 1;
                        end else if (x_type == 0)
                            config_error <= 0;
                        else
                            config_error <= 1;
                    end else if (case3)
                        config_error <= 1;
                    else if (case4 || case5) begin
                        src_left <= srcxsize;
                        des_left <= desxsize;
                    end else if (case6) begin
                        case (x_type)
                            0: begin
                                src_left <= 0;
                                des_left <= 0;
                            end
                            1: begin
                                src_left <= srcxsize;
                                des_left <= srcxsize;
                            end
                            2: begin
                                src_left <= desxsize;
                                des_left <= desxsize;
                            end
                            3: begin
                                src_left <= srcxsize;
                                des_left <= desxsize;
                            end
                            default: config_error <= 1;
                        endcase
                    end

                    fill_count <= ((srcxsize < desxsize) && x_type == 3 && (case2 || case6)) ?
                                   (desxsize - srcxsize) : 0;
                end

                WAIT_RD:
                    if (src_trigin_type == 2'b10 && src_trigin) begin
                        src_trigack <= 1;
                        src_trigin_ack_type <=
                            (src_trigin_req_type == 0 || src_trigin_req_type == 2) ? 0 : 1;
                    end

                AR: begin
                    ARVALID <= 1;
                    ARADDR  <= src_addr_reg;
                end

                R: begin
                    if (fifo_wptr + 1 != fifo_rptr)
                        RREADY <= 1;
                    else
                        RREADY <= 0;

                    if (RVALID && RREADY && src_left > 0) begin
                        fifo_mem[fifo_wptr] <= RDATA;
                        fifo_wptr           <= fifo_wptr + 1;
                        src_left            <= src_left - 1;
                    end
                end

                WRAP_FILL: begin
                    case (x_type)

                        2: begin
                            if ((!(desxsize - src_left < srcxsize)) && src_left > 0) begin
                                fifo_mem[fifo_wptr] <= fifo_mem[wrap_rd_ptr];
                                wrap_rd_ptr         <= (wrap_rd_ptr == srcxsize) ? 0 : wrap_rd_ptr + 1;
                                fifo_wptr           <= fifo_wptr + 1;
                                src_left            <= src_left - 1;
                            end
                        end

                        3: begin
                            if (fill_count > 0 && src_left == 0 && (case2 || case6)) begin
                                fifo_mem[fifo_wptr] <= fillval;
                                fill_count          <= fill_count - 1;
                                fifo_wptr           <= fifo_wptr + 1;
                            end
                        end

                        default: begin
                            fifo_mem[fifo_wptr] <= fifo_mem[fifo_wptr];
                        end
                    endcase
                end

                WAIT_WR:
                    if (des_trigin_type == 2'b10 && des_trigin) begin
                        des_trigack <= 1;
                        des_trigin_ack_type <=
                            (des_trigin_req_type == 0 || des_trigin_req_type == 2) ? 0 : 1;
                    end

                AW: begin
                    AWVALID <= 1;
                    AWADDR  <= des_addr_reg;
                end

                W: begin
                    WVALID <= 1;
                    WLAST  <= (des_left == 1);

                    if (WREADY && des_left > 0) begin
                        WDATA    <= fifo_mem[fifo_rptr] & wdata_mask;
                        des_left <= des_left - 1;
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

                TRIG_OUT:
                    trig_out_req <= 1;

                DONE_ST:
                    DONE <= 1;
            endcase
        end
    end


endmodule



`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module data_fsm #(
    parameter ADDR_W = 32,
    parameter DATA_W = 128,
    parameter ID_W   = 4
)(
    input  wire              clk,
    input  wire              resetn,
    input  wire              stat_error,
    input wire stat_error_partsel,
    input  wire              stat_done_reg,
    input  wire              link_en,        // added
    // Control
    input  wire              enable_cmd,
    input  wire              pause_cmd,
    input  wire              resume_cmd,
    input  wire              disable_cmd,
    input  wire              stop_cmd,
    input  wire              cmd_done,
    input wire               stat_disable_reg,
    input wire               stat_stop_reg,

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

    input wire [1:0] src_trigin_sw_req_type,
    input wire [1:0] des_trigin_sw_req_type,
    
    input  wire [1:0]        src_trigin_req_type,
    input  wire [1:0]        des_trigin_req_type,

    // To trigger matrix
    output reg  [1:0]        src_trigin_ack_type,
    output reg  [1:0]        des_trigin_ack_type,

  //  input  wire              SRCTRIGINSELERR,
  //  input  wire              DESTRIGINSELERR,
 //   input  wire              TRIGOUTSELERR,
//    output wire              trig_err,

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
    input  wire [127:0]      fillval,
    input  wire  [15:0]            src_xaddr_inc,
    input  wire   [15:0]           des_xaddr_inc,

    // AXI READ
    input  wire              ARREADY,
    output reg               ARVALID,
    output reg  [ADDR_W-1:0] ARADDR,
    output reg  [2:0]        ARSIZE,
    output reg  [1:0]        ARBURST,
    output reg  [ID_W-1:0]   ARID,
    output reg  [7:0]        ARLEN,

    input wire              [3:0] RID,
    input  wire              RVALID,
    input  wire [127 : 0]    RDATA,
    input  wire [1:0]        RRESP,
    input  wire              RLAST,
    output reg               RREADY,

    // AXI WRITE
    input  wire              AWREADY,
    output reg               AWVALID,
    output reg  [ADDR_W-1:0] AWADDR,
    output reg  [2:0]        AWSIZE,
    output reg  [1:0]        AWBURST,
    output reg  [ID_W-1:0]   AWID,
    output reg  [7:0] AWLEN,

    input  wire              WREADY,
    output reg               WVALID,
    output reg  [DATA_W-1:0] WDATA,
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
    output reg               regvalerr,
    output wire      cmd_done_stop,
    output reg               ENABLECMD, DISABLECMD, STOPCMD,
    output reg               STAT_STOP, STAT_DISABLE, STAT_RESUMEWAIT, 
    output reg               STAT_TRIGOUTACKWAIT, STAT_SRCTRIGINWAIT, 
    output reg               STAT_DESTRIGINWAIT, STAT_PAUSED, STAT_DONE
);

    // Internal counters
    reg cmd_done_reg;
    reg [15:0] src_left, des_left, fill_count;
    reg [15:0] wrap_rd_ptr;
    reg [DATA_W-1:0] wdata_mask;
    integer i;

    // FIFO memory
    reg [127:0] fifo_mem [0:255];
    reg [7:0]   fifo_wptr;
    reg [7:0]   fifo_rptr;
    integer j;

    reg [ADDR_W-1:0] src_addr_reg, des_addr_reg;

    
    localparam IDLE      = 4'd0,
               CONFIG    = 4'd1,
               WAIT_TRIG = 4'd2,
               AR        = 4'd3,
               R         = 4'd4,
               AW        = 4'd5,
               W         = 4'd6,
               B         = 4'd7,
               TRIG_OUT  = 4'd8,
               PAUSED    = 4'd9,
               DONE_ST   = 4'd10,
               ERROR_ST  = 4'd11,
               WRAP_FILL = 4'd12,
               WAIT = 4'd13;

    reg [3:0] state, next;

    wire case1 = (srcxsize == 0 && desxsize == 0);
    wire case2 = (srcxsize == 0 && desxsize > 0);
    wire case3 = (srcxsize > 0 && desxsize == 0);
    wire case4 = (srcxsize == desxsize && srcxsize > 0);
    wire case5 = ((srcxsize > desxsize) && (desxsize != 0));
    wire case6 = ((srcxsize < desxsize) && (srcxsize !=0));
    assign cmd_done_stop = (state == WAIT) ? 1 : 0;

  assign ERROR    = config_error || ard_error || arpoison_error || awr_error || bus_error;
 //   assign trig_err = SRCTRIGINSELERR || DESTRIGINSELERR || TRIGOUTSELERR;

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            state <= IDLE;
        else
            state <= next;
    end

        
    // Next State Logic
    always @(*) begin
        next = state;
        if (stop_cmd) begin
            next = IDLE;
        end else begin
        
        
            case (state)
                IDLE:
                    if (enable_cmd && cmd_done && !stat_error && !DONE && !stat_disable_reg && !stat_done_reg && !STAT_STOP)
                        next = WAIT;
                    else
                        next = IDLE;
                        
                WAIT : next = CONFIG;
                
                CONFIG: begin
                    if (config_error)
                        next = ERROR_ST;
                    else if (case1 || x_type == 0)
                        next = DONE_ST;
                    else if (case2)
                        next = (x_type == 3) ? WAIT_TRIG : ERROR_ST; // Note: You had WAIT_RD, but it's not defined. Using WAIT_TRIG
                    else if (case3)
                        next = ERROR_ST;
                    else if (case6)
                        next = (x_type == 0) ? DONE_ST : WAIT_TRIG;
                    else
                        next = WAIT_TRIG;
                end

                
                WAIT_TRIG:
                if (config_error)
                        next = ERROR_ST;
                    else if (pause_cmd)
                        next = PAUSED;
                    else if (use_src_trigin && use_des_trigin) begin  
                    
                        if ((src_trigin_type == 2'b00 && src_trigin_sw) && (des_trigin_type == 2'b00 && des_trigin_sw))
                            next = (case2 && x_type == 'd3) ? WRAP_FILL : AR; 
                        else if ((src_trigin_type == 2'b10 && src_trigin) && (des_trigin_type == 2'b10 && des_trigin))
                            next = (case2 && x_type == 'd3) ? WRAP_FILL : AR;  
                    end
                    else if (!use_src_trigin && !use_des_trigin)
                        next = AR;
                    else
                        next = WAIT_TRIG;

                AR:
                    if (ARVALID && ARREADY)
                        next = R;
                    else
                        next = AR;

                R:
                    if ((RRESP == 2 || RRESP == 3) && RVALID)
                        next = ERROR_ST;
                    else if (RVALID && RREADY && RLAST) begin
                        if ((src_left > 0 || fill_count > 1) &&(case6 || case2))
                            next = WRAP_FILL;
                      // else if (src_left == 0)
                          //next = AW;
                        else
                            next = AW;
                    end else
                        next = R;

                WRAP_FILL:
                    if (src_left == 0 && fill_count == 0)
                        next = AW;
                    else
                        next = WRAP_FILL;

                AW:
                    if (AWVALID && AWREADY)
                        next = W;

                W:
                    if (WREADY && WVALID && WLAST)
                        next = B;

                B:
                    if (BVALID && BREADY)
                        next = (BRESP <= 1) ? TRIG_OUT : ERROR_ST;

                TRIG_OUT:
                    if (!use_trigout)
                        next = DONE_ST;
                    else begin
                        if (trigout_type == 2'b00 && trig_out_ack_sw)
                            next = DONE_ST;
                        else if (trigout_type == 2'b10 && trig_out_ack)
                            next = DONE_ST;
                    end

                PAUSED:
                    if (resume_cmd)
                        next = WAIT_TRIG;

                DONE_ST:
                    next = IDLE;
                     //next = STAT_DONE ? DONE_ST : IDLE;

                ERROR_ST:
                    //if (stat_error_partsel ==0)// (stat_error == 1)
                        next = IDLE;

                default: next = IDLE;
            endcase
        end
    end

    // Sequential Logic
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            {ARVALID, RREADY, AWVALID, WVALID, BREADY,
             DONE, trig_out_req, config_error, ard_error,regvalerr,
             arpoison_error, awr_error, bus_error,cmd_done_reg} <= 0;
            {ENABLECMD, DISABLECMD, STOPCMD, STAT_STOP, STAT_DISABLE, STAT_RESUMEWAIT,
             STAT_TRIGOUTACKWAIT, STAT_SRCTRIGINWAIT, STAT_DESTRIGINWAIT, STAT_PAUSED, STAT_DONE} <= 'b0;

            fifo_wptr   <= 0;
            fifo_rptr   <= 0;
            src_left    <= 0;
            des_left    <= 0;
            fill_count  <= 0;
            wrap_rd_ptr <= 0;
            src_trigack <= 0;
            des_trigack <= 0;
            
            for(j=0;j<255;j=j+1) begin
                fifo_mem [j] <= 'd0;end
                
        end else begin
            ARVALID      <= 0;
            RREADY       <= 0;
            AWVALID      <= 0;
            WVALID       <= 0;
            BREADY       <= 0;
            DONE         <= 0;
            trig_out_req <= 0;
            src_trigack  <= 0;
            des_trigack  <= 0;
            cmd_done_reg <= cmd_done;
         //   cmd_done_stop <= 'd0;
        //   {STAT_STOP, STAT_DISABLE, STAT_RESUMEWAIT,
           //STAT_TRIGOUTACKWAIT, STAT_SRCTRIGINWAIT, STAT_DESTRIGINWAIT, STAT_PAUSED} <= 'b0;
            //STAT_DONE <= !stat_done ? 0 :1;
            STAT_RESUMEWAIT <= 'd0;
            STAT_PAUSED <= 'd0;
             if( stat_disable_reg == 0)begin
                         ENABLECMD    <= 0;
                        STAT_DISABLE  <= 0;
                         DISABLECMD <= 0;
                end
            if(stat_stop_reg == 0) begin
                 ENABLECMD    <= 0;
                STAT_STOP    <= 0;
                STOPCMD <= 0;
            end
            if (disable_cmd) begin
                ENABLECMD    <= 1;
                DISABLECMD <= 1;
                STAT_DISABLE <= 1;
            end
            if (stop_cmd ) begin
                ENABLECMD    <= 1;
                STAT_STOP    <= 1;
                STOPCMD <= 1;
            end
            STAT_DONE <= stat_done_reg ? STAT_DONE:0 ;
//data_done <=0;
            case (state)
                IDLE: begin
                    if (stat_error == 0) begin
                        config_error   <= 0;
                        ard_error      <= 0;
                        arpoison_error <= 0;
                        awr_error      <= 0;
                        bus_error      <= 0;
                        regvalerr      <= 0;
                        //data_done <=1; if cpu gives linaddr for reconfig.. then data_done should be high
                    end
                  /*  if( stat_disable_reg == 0)
                        STAT_DISABLE  <= 0;*/
                   // STAT_DONE <= stat_done_reg ? 0:STAT_DONE ;
                    fifo_wptr   <= 0;
                    fifo_rptr   <= 0;
                    wrap_rd_ptr <= 0;
                    fill_count  <= 0;
                    ARLEN       <= 0;
                end

                CONFIG: begin
                    wdata_mask <= {DATA_W{1'b0}};
                    for (i = 0; i < DATA_W; i = i + 1) begin
                        if (i < ((8'd1 << transize) << 3))
                            wdata_mask[i] <= 1'b1;
                    end

                    src_addr_reg <= SRC_ADDR;
                    des_addr_reg <= des_ADDR;

                    ARLEN   <= srcxsize;
                    ARBURST <= (src_xaddr_inc) ? 2'b01 : 2'b00;
                    ARSIZE  <= transize;
                    ARID    <= 0;

                    AWLEN <= desxsize;
                    AWBURST <= (des_xaddr_inc) ? 2'b01 : 2'b00;
                    AWSIZE  <= transize;
                    AWID    <= 0;

                    if (use_src_trigin) begin
                        if ((src_trigin_type != 2'b00 && src_trigin_type != 2'b10) || src_trigin_mode != 2'b00) begin
                            config_error <= 1;
                            regvalerr    <= 1;
                        end
                    end

                    if (use_des_trigin) begin
                        if ((des_trigin_type != 2'b00 && des_trigin_type != 2'b10) || src_trigin_mode != 2'b00) begin
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

                    config_error <= (config_error | (x_type > 3) |(src_xaddr_inc>1| (des_xaddr_inc>1))? 1 : 0);

                    if (case1) begin
                        src_left <= 0;
                        des_left <= 0;
                    end else if (case2) begin
                        if (x_type == 3) begin
                            src_left <= 0;
                            des_left <= desxsize;
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
                            0: begin src_left <= 0; des_left <= 0; end
                            1: begin src_left <= srcxsize; des_left <= srcxsize; end
                            2: begin src_left <= desxsize; des_left <= desxsize; end
                            3: begin src_left <= srcxsize; des_left <= desxsize; end
                            default: config_error <= 1;
                        endcase
                    end

                    fill_count <= ((srcxsize < desxsize) && x_type == 3 && (case2 || case6)) ? (desxsize - srcxsize) : 0;
                end

                WAIT_TRIG: begin
                    if (use_src_trigin && use_des_trigin) begin  
                        if ((src_trigin_type == 2'b10 && src_trigin) && (des_trigin_type == 2'b10 && des_trigin)) begin
                            src_trigack <= 1;
                            src_trigin_ack_type <= (src_trigin_req_type == 0 || src_trigin_req_type == 2) ? 0 : 1;
                            des_trigack <= 1;
                            des_trigin_ack_type <= (des_trigin_req_type == 0 || des_trigin_req_type == 2) ? 0 : 1;					
                        end else begin
                         if (!((src_trigin_type == 2'b00 && src_trigin_sw) && (des_trigin_type == 2'b00 && des_trigin_sw))) begin
                            STAT_SRCTRIGINWAIT <= 1'b1;
                            STAT_DESTRIGINWAIT <= 1'b1;				
                            end	
                        end
                    end
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
                        default: fifo_mem[fifo_wptr] <= fifo_mem[fifo_wptr];
                    endcase
                end

                AW: begin
                    AWVALID <= 1;
                    AWADDR  <= des_addr_reg;
                end

                W: begin
                    WVALID <= 1;
                    WLAST  <= (des_left == 1);
                    if (WREADY && des_left > 0) begin
                        WDATA     <= fifo_mem[fifo_rptr] & wdata_mask;
                        des_left  <= des_left - 1;
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

                TRIG_OUT: begin
                    if (use_trigout && trigout_type == 'b10)
                        trig_out_req <= 1;
                    
                    if (use_trigout && !trig_out_ack_sw && trigout_type == 'b00)
                        STAT_TRIGOUTACKWAIT <= 1'b1;
                    else if (use_trigout && !trig_out_ack && trigout_type == 'b10)
                        STAT_TRIGOUTACKWAIT <= 1'b1;
                    else 
                        STAT_TRIGOUTACKWAIT <= 1'b0;
                end

                DONE_ST: begin
                    DONE <= 1;
                    STAT_DONE <= !link_en ? 1 : 0;
                 end    
             //  WAIT : cmd_done_stop <= 1;
               
               

                PAUSED: begin
                    STAT_RESUMEWAIT <= !resume_cmd ? 1 : 0;
                    STAT_PAUSED <= 1;
                end
            endcase
        end
    end

endmodule

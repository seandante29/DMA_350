
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module data_fsm #(
    parameter ADDR_W = 32,
    parameter DATA_W = 128,
    parameter ID_W   = 4
)(
    input  wire              clk,
    input  wire              resetn,
    input  wire              stat_error_intr_reg,// from internal reg
    input wire               stat_error_partsel,
    input  wire              stat_done_intr_reg,// from internal reg
    input  wire              link_en,        // from part select
    // Control
    input  wire              enable_cmd_partsel,
    input  wire              pause_cmd_partsel,
    input  wire              resume_cmd_partsel,
    input  wire              disable_cmd_partsel,
    input  wire              stop_cmd_partsel,      // from internal reg
    input wire               stat_disable_intr_reg,
    input wire               stat_stop_intr_reg,
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

    // Config// from part select
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

//
    output reg [31:0] SRCADDR_UPDATED,
    output reg [31:0]  DESADDR_UPDATED,
    output reg [31:0]  XSIZE_UPDATED,
    output reg wr_en_for_updated,
    
    // Error flags
    output reg               config_error,
    output reg               ard_error,
    output reg               arpoison_error,
    output reg               awr_error,
    output reg               bus_error,
    output reg               regvalerr,
    output wire             cmd_done_stop,
    output reg               ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA,// FROM DATA FSM TO INTERNAL REGISTER 
    output reg               STAT_STOP_DATA, STAT_DISABLE_DATA, STAT_RESUMEWAIT_DATA, 
    output reg               STAT_TRIGOUTACKWAIT_DATA, STAT_SRCTRIGINWAIT_DATA, 
    output reg               STAT_DESTRIGINWAIT_DATA, STAT_PAUSED_DATA, STAT_DONE_DATA
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

    reg case1,case2,case3,case4,case5,case6;
//    wire case1 = (srcxsize == 0 && desxsize == 0);
//    wire case2 = (srcxsize == 0 && desxsize > 0);
//    wire case3 = (srcxsize > 0 && desxsize == 0);
//    wire case4 = (srcxsize == desxsize && srcxsize > 0);
//    wire case5 = ((srcxsize > desxsize) && (desxsize != 0));
//    wire case6 = ((srcxsize < desxsize) && (srcxsize !=0));
    assign cmd_done_stop = (state == WAIT) ? 1 : 0;

  assign ERROR    = config_error || ard_error || arpoison_error || awr_error || bus_error;
 //   assign trig_err = SRCTRIGINSELERR || DESTRIGINSELERR || TRIGOUTSELERR;

always @(*)
begin
 wr_en_for_updated =(state > CONFIG && state < TRIG_OUT);
 SRCADDR_UPDATED = SRCADDR_UPDATED;
DESADDR_UPDATED = DESADDR_UPDATED;
XSIZE_UPDATED = {des_left,src_left};
 if(state == CONFIG)
 begin
SRCADDR_UPDATED = src_addr_reg;
DESADDR_UPDATED = des_addr_reg;
//XSIZE_UPDATED = {desxsize,srcxsize};
XSIZE_UPDATED = {des_left,src_left};
end

else if(state == R) begin
   // wr_en_for_updated = 1;
    XSIZE_UPDATED = {des_left,src_left};
  // XSIZE_UPDATED[15:0] = src_left;
    if(src_xaddr_inc == 0)
        SRCADDR_UPDATED = src_addr_reg;
     else if(src_xaddr_inc == 1)
     begin
        SRCADDR_UPDATED = src_addr_reg + ((ARLEN - src_left) * transize);
     end
     else
         SRCADDR_UPDATED =  SRCADDR_UPDATED ;
 end
      
 else if(state == WRAP_FILL) begin
 XSIZE_UPDATED = {des_left,src_left};
    //wr_en_for_updated =1;
    SRCADDR_UPDATED = src_addr_reg + ((wrap_rd_ptr) * transize);
 end
 else if(state == W) begin
  //wr_en_for_updated =1;
  XSIZE_UPDATED = {des_left,src_left};
   // XSIZE_UPDATED[31:16] = des_left;
    if(des_xaddr_inc == 0)
        DESADDR_UPDATED = des_addr_reg;
     else if(des_xaddr_inc == 1)
     begin
        DESADDR_UPDATED = des_addr_reg + ((AWLEN - des_left) * transize);
     end
     else
         DESADDR_UPDATED =  DESADDR_UPDATED ;
         end
  //else
   //wr_en_for_updated =0;
 end






    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            state <= IDLE;
        else
            state <= next;
    end

        
    // Next State Logic
    always @(*) begin
        next = state;
        if (stop_cmd_partsel) begin
            next = IDLE;
        end else begin
        
        
            case (state)
                IDLE:
                    if (enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA)
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
                    else if (pause_cmd_partsel)
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
                    if (resume_cmd_partsel)
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
            {ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA, STAT_STOP_DATA, STAT_DISABLE_DATA, STAT_RESUMEWAIT_DATA,
             STAT_TRIGOUTACKWAIT_DATA, STAT_SRCTRIGINWAIT_DATA, STAT_DESTRIGINWAIT_DATA, STAT_PAUSED_DATA, STAT_DONE_DATA} <= 'b0;

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
            STAT_RESUMEWAIT_DATA <= 'd0;
            STAT_PAUSED_DATA <= 'd0;
             if( stat_disable_intr_reg == 0)begin
                         ENABLECMD_DATA    <= 0;
                        STAT_DISABLE_DATA  <= 0;
                         DISABLECMD_DATA <= 0;
                end
            if(stat_stop_intr_reg == 0) begin
                 ENABLECMD_DATA    <= 0;
                STAT_STOP_DATA    <= 0;
                STOPCMD_DATA <= 0;
            end
            if (disable_cmd_partsel) begin
                ENABLECMD_DATA    <= 1;
                DISABLECMD_DATA <= 1;
                STAT_DISABLE_DATA <= 1;
            end
            if (stop_cmd_partsel) begin
                ENABLECMD_DATA    <= 1;
                STAT_STOP_DATA    <= 1;
                STOPCMD_DATA <= 1;
                DONE <= 1;// after stop cmd the current command will not excuted and goes for next command after stat_stop is cleared 
                
            end
            STAT_DONE_DATA <= stat_done_intr_reg ? STAT_DONE_DATA:0 ;
//data_done <=0;
            case (state)
                IDLE: begin
                    if (stat_error_intr_reg == 0) begin
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
            WAIT : begin
                case1 <= (srcxsize == 0 && desxsize == 0);
                case2 <= (srcxsize == 0 && desxsize > 0);
                case3 <= (srcxsize > 0 && desxsize == 0);
                case4 <= (srcxsize == desxsize && srcxsize > 0);
                case5 <= ((srcxsize > desxsize) && (desxsize != 0));
                case6 <= ((srcxsize < desxsize) && (srcxsize !=0));
                
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
                            STAT_SRCTRIGINWAIT_DATA <= 1'b1;
                            STAT_DESTRIGINWAIT_DATA <= 1'b1;				
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
                    if (WREADY && des_left > 0 && WVALID) begin
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
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else if (use_trigout && !trig_out_ack && trigout_type == 'b10)
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else 
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
                end

                DONE_ST: begin
                    DONE <= 1;
                    STAT_DONE_DATA <= !link_en ? 1 : 0;
                 end    
             //  WAIT : cmd_done_stop <= 1;
               
               

                PAUSED: begin
                    STAT_RESUMEWAIT_DATA <= !resume_cmd_partsel ? 1 : 0;
                    STAT_PAUSED_DATA <= 1;
                end
            endcase
        end
    end

endmodule

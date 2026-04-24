module data_fsm #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter ID_W   = 4
)(
    input  wire                 clk,
    input  wire                 resetn,
    input  wire                 stat_error_intr_reg,
    input  wire                 stat_done_intr_reg,
    input  wire                 link_en,
    input  wire                 LINKHDERR,
    
    // Control
    input  wire                 enable_cmd_partsel,
    input  wire                 pause_cmd_partsel,
    input  wire                 resume_cmd_partsel,
    input  wire                 disable_cmd_partsel,
    input  wire                 stop_cmd_partsel,
    input wire                  stop_cmd_apb,
    input  wire                 stat_disable_intr_reg,
    input  wire                 stat_stop_intr_reg,
    input  wire                 cmd_done,

    // Triggers
    
    input  wire                 use_src_trigin,
    input  wire [1:0]           src_trigin_type,
    input  wire [1:0]           src_trigin_mode,
    input  wire [7:0]           src_trigin_blk_size,
    input  wire [7:0]           src_trigin_sel,
    
    input  wire                 use_des_trigin,
    input  wire [1:0]           des_trigin_type,
    input  wire [1:0]           des_trigin_mode,
    input  wire [7:0]           des_trigin_blk_size,
    input  wire [7:0]           des_trigin_sel,
    
    input  wire                 use_trigout,
    input  wire [1:0]           trigout_type,
    input  wire [5:0]           trigout_sel,
    
    input  wire                 src_trigin_sw,
    input  wire                 des_trigin_sw,
    input  wire                 trig_out_ack_sw,
    
input wire [1:0] src_trigin_sw_type,des_trigin_sw_type,
    input  wire                 src_trigin,
    input wire  [1:0]           src_trig_req_type,
    input  wire                 des_trigin,
    input wire  [1:0]           des_trig_req_type,
    output reg                  src_trigack,
    output reg [1:0]            src_trigack_type, 
    output reg                  des_trigack,
    output reg [1:0]            des_trigack_type,
    output reg                  trig_out_req,
    input  wire                 trig_out_ack,



    //
    input wire cmd_restart_en,//
    input wire [15:0] cmd_restart_cnt,//
    input wire [2:0] reg_reload_type,//
    input wire [2:0] done_type,
    input wire done_pause_en,
    
    // Config
    input  wire [ADDR_W-1:0]    SRC_ADDR,
    input  wire [ADDR_W-1:0]    des_ADDR,
    input  wire [2:0]           transize,
    input  wire [15:0]          srcx_transfer_count,
    input  wire [15:0]          desx_transfer_count,
    input  wire [2:0]           x_type,
    input wire  [2:0]           y_type,
    input  wire [31:0]          fillval,
    input  wire [15:0]          src_xaddr_inc,
    input  wire [15:0]          des_xaddr_inc,
    input  wire [3:0]           src_max_burst_len,
    input  wire [3:0]           des_max_burst_len,



    // template
    
    input wire [4:0] des_tmplt_size,
    input wire [4:0] src_tmplt_size,
    input wire [31:0] des_tmplt,
    input wire [31:0] src_tmplt,
    
    // AXI READ
    input  wire                 ARREADY,
    output reg                  ARVALID,
    output reg  [ADDR_W-1:0]    ARADDR,
    output reg  [2:0]           ARSIZE,
    output reg  [1:0]           ARBURST,
    output reg  [ID_W-1:0]      ARID,
    output reg  [7:0]           ARLEN,
    output reg  [3:0]        ARQOS,
    
    input  wire [ID_W-1:0]      RID,
    input  wire                 RVALID,
    input  wire [DATA_W - 1 :0] RDATA,
    input  wire [1:0]           RRESP,
    input  wire                 RLAST,
    output reg                  RREADY,
    
    // AXI WRITE
    input  wire                 AWREADY,
    output reg                  AWVALID,
    output reg  [ADDR_W-1:0]    AWADDR,
    output reg  [2:0]           AWSIZE,
    output reg  [1:0]           AWBURST,
    output reg  [ID_W-1:0]      AWID,
    output reg  [7:0]           AWLEN,
    output reg [3:0]            AWQOS,
    
    input  wire                WREADY,
    output reg                WVALID,
    output reg [DATA_W-1:0]    WDATA,
    output wire                 WLAST,// changed to wire
    output [(DATA_W/8)-1:0]    WSTRB,
    
    input wire [ID_W-1:0]       BID,
    input  wire                 BVALID,
    input  wire [1:0]           BRESP,
    output reg                  BREADY,
    
    // Status
    output reg                  DONE,
    output reg  [31:0]          read_base_addr_UPDATED,
    output reg  [31:0]          write_base_addr_UPDATED,
    output reg  [31:0]          x_transfer_count_UPDATED,y_transfer_count_UPDATED,
    output reg                  wr_en_for_updated,
    
    output reg [31:0]          read_base_addr_INITIAL,read_base_addr_LINEINITIAL,
    output reg [31:0]          write_base_addr_INITIAL,write_base_addr_LINEINITIAL,
    output wire [31:0]          SRCx_transfer_count_INITIAL,
    output wire [31:0]          DESx_transfer_count_INITIAL,
    output wire [31:0]          SRCy_transfer_count_INITIAL,
    output wire [31:0]          DESy_transfer_count_INITIAL,

    // Error flags
    
    output wire                 config_error,
    output reg                  ard_error,
    output reg                  arpoison_error,
    output reg                  awr_error,
    output wire                  bus_error,
    output wire                 regvalerr,
    output reg                  ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA,
    output reg                  STAT_STOP_DATA, STAT_DISABLE_DATA, STAT_RESUMEWAIT_DATA, 
    output reg                  STAT_TRIGOUTACKWAIT_DATA, STAT_SRCTRIGINWAIT_DATA, 
    output reg                  STAT_DESTRIGINWAIT_DATA, STAT_PAUSED_DATA, STAT_DONE_DATA,
      input wire [15:0] src_yaddr_stride, //
   input wire [15:0] des_yaddr_stride,
   input wire [15:0] src_y_transfer_count, //
   input wire [15:0] des_y_transfer_count  
);
    //integer _integer,des_x_left_initial_integer;
    reg [31:0]    initial_tmplt_addr_src,initial_tmplt_addr_des;
    reg [31:0]write_base_addr_UPDATED_wire;
     wire [(DATA_W/8)-1:0] WSTRB_wire,WSTRB_COMB;
    wire [6:0] transize_power = (2**transize) + write_base_addr_UPDATED_wire;
    reg [15:0] restart_cnt_reg;
    wire       ERROR;
       wire  [DATA_W-1:0] prev_WDATA = WDATA;
    wire [15:0] src_xaddr_inc_sign, des_xaddr_inc_sign; 
    reg [4:0] count_src_tmplt;//
    reg [4:0] count_des_tmplt;//
    wire [15:0] src_yaddr_stride_signed;
    wire [15:0] des_yaddr_stride_signed;
    // multiple reads
    reg [15:0] src_x_transfer_count_remaining,src_y_transfer_count_remaining;   
    reg [15:0] des_x_transfer_count_remaining,des_y_transfer_count_remaining, des_x_transfer_count_remaining_2d; 
    reg [1:0] src_trig_req_type_reg;
    reg [1:0] des_trig_req_type_reg;
    //
 reg [1:0] des_trigin_sw_type_reg,src_trigin_sw_type_reg;
    reg        reg1, reg2;
    reg        cmd_done_reg;
    reg [15:0] src_x_left, des_x_left, fill_count,fill_count_y, src_y_left, des_y_left,r1;
    reg [15:0] src_x_left_initial, des_x_left_initial;
    reg [15:0] src_x_addr_inital, des_x_addr_initial;
    reg [7:0]  wrap_rd_ptr;
    reg [DATA_W-1:0] wdata_mask;
    integer    i;
    reg [15:0] srcx_transfer_count_reg, desx_transfer_count_reg;
    reg [15:0] srcy_transfer_count_reg, desy_transfer_count_reg;  
    reg [15:0] srcx_transfer_count_initial_reg, desx_transfer_count_initial_reg; 

    reg [DATA_W - 1:0] fifo_mem [0:31];
    reg [5:0]   fifo_wptr;
    reg [5:0]   fifo_rptr;
    integer     j,k,p;
    
    reg [4:0] m,l;

    reg config_error_size, config_error_src, config_error_des, config_error_trigout,config_error_transize;
    reg config_error_inc, config_error_x_type, config_error_case3, config_error_case6;
    reg regvalerr_src, regvalerr_des, regvalerr_trigout;

    reg [ADDR_W-1:0] src_addr_reg, des_addr_reg;
    reg case1,case2,case3,case4,case5,case6;  // chnaged from wire to reg
     reg ycase1, ycase2, ycase3, ycase4, ycase5;
     reg [31:0] area_src, area_des; 
     
     wire [5:0] fifo_rptr_t = fifo_rptr[4:0] + 1;
    localparam RD_IDLE       = 5'd0,
               RD_WAIT       = 5'd1,
               RD_CONFIG     = 5'd2,
               RD_WAIT_TRIG  = 5'd3,
               RD_AR         = 5'd4,
               RD_R          = 5'd5,
               RD_WRAP_FILL  = 5'd6,
               RD_ERROR_ST   = 5'd7,
               RD_PAUSED     = 5'd8,
               RD_ROWS       = 5'd17;
    
    localparam W_IDLE        = 5'd9,
               W_AW          = 5'd10,
               W_W           = 5'd11,
               W_B           = 5'd12,
               W_TRIG_OUT    = 5'd13,
               W_DONE_ST     = 5'd14,
               W_ERROR_ST    = 5'd15,
               W_PAUSED      = 5'd16,
               W_ROWS        = 5'd18;
    reg [4:0] rd_state, wr_state, wr_next_st, rd_next_st,wr_pause_state, rd_pause_state;
    
    localparam STRB_W = DATA_W / 8;
    wire [DATA_W-1:0] strobe_mask;
   wire [31:0]wire_11;
 assign wire_11 = write_base_addr_UPDATED_wire + 2** transize; 
// assign WLAST = (des_x_left == 1)?1:0;
genvar a;
generate
    for (a = 0; a < STRB_W; a = a + 1) begin : GEN_STROBE_MASK
        assign strobe_mask[a*8 +: 8] = (wr_state == W_W /*&& fifo_rptr == 0*/ && !(WVALID && WREADY))?{8{WSTRB[a]}}:{8{WSTRB_wire[a]}};
    end
endgenerate
    
    wire full =( (fifo_wptr +1)  == {~fifo_rptr[5],fifo_rptr[4:0]});
    wire empty = ((fifo_wptr == fifo_rptr)||(WVALID && WREADY &&(fifo_wptr == fifo_rptr+1))) ? 1 : 0;
     wire ycase1_wire = ((srcx_transfer_count == 0 || src_y_transfer_count == 0) &&
                                       (!(desx_transfer_count > 0 && des_y_transfer_count > 0)));
                        
                        //write only
           wire  ycase2_wire = (!ycase1_wire) &&
                                       ((srcx_transfer_count == 0)||(src_y_transfer_count ==0)) &&
                                       (desx_transfer_count > 0) && (des_y_transfer_count > 0);
                        
                        //read only
           wire  ycase3_wire = (!ycase1_wire) &&
                                       ((desx_transfer_count == 0)||(des_y_transfer_count == 0)) &&
                                       (srcx_transfer_count > 0) && (src_y_transfer_count > 0);
                        
                        //1d to 1d
            wire    ycase4_wire = (!ycase1_wire && !ycase2_wire && !ycase3_wire) &&
                                       (srcx_transfer_count > 0 && src_y_transfer_count == 1) &&
                                       (desx_transfer_count > 0 && des_y_transfer_count == 1);
                        
   
   wire test_ycase =!(ycase1_wire || ycase2_wire || ycase3_wire || ycase4_wire);
   
   
    reg [4:0] wr_pause_state_q;
    reg [4:0] rd_pause_state_q;
   
    reg DONE_temp;
    reg [15:0]src_x_transfer_count_reload,des_x_transfer_count_reload,src_y_transfer_count_reload,des_y_transfer_count_reload;
    reg [31:0] src_addr_reload,des_addr_reload;
    reg [15:0] src_yaddr_stride_reg; //not using
     reg [15:0] des_yaddr_stride_reg; //not using
    
    assign config_error = config_error_size | config_error_src | config_error_des | config_error_trigout | 
                          config_error_inc | config_error_x_type | config_error_case3 | config_error_case6 | config_error_transize;
    assign regvalerr    = regvalerr_src | regvalerr_des | regvalerr_trigout;
    assign ERROR        = config_error || ard_error || arpoison_error || awr_error || bus_error;
    
//    assign read_base_addr_INITIAL  = src_addr_reg;
//    assign write_base_addr_INITIAL  = des_addr_reg;
    assign SRCx_transfer_count_INITIAL = {16'd0, srcx_transfer_count_initial_reg};
    assign DESx_transfer_count_INITIAL = {16'd0, desx_transfer_count_reg};
    assign SRCy_transfer_count_INITIAL = {16'd0, srcy_transfer_count_reg};
    assign DESy_transfer_count_INITIAL = {16'd0, desy_transfer_count_reg};     
    assign src_xaddr_inc_sign = $signed(src_xaddr_inc);
    assign des_xaddr_inc_sign = $signed(des_xaddr_inc);
    assign src_yaddr_stride_signed = $signed(src_yaddr_stride);
    assign des_yaddr_stride_signed = $signed(des_yaddr_stride);
    
 //   assign WLAST = (wr_state == W_W) ? ((des_x_left == 1)? 1 : 0) : 0;
  assign WLAST = (wr_state == W_W && WVALID) ? ((des_x_transfer_count_remaining_2d - AWLEN) == des_x_left ? 1 : 0) : 0;
  wire  WVALID_wire = ((empty) ||(WREADY && WLAST)||(stop_cmd_apb)||(wr_state != W_W)) ? 0 : 1;
    assign WSTRB = (wr_state == W_W) ? ((1 << (1 << transize)) - 1)<< write_base_addr_UPDATED_wire[$clog2(DATA_W/8)-1:0] : 0;
    assign WSTRB_wire = (wr_next_st == W_W) ? ((1 << (1 << transize)) - 1)<< wire_11[$clog2(DATA_W/8)-1:0] : 0;
     always@(*) begin
        write_base_addr_UPDATED_wire = des_addr_reg;
        if(wr_state == W_W  && des_x_left !=0)
         begin 
            if(WREADY)
                begin
                    if(des_xaddr_inc == 1)
                        write_base_addr_UPDATED_wire = des_addr_reg + ((desx_transfer_count_reg - des_x_left) * ( 2**transize));
                        
                 end
            else
                    write_base_addr_UPDATED_wire =  write_base_addr_UPDATED;
         end
        else
            write_base_addr_UPDATED_wire =  des_addr_reg;
        end        
   

    reg       bus_error_w, bus_error_r, done_signal, wr_start;
    assign bus_error = bus_error_r |bus_error_w;
       integer q;
       reg [31:0] k1,p1;
       
       //seq for combo infered latch
always@(posedge clk or negedge resetn)
begin
if(!resetn)
        begin
p1<=0;
k1<= 0;
end
else begin
p1<= p;
k1 <= k;
end
end

always @(*) begin
    k = 0;

    if (rd_state == RD_CONFIG) begin
        for (q = 0; q < 32; q = q + 1) begin
            if ((q <= src_tmplt_size) && src_tmplt[q]) begin
                k = q;  // keeps updating ? highest index wins
            end
            else 
                k = k1;//added
        end
    end
end
      integer d;

always @(*) begin
    p = 0;  // default

    if (rd_state == RD_CONFIG) begin
        for (d = 0; d < 32; d = d + 1) begin
            if ((d <= des_tmplt_size) && des_tmplt[d]) begin
                p = d;  // highest index wins
            end
            else 
                p = p1;
        end
    end
end
//      always@(*) begin
//      if(rd_state == RD_R )
//      for (m=0; m < src_tmplt_size; m=m+1)                         
//        if(RLAST && src_tmplt[m] == 0)
//            m = m + 1;
//      end
    //
    always @(posedge clk or negedge resetn)  //  diFFERENT FROM V1
    begin
        if(!resetn)
        begin
            wr_en_for_updated <= 'd0;
            read_base_addr_UPDATED <= 'd0;
            write_base_addr_UPDATED <= 'd0;
            x_transfer_count_UPDATED <= 'd0;
            y_transfer_count_UPDATED <= 0;
          //  src_yaddr_stride_reg <='d0;
        end
        else begin
            wr_en_for_updated <=(rd_state > RD_CONFIG && rd_state <= RD_PAUSED);
            read_base_addr_UPDATED <= read_base_addr_UPDATED;
            write_base_addr_UPDATED <= write_base_addr_UPDATED;
            //x_transfer_count_UPDATED <= (case6 && x_type == 2)?(src_x_transfer_count_remaining == 0 && src_x_left <= srcx_transfer_count_reg && src_x_left!=0)?x_transfer_count_UPDATED:(src_x_transfer_count_remaining>=src_x_left)?({des_x_left,src_x_left}):{des_x_left,srcx_transfer_count_reg-((desx_transfer_count_reg -src_x_left)%srcx_transfer_count_reg)}
            //                : (case6 && x_type == 1)? {(des_x_left+(desx_transfer_count_reg - srcx_transfer_count_reg)),src_x_left}:{des_x_left,src_x_left};// src_x_left-(desx_transfer_count_reg - srcx_transfer_count_reg)
            if (case6 && x_type == 2 && !DONE_temp) begin
                if (src_x_transfer_count_remaining == 0 && src_x_left <= srcx_transfer_count_reg && src_x_left != 0) begin
                    x_transfer_count_UPDATED <= x_transfer_count_UPDATED;
                end
                else if (src_x_transfer_count_remaining >= src_x_left) begin
                    x_transfer_count_UPDATED <= {des_x_left, src_x_left};
                end
                else begin
                    x_transfer_count_UPDATED <= {des_x_left,
                                      srcx_transfer_count_reg - ((desx_transfer_count_reg - src_x_left) % srcx_transfer_count_reg)};
                end
            end
            
            else if (case6 && x_type == 1) begin
                x_transfer_count_UPDATED <= {des_x_left + (desx_transfer_count_reg - srcx_transfer_count_reg), src_x_left};
            end
            else if((cmd_restart_en || restart_cnt_reg != 0) && (src_x_left == 0 && DONE_temp) && (reg_reload_type != 0))
                 x_transfer_count_UPDATED <= {des_x_transfer_count_reload,src_x_transfer_count_reload};
            else begin
                x_transfer_count_UPDATED <= {des_x_left, src_x_left};
            end 
            //y_transfer_count
            if (case6 && y_type == 2 && !DONE_temp) begin
                if (src_y_transfer_count_remaining == 0 && src_y_left <= srcy_transfer_count_reg && src_y_left != 0) begin
                    y_transfer_count_UPDATED <= y_transfer_count_UPDATED;
                end
                else if (src_y_transfer_count_remaining >= src_y_left) begin
                    y_transfer_count_UPDATED <= {des_y_left, src_y_left};
                end
                else begin
                    y_transfer_count_UPDATED <= {des_y_left,
                                      srcy_transfer_count_reg - ((desy_transfer_count_reg - src_y_left) % srcy_transfer_count_reg)};
                end
            end
            
            else if (case6 && x_type == 1) begin
                y_transfer_count_UPDATED <= {des_y_left + (desy_transfer_count_reg - srcy_transfer_count_reg), src_y_left};
            end
            else if((cmd_restart_en || restart_cnt_reg != 0) && (src_y_left == 0 && DONE_temp) && (reg_reload_type != 0))
                 y_transfer_count_UPDATED <= {des_y_transfer_count_reload,src_y_transfer_count_reload};
            else begin
                y_transfer_count_UPDATED <= {des_y_left, src_y_left};
            end 
            
            if(rd_state == RD_WAIT_TRIG)
            begin
                read_base_addr_UPDATED <= src_addr_reg;
                //write_base_addr_UPDATED <= des_addr_reg;
            end
            else if(rd_state ==  RD_R && src_x_left !=0) begin
                if(RVALID) begin
                    if(src_xaddr_inc == 1)
                    begin
                        read_base_addr_UPDATED <= (case6 && x_type == 2) ? (src_x_left>(desx_transfer_count_reg - srcx_transfer_count_reg)) ? (src_addr_reg + ((srcx_transfer_count_reg +1  - (src_x_left-(desx_transfer_count_reg - srcx_transfer_count_reg))) *( 2**transize)*(src_xaddr_inc_sign))) 
                                                    : src_addr_reg +((desx_transfer_count_reg + 1 -src_x_left)%srcx_transfer_count_reg)
                                                    :src_addr_reg + ((srcx_transfer_count_reg - src_x_left +1) *( 2**transize)*(src_xaddr_inc_sign)) ;
                    end
                    else
                        read_base_addr_UPDATED <=  src_addr_reg;
                end
            end 
            
            if(wr_state == W_W  && des_x_left !=0) begin 
                if(WREADY)
                    if(des_xaddr_inc == 1)
                    begin
                        write_base_addr_UPDATED <= des_addr_reg + ((desx_transfer_count_reg - des_x_left+1) * (( 2**transize)*des_xaddr_inc_sign));
                    end
                    else
                        write_base_addr_UPDATED <=  des_addr_reg;
                else write_base_addr_UPDATED <= write_base_addr_UPDATED;
            end 
            
        end
    end
    
    
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin 
            {ENABLECMD_DATA, DISABLECMD_DATA, STOPCMD_DATA, STAT_STOP_DATA, STAT_DISABLE_DATA,STAT_DONE_DATA,STAT_PAUSED_DATA,STAT_RESUMEWAIT_DATA} <= 'b0;
            
        end else begin 
            if ((disable_cmd_partsel && wr_state == W_DONE_ST) || stop_cmd_apb)
                ENABLECMD_DATA <= 1;
            else  
                ENABLECMD_DATA <= 0;
            
            if (disable_cmd_partsel) begin
                DISABLECMD_DATA <= 1;
                STAT_DISABLE_DATA <= 1;
            end else if(stat_disable_intr_reg == 0) begin
                STAT_DISABLE_DATA <= 0;
                DISABLECMD_DATA <= 0;
            end
            
            if (stop_cmd_apb) begin
                STAT_STOP_DATA <= 1;
                STOPCMD_DATA <= 1;
            end else if(stat_stop_intr_reg == 0) begin
                STAT_STOP_DATA <= 0;
                STOPCMD_DATA <= 0;
            end
            if(wr_state == W_PAUSED && rd_state == RD_PAUSED) begin
                STAT_PAUSED_DATA <= 1;
                STAT_RESUMEWAIT_DATA <= 1;
            end
            else begin
                STAT_PAUSED_DATA <= 0;
                STAT_RESUMEWAIT_DATA <= 0;
            end
            if(wr_state == W_DONE_ST)
                STAT_DONE_DATA <= (done_type == 0)? 0 : 
                                       (done_type == 1)? 1:
                                       (done_type == 3)? (1 & (cmd_restart_en || restart_cnt_reg>0)):0;
//    STAT_DONE_DATA <= !(link_en || cmd_restart_en || restart_cnt_reg >0 ) ? 1 : 0;
            else
                STAT_DONE_DATA <= stat_done_intr_reg ? STAT_DONE_DATA : 0;
        end
    end


always @(posedge clk or negedge resetn) begin
    if(!resetn) begin
        rd_state           <= RD_IDLE;
        wr_state           <= W_IDLE;
        rd_pause_state_q   <= RD_IDLE;
        wr_pause_state_q   <= W_IDLE;
    end 
    else begin
        // State updates
        rd_state <= rd_next_st;
        wr_state <= wr_next_st;

        // Pause tracking (store last non-paused state)
        if (rd_next_st != RD_PAUSED)
            rd_pause_state_q <= rd_next_st;

        if (wr_next_st != W_PAUSED)
            wr_pause_state_q <= wr_next_st;
    end
end
 

    always @(*) begin
       // rd_pause_state =(rd_next_st != RD_PAUSED )? rd_next_st :rd_pause_state_q; 
        rd_next_st = rd_state;
        if (stop_cmd_apb) begin
            rd_next_st = RD_IDLE;
        end
        else if(pause_cmd_partsel || (STAT_DONE_DATA && done_pause_en))begin
            rd_next_st = RD_PAUSED;
        end else begin
            case (rd_state)
                RD_IDLE:
                    if (wr_state == W_IDLE && !wr_start && enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA) begin
                        if(LINKHDERR)  
                            rd_next_st = RD_IDLE;
                        else
                            rd_next_st = RD_WAIT;
                    end else
                        rd_next_st = RD_IDLE;
                        
                RD_PAUSED:
                    if(resume_cmd_partsel)
                            rd_next_st = rd_pause_state_q;
            
                RD_WAIT: 
                    if (stat_error_intr_reg) 
                        rd_next_st = RD_ERROR_ST;
                    else 
                        rd_next_st = reg2 ? RD_CONFIG : RD_WAIT;
            
                RD_CONFIG: begin
                  
                    if (config_error)
                        rd_next_st = RD_ERROR_ST;
                    else if (case1 || x_type == 0 || (ycase1 && y_type != 0) )
                        rd_next_st = RD_IDLE;
                    else if (case2)
                        rd_next_st = (x_type == 3) ? RD_WAIT_TRIG : RD_ERROR_ST; 
                     else if(ycase2)
                        rd_next_st = ((x_type == 3 && y_type == 3) ) ? RD_WAIT_TRIG : RD_ERROR_ST;
                   else if(ycase3)
                        rd_next_st = RD_WAIT_TRIG;
                    else if (case3)
                        rd_next_st = RD_ERROR_ST;
                    else if (case6)
                        rd_next_st = (x_type == 0) ? RD_IDLE : RD_WAIT_TRIG;
                    else
                        rd_next_st = RD_WAIT_TRIG;
                end
            
                RD_WAIT_TRIG:
                begin
                    
                    if (config_error)
                        rd_next_st = RD_ERROR_ST;
                    else if (pause_cmd_partsel)
                        rd_next_st = RD_PAUSED;
                    else if (use_src_trigin && use_des_trigin) begin  
                        if (((src_trigin_type == 2'b00 && src_trigin_sw)||(src_trigin_type == 2'b10 && src_trigin)) &&
                        ((des_trigin_type == 2'b00 && des_trigin_sw)||(des_trigin_type == 2'b10 && des_trigin)))
                            rd_next_st = (case2 && x_type == 'd3) ? RD_WRAP_FILL : RD_AR;  
                    end    
                    else if (!use_src_trigin && !use_des_trigin)
                            rd_next_st =  RD_AR;  
                    else if(!use_src_trigin && use_des_trigin) begin
                        if ((des_trigin_type == 2'b00 && des_trigin_sw)||(des_trigin_type == 2'b10 && des_trigin))
                     rd_next_st = (case2 && x_type == 'd3) ? RD_WRAP_FILL : RD_AR;
                    end
                    else if(!use_des_trigin && use_src_trigin) begin
                         if ((src_trigin_type == 2'b00 && src_trigin_sw)||(src_trigin_type == 2'b10 && src_trigin)) 
                            rd_next_st = (case2 && x_type == 'd3) ? RD_WRAP_FILL : RD_AR;
                    end
                    else
                            rd_next_st = RD_WAIT_TRIG;
                end
                
                RD_AR:
                begin
               
                    if (ARVALID && ARREADY) begin
                        if(src_tmplt [m] == 1 || src_tmplt_size == 0) 
                        rd_next_st = RD_R;
                        end
                    else
                        rd_next_st = RD_AR;
                end
                
                RD_R:
                    if ((RRESP == 2 || RRESP == 3) && RVALID)
                        rd_next_st = RD_ERROR_ST;
                    else if (RVALID && RREADY && RLAST) begin    // diFFERENT FROM V1
                    
//                        if(count_src_tmplt > 0)//
//                            rd_next_st = RD_AR;
                         if(src_x_left > 'd1)
                            rd_next_st = RD_AR;
                      //  else if(ycase5 && ((((srcx_transfer_count_reg * srcy_transfer_count_reg)% desx_transfer_count_reg ) != 0) && x_type == 1) && srcx_transfer_count_reg > desx_transfer_count_reg && ((srcy_transfer_count_reg * srcy_transfer_count_reg) == fifo_rptr))
                        //    rd_next_st <= RD_IDLE;
                        else if (( fill_count > 1) && ( (x_type == 3) && (case6  || case2)))
                            rd_next_st = RD_WRAP_FILL;
                       
                            
                         else if((cmd_restart_en || restart_cnt_reg != 0))
                          rd_next_st = RD_R; 
                         else if((src_y_left > 0) &&(src_tmplt_size == 0))
                          rd_next_st  = RD_ROWS;
                         else
                        rd_next_st = RD_IDLE;      
                        end   
                    else if((cmd_restart_en || restart_cnt_reg != 0))begin
                            rd_next_st = RD_R;
                            if((src_x_left == 0 && DONE_temp))
                                rd_next_st = RD_WAIT; 
                            end   
                    else
                        rd_next_st = RD_R;
                        
                RD_WRAP_FILL:
                   
                    if((cmd_restart_en || restart_cnt_reg != 0)) 
                    begin
                        rd_next_st = RD_WRAP_FILL;
                        if (((src_x_left == 0) && (fill_count == 0)) && DONE_temp )
                            rd_next_st = RD_WAIT; 
                    end
                      else if(src_x_left == 0 && src_y_left > 0 && fill_count == 0)
                            rd_next_st = RD_ROWS;
                       
                     else if (src_x_left == 0 && fill_count == 0 && fill_count_y == 0)
                        rd_next_st = RD_IDLE;
                      else
                        rd_next_st = RD_WRAP_FILL;
                
                RD_ERROR_ST:
                    rd_next_st = RD_IDLE;
                    
                RD_ROWS:
                begin
                if(src_y_left > 1)
                   rd_next_st = RD_AR;
                else if  (( fill_count_y > 0) && ( (y_type == 3) && (ycase2  || ycase5)))
                    rd_next_st = RD_WRAP_FILL;
                else 
                   rd_next_st = RD_IDLE;
                end
                
            
                default: rd_next_st = RD_IDLE;
            endcase
        end
    end

// Next State Logic
    always @(*) begin
    // wr_pause_state = (wr_next_st  != W_PAUSED )? wr_next_st :wr_pause_state_q; 
        wr_next_st = wr_state;
        if (stop_cmd_apb) begin
            wr_next_st = W_IDLE;
        end 
        else if(pause_cmd_partsel /*|| (STAT_DONE_DATA && done_pause_en)*/)begin
            wr_next_st = W_PAUSED;
        end
        else begin
            case (wr_state)
            W_IDLE:
                if (enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA) begin
                    if(done_signal)  
                        wr_next_st = W_DONE_ST;
                    else if(wr_start && !ycase3)
                        wr_next_st = W_AW;
                end
             W_PAUSED:
                    if(resume_cmd_partsel)
                            wr_next_st = (wr_pause_state_q == W_DONE_ST)? W_IDLE : wr_pause_state_q;
             W_AW:
                if (AWVALID && AWREADY)
                    if(des_tmplt [l] == 1 || des_tmplt_size == 0) 
                    wr_next_st = W_W;
            
            W_W:
                if (WREADY && WVALID && WLAST)
                        wr_next_st = W_B;
//                else if(ycase5 && ((((srcx_transfer_count_reg * srcy_transfer_count_reg)% desx_transfer_count_reg ) != 0) && x_type == 1) && srcx_transfer_count_reg > desx_transfer_count_reg && ((srcy_transfer_count_reg * srcy_transfer_count_reg) == fifo_wptr))
//                            wr_next_st = W_IDLE;
                          
            W_B:
                if (BVALID && BREADY)begin
                    if(BRESP < 1) begin
                        if(des_x_left > 'd0)
                            wr_next_st = W_AW;     
                        else if(des_y_left > 0 &&(src_tmplt_size == 0))
                            wr_next_st = W_ROWS;
                        else
                            wr_next_st = W_TRIG_OUT; end
                    else
                        wr_next_st = W_ERROR_ST;end
            W_TRIG_OUT:
                if (!use_trigout)
                    wr_next_st = W_DONE_ST;
                else begin
                    if (trigout_type == 2'b00 && trig_out_ack_sw)
                        wr_next_st = W_DONE_ST;
                    else if (trigout_type == 2'b10 && trig_out_ack)
                        wr_next_st = W_DONE_ST;
                end
            
            W_DONE_ST:
                if(done_pause_en && !resume_cmd_partsel)
                wr_next_st = W_PAUSED;
                else
                wr_next_st = W_IDLE;
            
            W_ERROR_ST:
                wr_next_st = W_IDLE;
            W_ROWS:
            begin
            if(des_y_left>1)
            wr_next_st = W_AW;
//            else
//            wr_next_st = W_IDLE;
            else
            wr_next_st = W_TRIG_OUT;
            end
            
            default: wr_next_st = W_IDLE;
            endcase
        end
    end
    integer r;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            {ARVALID, RREADY, src_addr_reg, wdata_mask,r1,
            ard_error, ARADDR, desx_transfer_count_reg,desy_transfer_count_reg, ARID, ARSIZE,ARQOS, ARBURST, srcx_transfer_count_reg, srcy_transfer_count_reg,ARLEN,src_x_transfer_count_remaining,src_y_transfer_count_remaining,src_trig_req_type_reg,des_trig_req_type_reg,
             arpoison_error, bus_error_r, cmd_done_reg} <= 0;
           {STAT_SRCTRIGINWAIT_DATA, STAT_DESTRIGINWAIT_DATA} <= 'b0;
            {config_error_size, config_error_src,config_error_transize, config_error_des, config_error_trigout, config_error_inc, config_error_x_type, config_error_case3, config_error_case6} <= 'd0;
            {regvalerr_src, regvalerr_des, regvalerr_trigout} <= 'd0;
            {ycase1,ycase2,ycase3,ycase4,ycase5,case1,case2,case3,case4,case5,case6} <=0;
            read_base_addr_INITIAL  <= 0;
            write_base_addr_INITIAL  <= 0;
            write_base_addr_LINEINITIAL <= 0;
            read_base_addr_LINEINITIAL <= 0;
            fill_count_y <= 0;
            src_yaddr_stride_reg <=0;
            r <= 0;
            initial_tmplt_addr_src<=0;
            //rd_pause_state <= RD_IDLE;
            fifo_wptr       <= 0;
          // fifo_rptr       <= 0;
            src_x_left        <= 0;
            src_x_left_initial <= 0;
           // des_x_left_initial <= 0;
            src_x_addr_inital <= 0;
            des_x_addr_initial <= 0;
            fill_count      <= 0;
            wrap_rd_ptr     <= 0;
            src_trigack     <= 0;
            des_trigack     <= 0;
            desx_transfer_count_initial_reg <=0;
            srcx_transfer_count_initial_reg <=0;
            area_src <= 0;
            area_des <= 0;
             src_y_transfer_count_reload <=0;
             src_x_transfer_count_reload <= 0;
             des_x_transfer_count_reload <=0;
             src_addr_reload <= 0;
                   des_addr_reload <= 0;
                   des_y_transfer_count_reload <= 0;
            done_signal <= 0;
            src_trigack_type <= 'd0;
            des_trigack_type <= 'd0;
            wr_start <= 'd0;
            reg1 <= 0;
            m <= 0;
            reg2 <= 0;
            restart_cnt_reg <= 0;
            src_y_left <=0;
           // des_y_left <=0;
            
            for(j=0; j<32; j=j+1) begin
                fifo_mem[j] <= 'd0;
            end
        end else begin
            ARQOS <= 0;
             wr_start <= 'd0;
            ARVALID      <= 0;
            RREADY       <= 0;
            src_trigack  <= 0;
            des_trigack  <= 0;
            cmd_done_reg <= cmd_done;
             write_base_addr_LINEINITIAL <= des_addr_reg;
            read_base_addr_LINEINITIAL <= src_addr_reg;
            reg1 <= 0;
            reg2 <= 0;
//            STAT_RESUMEWAIT_DATA     <= 'd0;
//            STAT_PAUSED_DATA         <= 'd0;
//            STAT_SRCTRIGINWAIT_DATA  <= 1'b0;
//            STAT_DESTRIGINWAIT_DATA  <= 1'b0;
             if( m == src_tmplt_size  )
                   initial_tmplt_addr_src  <= ARADDR + ((src_tmplt_size + 1) - k) *(2**transize);
              else if(rd_state == RD_CONFIG)
                initial_tmplt_addr_src <= src_addr_reg;
                
                  
               // rd_pause_state <=(rd_next_st != RD_PAUSED )? rd_next_st :rd_pause_state; 
            case (rd_state)
                RD_IDLE: begin
                    done_signal <= 0;
                      m <= 0;
                    if (enable_cmd_partsel && cmd_done && !stat_error_intr_reg && !DONE && !stat_disable_intr_reg && !stat_done_intr_reg && !STAT_STOP_DATA) begin
                        if(LINKHDERR) done_signal <= 1;
                    end
                    if (stat_error_intr_reg == 0) begin
                        {config_error_size, config_error_src, config_error_des, config_error_transize, config_error_trigout, config_error_inc, config_error_x_type, config_error_case3, config_error_case6} <= 0;
                        ard_error      <= 0;
                        arpoison_error <= 0;
                        bus_error_r    <= 0;
                        {regvalerr_src, regvalerr_des, regvalerr_trigout} <= 'd0;
                    end
//                    fifo_wptr   <= 0;
                    wrap_rd_ptr <= 0;
                    fill_count  <= 0;
                    ARLEN       <= 0;
                end
                
                RD_WAIT: begin
                    area_src <= srcx_transfer_count * src_y_transfer_count;
                    area_des <= desx_transfer_count * des_y_transfer_count;
                      if ((use_src_trigin && !((src_trigin_type == 2'b00 && src_trigin_sw)|| (src_trigin_type == 2'b10 && src_trigin))) && reg1) begin
                        STAT_SRCTRIGINWAIT_DATA <= 1'b1;
                    end
                    if ((use_des_trigin && !((des_trigin_type == 2'b00 && des_trigin_sw == 1)||(des_trigin_type == 2'b10 && des_trigin == 1))) && reg1) begin
                        STAT_DESTRIGINWAIT_DATA <= 1'b1; end
                    reg1 <= 1;
                    fifo_wptr       <= 0;
                    reg2 <= reg1;
                    if(reg2) begin
                     // no trnasfer
                        ycase1 <= ((srcx_transfer_count == 0 || src_y_transfer_count == 0) &&
                                       (!(desx_transfer_count > 0 && des_y_transfer_count > 0)));
                        
                        //write only
                        ycase2 <= (!ycase1_wire) &&
                                       ((srcx_transfer_count == 0)||(src_y_transfer_count ==0)) &&
                                       (desx_transfer_count > 0) && (des_y_transfer_count > 0);
                        
                        //read only
                        ycase3 <= (!ycase1_wire) &&
                                       ((desx_transfer_count == 0)||(des_y_transfer_count == 0)) &&
                                       (srcx_transfer_count > 0) && (src_y_transfer_count > 0);
                        
                        //1d to 1d
                        ycase4 <= (!ycase1_wire && !ycase2_wire && !ycase3_wire) &&
                                       (srcx_transfer_count > 0 && src_y_transfer_count == 1) &&
                                       (desx_transfer_count > 0 && des_y_transfer_count == 1);
                        
                        //2d to 2d/1d
                        ycase5 <= (test_ycase) &&
                                       ((src_y_transfer_count > 1) || (des_y_transfer_count > 1));
                        case1 <= ((srcx_transfer_count == 0 && desx_transfer_count == 0));
                        case2 <= ((srcx_transfer_count == 0 && desx_transfer_count > 0));
                        case3 <= ((srcx_transfer_count > 0 && desx_transfer_count == 0));
                        case4 <= ((srcx_transfer_count == desx_transfer_count && srcx_transfer_count > 0));
                        case5 <= (((srcx_transfer_count > desx_transfer_count) && (desx_transfer_count != 0)));
                        case6 <= (((srcx_transfer_count < desx_transfer_count) && (srcx_transfer_count !=0)));
                    end
                    srcx_transfer_count_reg <= srcx_transfer_count; //(src_trigin_blk_size > srcx_transfer_count)?srcx_transfer_count:src_trigin_blk_size;
                    desx_transfer_count_reg <= desx_transfer_count;//(des_trigin_blk_size > desx_transfer_count)?desx_transfer_count:des_trigin_blk_size;
                   srcx_transfer_count_initial_reg <=srcx_transfer_count;
                   desx_transfer_count_initial_reg <= desx_transfer_count;
                    srcy_transfer_count_reg <= src_y_transfer_count; 
                    desy_transfer_count_reg <= des_y_transfer_count;
                     src_addr_reg <= SRC_ADDR; //added for 2d change
                   // des_addr_reg <= des_ADDR;
                   if((restart_cnt_reg > 0 || cmd_restart_en)&& !DONE_temp)begin
                    src_addr_reg <= SRC_ADDR;
                   // des_addr_reg <= des_ADDR;
                    end
                   src_x_transfer_count_reload <= srcx_transfer_count;//(src_trigin_blk_size > srcx_transfer_count)?srcx_transfer_count:src_trigin_blk_size;
                   des_x_transfer_count_reload <= desx_transfer_count;//(des_trigin_blk_size > desx_transfer_count)?desx_transfer_count:des_trigin_blk_size;
                   src_y_transfer_count_reload <= src_y_transfer_count;
                   des_y_transfer_count_reload <= des_y_transfer_count;
                 //  src_addr_reload <= (restart_cnt_reg == 0)?SRC_ADDR:src_addr_reload;
                 
                   src_addr_reload <= read_base_addr_INITIAL;
                   des_addr_reload <= write_base_addr_INITIAL;
                   src_yaddr_stride_reg <= src_yaddr_stride_signed;  // initalize yaddr stride here
                   restart_cnt_reg <= (DONE_temp)? (restart_cnt_reg ): cmd_restart_cnt ;
//                    if(reg2) begin
//                        case1 <= (srcx_transfer_count == 0 && desx_transfer_count == 0);
//                        case2 <= (srcx_transfer_count == 0 && desx_transfer_count > 0);
//                        case3 <= (srcx_transfer_count > 0 && desx_transfer_count == 0);
//                        case4 <= (srcx_transfer_count == desx_transfer_count && srcx_transfer_count > 0);
//                        case5 <= ((srcx_transfer_count > desx_transfer_count) && (desx_transfer_count != 0));
//                        case6 <= ((srcx_transfer_count < desx_transfer_count) && (srcx_transfer_count != 0));
//                    end
                end 
                
                RD_CONFIG: begin
                
                
                 if ((use_src_trigin && !((src_trigin_type == 2'b00 && src_trigin_sw)|| (src_trigin_type == 2'b10 && src_trigin))) ) begin
                        STAT_SRCTRIGINWAIT_DATA <= 1'b1;
                    end
                    if ((use_des_trigin && !((des_trigin_type == 2'b00 && des_trigin_sw == 1)||(des_trigin_type == 2'b10 && des_trigin == 1))) ) begin
                        STAT_DESTRIGINWAIT_DATA <= 1'b1;
                    end
                    area_src <= srcx_transfer_count * src_y_transfer_count;
                    area_des <= desx_transfer_count * des_y_transfer_count;
                    
                 
                    src_y_left <= src_y_transfer_count;
                   read_base_addr_INITIAL  <= src_addr_reg;
                    write_base_addr_INITIAL  <= des_addr_reg;
//                   src_x_transfer_count_reload <= srcx_transfer_count_reg;
//                   des_x_transfer_count_reload <= desx_transfer_count_reg;
//                   src_addr_reload <= src_addr_reg;
//                   des_addr_reload <= des_addr_reg;
                   if((cmd_restart_en || restart_cnt_reg != 0) && src_x_left == 0) begin
                        if(reg_reload_type == 0)begin
                        srcx_transfer_count_reg <= 0;
                        desx_transfer_count_reg <= 0;
                         srcy_transfer_count_reg <= 0;
                        desy_transfer_count_reg <= 0;
                        src_addr_reg <= 0;
                       
                        end
                        else if(reg_reload_type == 1) begin
                        srcx_transfer_count_reg <= src_x_transfer_count_reload;
                        desx_transfer_count_reg <= des_x_transfer_count_reload;
                         srcy_transfer_count_reg <= src_y_transfer_count_reload;
                        desy_transfer_count_reg <= des_y_transfer_count_reload;
                        end
                        
                        else if(reg_reload_type == 3)begin
                        srcx_transfer_count_reg <= src_x_transfer_count_reload;
                        desx_transfer_count_reg <= des_x_transfer_count_reload;
                        srcy_transfer_count_reg <= src_y_transfer_count_reload;
                        desy_transfer_count_reg <= des_y_transfer_count_reload;
                        src_addr_reg <= src_addr_reload;end
                        
                        else if(reg_reload_type == 5)begin
                        srcx_transfer_count_reg <= src_x_transfer_count_reload;
                        desx_transfer_count_reg <= des_x_transfer_count_reload;
                        srcy_transfer_count_reg <= src_y_transfer_count_reload;
                        desy_transfer_count_reg <= des_y_transfer_count_reload;
                        end
                        
                        else if(reg_reload_type == 7)begin
                        srcx_transfer_count_reg <= src_x_transfer_count_reload;
                        desx_transfer_count_reg <= des_x_transfer_count_reload;
                        srcy_transfer_count_reg <= src_y_transfer_count_reload;
                        desy_transfer_count_reg <= des_y_transfer_count_reload;
                        src_addr_reg <= src_addr_reload;
                        end end
                        
                    else begin
                    srcx_transfer_count_reg <= srcx_transfer_count_reg;
                        desx_transfer_count_reg <= desx_transfer_count_reg;
                         srcy_transfer_count_reg <= srcy_transfer_count_reg;
                        desy_transfer_count_reg <= desy_transfer_count_reg;
                        src_addr_reg <= src_addr_reg;
                    end
                        
                   des_trig_req_type_reg <= 'd2;
                   src_trig_req_type_reg <= 'd2;
                    if ((case1 || x_type == 0)||(ycase1  &&(y_type != 0))) begin
                    done_signal <= 1; end

                    wdata_mask <= {DATA_W{1'b0}};
                    for (i = 0; i < DATA_W; i = i + 1) begin
                        if (i < ((8'd1 << transize) << 3))
                            wdata_mask[i] <= 1'b1;
                    end
                     // initial_tmplt_addr_src <= src_addr_reg;//SRC_ADDR;
//                    src_addr_reg <= SRC_ADDR;
//                    des_addr_reg <= des_ADDR;
//                    srcx_transfer_count_reg <= (src_trigin_blk_size > srcx_transfer_count)?srcx_transfer_count:src_trigin_blk_size;
//                    desx_transfer_count_reg <= (des_trigin_blk_size > desx_transfer_count)?desx_transfer_count:des_trigin_blk_size;

                    //config_error_inc  <= ((x_type > 3) | (src_xaddr_inc > 1 | (des_xaddr_inc > 1)) ? 1 : 0);
                    config_error_size <= (transize > 4) | (srcx_transfer_count > 'd256) | (desx_transfer_count > 'd256);
                    config_error_transize <= (DATA_W) < ((2**transize)* 8);
                    if (use_src_trigin) begin
                        if ((src_trigin_type != 2'b00 && src_trigin_type != 2'b10) || src_trigin_mode != 2'b00) begin
                            config_error_src <= 1;
                            regvalerr_src    <= 1;
                        end
                    end
                    
                    if (use_des_trigin) begin
                        if ((des_trigin_type != 2'b00 && des_trigin_type != 2'b10) || src_trigin_mode != 2'b00) begin
                            config_error_des <= 1;
                            regvalerr_des    <= 1;
                        end
                    end
                    
                    if (use_trigout) begin
                        if (trigout_type != 2'b00 && trigout_type != 2'b10) begin
                            config_error_trigout <= 1;
                            regvalerr_trigout    <= 1;
                        end
                    end
                    
                    if (((ycase1 || ycase2)&&(y_type!=0))||(case1)) begin   //no transfer
                        src_x_left <= 0;
                    end else if (case2  || ycase2) begin  //write only
                        if ((x_type == 3 && case2)||(ycase2 && y_type == 3 && x_type ==3)) 
                        begin
                            src_x_left <= 0;
                        end else if (x_type == 0 && y_type == 0)
                            config_error_x_type <= 0;
                        else
                            config_error_x_type <= 1;
                        end 
                    else if (case3 || (ycase3)) //read only
                              src_x_left <= srcx_transfer_count;
                       // config_error_case3 <= 1;
                         else if(ycase5)
                            begin 
                                if(srcx_transfer_count == desx_transfer_count)
                                    begin
                                        src_x_left <= desx_transfer_count;
                                     case(y_type)
                                          0:src_y_left <= 0;
                                            1:src_y_left <= src_y_transfer_count;
                                            2:src_y_left <= des_y_transfer_count;
                                            3:src_y_left <= src_y_transfer_count;
                                            default : src_y_left <= src_y_transfer_count;
                                       endcase
                                   end
                           else if(srcx_transfer_count > desx_transfer_count)
                                begin
                                   
                                    if(src_y_transfer_count >= des_y_transfer_count)
                                    begin
                                        src_y_left <= des_y_transfer_count;
                                         src_x_left <= (x_type == 1)? srcx_transfer_count : desx_transfer_count;
                                    end
//                                    else if(src_y_transfer_count < des_y_transfer_count)begin
//                                    case(y_type)
//                                          0:src_y_left <= 0;
//                                            1:src_y_left <= src_y_transfer_count;
//                                            2:src_y_left <= des_y_transfer_count;
//                                            3:src_y_left <= src_y_transfer_count;
//                                            default : src_y_left <= src_y_transfer_count;
//                                       endcase
//                                    end
                                    
                                  else if(src_y_transfer_count < des_y_transfer_count)
                                   begin
                                       if(x_type == 2 || x_type == 3)  //xtype ==1 yet to add
                                       begin
                                       src_x_left <= desx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= des_y_transfer_count; // wrap
                                            3 : src_y_left <= src_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                       end
                                  else if((((srcx_transfer_count * src_y_transfer_count) == (desx_transfer_count * des_y_transfer_count))) && x_type == 1)
                                        begin
                                       src_x_left <= srcx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= src_y_transfer_count; // wrap
                                            3 : src_y_left <= src_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                       end
                                  
                                   else if((((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) == 0) && x_type == 1)
                                        begin
                                       src_x_left <= srcx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= des_y_transfer_count; // wrap
                                            3 : src_y_left <= src_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                       end      
                                   else if((((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) != 0) && x_type == 1)
                                        begin
                                       src_x_left <= srcx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= des_y_transfer_count; // wrap
                                            3 : src_y_left <= src_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                       end      
                                   end 
                                    
                                end
                           else if(srcx_transfer_count < desx_transfer_count)
                            begin
                                if(src_y_transfer_count >= des_y_transfer_count && x_type != 1)
                                    begin
                                       case (x_type)
                                            0: begin src_x_left <= 0; end
                                            1: begin src_x_left <= srcx_transfer_count;end
                                            2: begin src_x_left <= desx_transfer_count;end
                                            3: begin src_x_left <= srcx_transfer_count;end
                                            default: begin src_x_left <= srcx_transfer_count;  end
                                        endcase 
                                      
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= des_y_transfer_count; // wrap
                                            3 : src_y_left <= des_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                       end   
                                      
                                else if((src_y_transfer_count >= des_y_transfer_count) && x_type == 1)begin
                                    if((srcx_transfer_count * src_y_transfer_count) % desx_transfer_count == 0)
                                    begin
                                        src_x_left <= /*(y_type == 2)? desx_transfer_count :*/ srcx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= (area_des > area_src) ? area_des/srcx_transfer_count : src_y_transfer_count; // wrap unknown
                                            3 : src_y_left <= src_y_transfer_count; //fill  
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                    end
                                    
                                    else if((((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) != 0) && x_type == 1)
                                        begin
                                       src_x_left <= srcx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= (area_des > area_src) ? ((area_des % srcx_transfer_count==0)? (area_des/srcx_transfer_count) :((area_des/srcx_transfer_count) +1)): src_y_transfer_count; // wrap
                                            3 : src_y_left <= src_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                       end   
                                    
                                end
                                
                                else if(src_y_transfer_count < des_y_transfer_count) begin
                                    if(x_type == 2)begin
                                    src_x_left <= desx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= des_y_transfer_count; // wrap
                                            3 : src_y_left <= src_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                    end
                                    else if(x_type == 3)begin
                                    src_x_left <= srcx_transfer_count;
                                        case(y_type)
                                            0 : src_y_left <= src_y_transfer_count;
                                            1 : src_y_left <= src_y_transfer_count; //continue
                                            2 : src_y_left <= des_y_transfer_count; // wrap
                                            3 : src_y_left <= src_y_transfer_count; //fill
                                        default: src_y_left <= src_y_transfer_count;
                                        endcase
                                    end
                                    else if(x_type == 1 /*&& (((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) == 0) */)begin
                                    
                                        case(y_type)
                                            0 : begin
                                                src_x_left <= srcx_transfer_count;
                                                src_y_left <= src_y_transfer_count;
                                            end
                                            1 :  begin
                                                src_x_left <= srcx_transfer_count;
                                                src_y_left <= src_y_transfer_count;
                                            end //continue
                                            2 : begin
                                                src_x_left <= srcx_transfer_count;
                                                src_y_left <= (area_des > area_src) ? ((area_des % srcx_transfer_count==0)? (area_des/srcx_transfer_count) :((area_des/srcx_transfer_count) +1)): src_y_transfer_count;
                                            end// wrap
                                            3 :  begin
                                                src_x_left <= srcx_transfer_count;
                                                src_y_left <= src_y_transfer_count;
                                            end //fill
                                        default: begin
                                                src_x_left <= srcx_transfer_count;
                                                src_y_left <= src_y_transfer_count;
                                            end 
                                        endcase
                                    end
//                                    else if(x_type == 1 && (((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) != 0) )begin
                                    
//                                        case(y_type)
//                                            0 : begin
//                                                src_x_left <= srcx_transfer_count;
//                                                src_y_left <= src_y_transfer_count;
//                                            end
//                                            1 :  begin
//                                                src_x_left <= srcx_transfer_count;
//                                                src_y_left <= src_y_transfer_count;
//                                            end //continue
//                                            2 : begin
//                                                src_x_left <= srcx_transfer_count;
//                                                src_y_left <= (area_des > area_src) ? ((area_des % srcx_transfer_count==0)? (area_des/srcx_transfer_count) :((area_des/srcx_transfer_count) +1)): src_y_transfer_count;
//                                            end// wrap
//                                            3 :  begin
//                                                src_x_left <= srcx_transfer_count;
//                                                src_y_left <= src_y_transfer_count;
//                                            end //fill
//                                        default: begin
//                                                src_x_left <= srcx_transfer_count;
//                                                src_y_left <= src_y_transfer_count;
//                                            end 
//                                        endcase
//                                    end
                                end
                                
                            end 
                         end
                        
                               
                    else if ((case4 || case5)) begin
                        /*if((cmd_restart_en || cmd_restart_cnt != 0))
                            src_x_left <= (src_trigin_blk_size > src_x_transfer_count_reload)?src_x_transfer_count_reload:src_trigin_blk_size;
                        else*/

                            src_x_left <= desx_transfer_count;//(src_trigin_blk_size > desx_transfer_count)?desx_transfer_count:src_trigin_blk_size;
                    end else if (case6) begin
                        case (x_type)
                            0: begin src_x_left <= 0; end
                            1: begin src_x_left <= srcx_transfer_count;end//(src_trigin_blk_size > srcx_transfer_count)?srcx_transfer_count:src_trigin_blk_size; end
                            2: begin src_x_left <= desx_transfer_count;end// (src_trigin_blk_size > desx_transfer_count)?desx_transfer_count:src_trigin_blk_size; end
                            3: begin src_x_left <= srcx_transfer_count;end//(src_trigin_blk_size > srcx_transfer_count)?srcx_transfer_count:src_trigin_blk_size; end
                            default: begin src_x_left <= srcx_transfer_count; config_error_case6 <= 1; end
                        endcase
                    end
                  
                    //fill_count <= ((srcx_transfer_count < desx_transfer_count) && x_type == 3 && (case2 || case6)) ? ((desx_transfer_count - srcx_transfer_count) & 16'hFFFF) : 0;//
                end
                
                RD_WAIT_TRIG: begin
                 src_x_left_initial <= /*(case6 && x_type ==2)? srcx_transfer_count_reg :*/ src_x_left;
               // src_x_left_initial_integer <= src_x_left;

                if(use_src_trigin)
                 src_trig_req_type_reg <= (src_trigin_type == 'b10) ? src_trig_req_type : (src_trigin_type == 'b00) ? src_trigin_sw_type : src_trig_req_type_reg;
                                   
                   if(use_des_trigin)
                des_trig_req_type_reg <= (des_trigin_type == 'b10) ? des_trig_req_type : (des_trigin_type == 'b00) ? des_trigin_sw_type : des_trig_req_type_reg; 
                   // src_trig_req_type_reg <= (use_src_trigin)?src_trig_req_type:src_trig_req_type_reg;
                   // des_trig_req_type_reg <= (use_des_trigin)?des_trig_req_type:des_trig_req_type_reg; 
                      if (use_src_trigin && use_des_trigin) begin  
                    if (((src_trigin_type == 2'b00 && src_trigin_sw)||(src_trigin_type == 2'b10 && src_trigin)) &&
                        ((des_trigin_type == 2'b00 && des_trigin_sw)||(des_trigin_type == 2'b10 && des_trigin))) begin
                        src_trigack <= (src_trigin_type == 2'b00)?0:1;
src_trigack_type <= (src_trigin_type == 2'b10 && (src_trig_req_type == 0||src_trig_req_type == 1) )?0:
(src_trigin_type == 2'b10 && (src_trig_req_type == 1||src_trig_req_type == 3) )?1:0;
des_trigack <= (des_trigin_type == 2'b00)?0:1; 
des_trigack_type <=(des_trigin_type == 2'b10 && (des_trig_req_type == 0||des_trig_req_type == 1) )?0:
(des_trigin_type == 2'b10 && (des_trig_req_type == 1||des_trig_req_type == 3) )?1:0;
end
                end

                else if(!use_src_trigin && use_des_trigin) begin
                    if ((des_trigin_type == 2'b00 && des_trigin_sw)||(des_trigin_type == 2'b10 && des_trigin))   
        des_trigack <=  (des_trigin_type == 2'b00)?0:1; 

des_trigack_type <=(des_trigin_type == 2'b10 && (des_trig_req_type == 0||des_trig_req_type == 1) )?0:
(des_trigin_type == 2'b10 && (des_trig_req_type == 1||des_trig_req_type == 3) )?1:0;
                end

                else if(!use_des_trigin && use_src_trigin) begin
                     if ((src_trigin_type == 2'b00 && src_trigin_sw)||(src_trigin_type == 2'b10 && src_trigin)) 
                        src_trigack <= (src_trigin_type == 2'b00)?0:1;    
src_trigack_type <= (src_trigin_type == 2'b10 && (src_trig_req_type == 0||src_trig_req_type == 1
) )?0:
(src_trigin_type == 2'b10 && (src_trig_req_type == 1||src_trig_req_type == 3) )?1:0;
                end
                
                
                   if ((use_src_trigin && !((src_trigin_type == 2'b00 && src_trigin_sw)|| (src_trigin_type == 2'b10 && src_trigin))) && rd_next_st == RD_WAIT_TRIG) begin
                        STAT_SRCTRIGINWAIT_DATA <= 1'b1;
                    end
                    if ((use_des_trigin && !((des_trigin_type == 2'b00 && des_trigin_sw == 1)||(des_trigin_type == 2'b10 && des_trigin == 1)))  && rd_next_st == RD_WAIT_TRIG) begin
                        STAT_DESTRIGINWAIT_DATA <= 1'b1;
                    end
                    src_x_transfer_count_remaining <= (case6 && x_type ==2 )? srcx_transfer_count_reg : src_x_left;//(src_trigin_blk_size > srcx_transfer_count_reg )? srcx_transfer_count_reg:src_trigin_blk_size;
                    src_y_transfer_count_remaining <= srcy_transfer_count_reg;
                    fill_count <= ((src_x_left < des_x_left) && x_type == 3 && (case2 || case6)) ? ((des_x_left - src_x_left) & 16'hFFFF) : 0;//
                        if((src_y_transfer_count >= des_y_transfer_count) && x_type == 1 &&  (((srcx_transfer_count * src_y_transfer_count) % desx_transfer_count == 0) && srcx_transfer_count < desx_transfer_count))
                            fill_count_y <= ((des_y_left - ((area_src / desx_transfer_count)& (16'hFFFF))) & (16'hFFFF)) ; 
                        else if((src_y_transfer_count >= des_y_transfer_count) && x_type == 1 &&  (((srcx_transfer_count * src_y_transfer_count) % desx_transfer_count != 0) && srcx_transfer_count < desx_transfer_count))
                            fill_count_y <= ((des_y_left - ((area_src / desx_transfer_count)& (16'hFFFF))) & (16'hFFFF)) ; 
                        else if ((src_y_transfer_count < des_y_transfer_count) && y_type == 3 && (ycase2 || ycase5) &&  (srcx_transfer_count < desx_transfer_count))
                        begin
                            if(x_type == 1)
                            fill_count_y <= ((des_y_left - ((area_src / desx_transfer_count)& (16'hFFFF)))& (16'hFFFF));
                            else
                            fill_count_y <= des_y_left - src_y_left;
                        end
                        else                                
                            fill_count_y <= ((src_y_left < des_y_left) && y_type == 3 && (ycase2 || ycase5)) ? ((des_y_left - ((area_src / desx_transfer_count)& (16'hFFFF))) & 16'hFFFF) : 0;
                end 
                
                RD_AR: begin                   
                    //ARLEN   <= (src_trig_req_type == 'd0) ? 'd0 :  ;
                    if(src_tmplt_size > 0)
                        ARLEN <= 'd0;
                    else if(ycase5 && ((((srcx_transfer_count_reg * srcy_transfer_count_reg)% desx_transfer_count_reg ) != 0) && x_type == 1)&& y_type == 2 /*&& srcx_transfer_count_reg > desx_transfer_count_reg*/ && (src_y_left == 1) &&(area_src < area_des))begin
                        ARLEN <= ((src_x_left - 1) > src_max_burst_len) ? {4'd0,src_max_burst_len}  : src_x_left - 1;
                    end
                    else if((src_trig_req_type_reg == 'd0 && use_src_trigin) || (src_xaddr_inc > 1) || (src_xaddr_inc < 0)) 
                        ARLEN <= 'd0;
                    else if(src_trig_req_type_reg == 'd2)
                        ARLEN <= ((src_x_transfer_count_remaining - 1) > src_max_burst_len) ? {4'd0,src_max_burst_len} : src_x_transfer_count_remaining - 1;
                    
                    ARBURST <= ((src_xaddr_inc == 1)) ? 2'b01 : 2'b00;
                    ARSIZE  <= transize;
                    ARID    <= 0;
                   // ARVALID <= 1;
                   // ARADDR <= (src_xaddr_inc == 'd0) ? src_addr_reg : (src_x_transfer_count_remaining == srcx_transfer_count_reg)? src_addr_reg : (ARVALID && ARREADY) ? ARADDR + ((ARLEN + 1) * 2**transize) : ARADDR;
                   // ARADDR <= (case6 && x_type == 'd2 && src_x_transfer_count_remaining == 0)? read_base_addr_INITIAL: ((src_x_transfer_count_remaining == src_x_left) && case6 && x_type == 2) ? ARADDR : src_addr_reg + (srcx_transfer_count_reg - src_x_transfer_count_remaining)  * ((2**transize)*src_xaddr_inc_sign);
                   
                   if(src_tmplt_size != 0)begin
                            if(src_tmplt[m] == 0) 
                            begin
                            if(m >= src_tmplt_size)
                                   m <= 0;
                             else      
                                m <= m + 1;
                            end
                            
                            
                         if(src_tmplt[m] ) begin
                          ARVALID <= 1;
                               ARADDR <= initial_tmplt_addr_src + m * (2**transize);      end                      
                   end

                           else if (case6 && x_type == 'd2 && ((src_x_transfer_count_remaining == 0) || (src_x_left == srcx_transfer_count_initial_reg))) begin
                        ARADDR <=src_addr_reg /*read_base_addr_INITIAL*/;
                         ARVALID <= 1;
                    end
//                    else if ((src_x_transfer_count_remaining == src_x_left) && case6 && x_type == 2 && (ARVALID)) begin
//                        ARADDR <= ARADDR;
//                         ARVALID <= 1;
//                    end
                    else if (case6 && x_type == 'd2 ) begin
                         ARVALID <= 1;
                        ARADDR <= (ARVALID)?ARADDR : src_addr_reg + 
                                  (srcx_transfer_count_initial_reg - src_x_transfer_count_remaining) * 
                                  ((2**transize) * src_xaddr_inc_sign);
                    end
                    else begin
                     ARVALID <= 1;
                        ARADDR <= (ARVALID)?ARADDR : src_addr_reg + 
                                  (src_x_left_initial - src_x_transfer_count_remaining) * 
                                  ((2**transize) * src_xaddr_inc_sign);
            //            ARADDR <= (ARVALID)?ARADDR : src_addr_reg +   (srcx_transfer_count_reg - src_x_transfer_count_remaining) * ((2**transize) * src_xaddr_inc_sign);
                    end 
                    //ARVALID <= (!stop_cmd_apb)?ARVALID:0;
                   src_x_transfer_count_remaining <= (case6 && x_type == 'd2 && src_x_transfer_count_remaining == 0) ? (srcx_transfer_count_reg > src_x_left) ? src_x_left : srcx_transfer_count_reg : (src_x_transfer_count_remaining);
                   srcx_transfer_count_reg <= (case6 && x_type == 'd2 && src_x_transfer_count_remaining == 0) ? (srcx_transfer_count_reg > src_x_left) ? src_x_left : srcx_transfer_count_reg : (srcx_transfer_count_reg);
                    end
        

                RD_R: begin
                
                if(src_x_left == 0 && DONE_temp)
                                restart_cnt_reg <= restart_cnt_reg - 1;
                    if (full || (stop_cmd_apb))
                        RREADY <= 0;
                    else
                        RREADY <= 1;
                    if (RVALID && RREADY && RLAST) begin
//                            if(src_x_left == 0)
//                                restart_cnt_reg <= restart_cnt_reg - 1;
                            src_x_transfer_count_remaining <= src_x_transfer_count_remaining - (ARLEN + 1);
                            if(src_tmplt_size != 0) begin
                                 m <= m + 1;
                            
                                if(m >= src_tmplt_size)
                                       m <= 0;end
                    end                
                    if ( RVALID && RREADY && src_x_left > 0 && !full) begin
                   
                        fifo_mem[fifo_wptr[4:0]] <= RDATA;
                        fifo_wptr           <= fifo_wptr + 1;
                        src_x_left            <= src_x_left - 1;
                     
                        
                
                        if (RRESP == 2'b11) begin
                            bus_error_r <= 1'b1;
                            ard_error   <= 1'b1;
                        end else if (RRESP == 2'b10) begin
                            bus_error_r    <= 1'b1;
                            arpoison_error <= 1'b1;
                        end
                    end
                
                    end
                    
                RD_WRAP_FILL: begin
                     if(src_x_left == 0 && fill_count == 0 && DONE_temp)
                                restart_cnt_reg <= restart_cnt_reg - 1;
                    case (x_type)
                        1: begin
                       // r1 <= 0;
                            if (fill_count_y >0 && src_y_left == 0 && (ycase2 || ycase5) && y_type == 3) begin
                                //for(r = 0; r < des_x_left_initial_integer ; r=r+1)
                                if(r1 < des_x_left_initial)
                                begin
                                    fifo_mem[fifo_wptr[4:0]] <= {96'd0, fillval};
                                    fifo_wptr           <= fifo_wptr + 1;
                                    r1 <= (r1 == des_x_left_initial - 1) ? 0 : r1 + 1;
                                  //  r=r+1;
                                 end
                                    fill_count_y <= (r1 == des_x_left_initial-1)? fill_count_y - 1 : fill_count_y;
                                    
                            end
                          end
                        2: begin 
                                                
                           if (fill_count_y >0 && src_y_left == 0 && (ycase2 || ycase5) && y_type == 3) begin
                                //for(r = 0; r < des_x_left_initial_integer ; r=r+1)
                                if(r1 < des_x_left_initial)
                                begin
                                    fifo_mem[fifo_wptr[4:0]] <= {96'd0, fillval};
                                    fifo_wptr           <= fifo_wptr + 1;
                                    r1 <= (r1 == des_x_left_initial - 1) ? 0 : r1 + 1;
                                    /*r1 <= r1+1;*/end
                                    fill_count_y <= (r1 == des_x_left_initial-1)? fill_count_y - 1 : fill_count_y;
                                    
                            end
                        end
                        3: begin
                            if (fill_count > 0 && src_x_left == 0 && (case2 || case6)) begin
                                fifo_mem[fifo_wptr[4:0]] <= {96'd0, fillval};
                                fill_count          <= fill_count - 1;
                                fifo_wptr           <= fifo_wptr + 1;
                            end
                            
                            else if(desx_transfer_count_initial_reg > srcx_transfer_count_initial_reg && desy_transfer_count_reg > srcy_transfer_count_reg) begin
                                if (fill_count_y >0 && src_y_left == 0 && (ycase2 || ycase5) && y_type == 3) begin
                                //for(r = 0; r < des_x_left_initial_integer ; r=r+1)
                                if(r1 < des_x_left_initial)
                                begin
                                    fifo_mem[fifo_wptr[4:0]] <= {96'd0, fillval};
                                    fifo_wptr           <= fifo_wptr + 1;
                                    r1 <= (r1 == des_x_left_initial - 1) ? 0 : r1 + 1;
                                    /*r1 <= r1+1;*/end
                                    fill_count_y <= (r1 == des_x_left_initial-1)? fill_count_y - 1 : fill_count_y;
                                    end
                            end
                         
                            
                            else if (fill_count_y >0 && src_y_left == 0 && (ycase2 || ycase5)) begin
                                //for(r = 0; r < src_x_left_initial_integer ; r=r+1)
                                if(r1 < des_x_left_initial)
                                begin
                                    fifo_mem[fifo_wptr[4:0]] <= {96'd0, fillval};
                                    fifo_wptr           <= fifo_wptr + 1;
                                    r1 <= r1+1;end
                                    fill_count_y <= (r1 == src_x_left_initial-1)? fill_count_y - 1 : fill_count_y;
                            end
                            
                        end
                        default: fifo_mem[fifo_wptr[4:0]] <= fifo_mem[fifo_wptr[4:0]];
                    endcase
                end
                RD_ROWS: begin
                   if(src_x_left == 0)
                            begin
                            src_y_transfer_count_remaining <= src_y_transfer_count_remaining - 1;
                            src_y_left <= src_y_left - 1; 
                            end
                        else if((ycase5 && y_type == 2) && src_y_transfer_count_remaining == 1 && src_y_left !=1)begin
                            src_y_transfer_count_remaining <= (src_y_left > srcy_transfer_count_reg)?srcy_transfer_count_reg:src_y_left;
                            src_addr_reg  <= read_base_addr_INITIAL;
                        end
                        else 
                        src_addr_reg <= src_addr_reg + ( src_yaddr_stride_signed *(2** transize));
                   
                    if(src_y_left > 1 )
                    begin
                        if(src_x_left == 0 )begin
                            fill_count <= ((src_x_left_initial < des_x_left_initial) && x_type == 3 && (case2 || case6)) ? ((des_x_left_initial - src_x_left_initial) & 16'hFFFF) : 0;end
                            
                        src_x_left <=  {6'd0,src_x_left_initial};
                        src_x_transfer_count_remaining <= (case6 && x_type ==2 )? srcx_transfer_count_initial_reg : {6'd0,src_x_left_initial};
                        //src_x_transfer_count_remaining <= src_x_left_initial;
                        if(ycase5 && ((((srcx_transfer_count_reg * srcy_transfer_count_reg)% desx_transfer_count_reg ) != 0) && x_type == 1)&& y_type == 2 /*&& srcx_transfer_count_reg > desx_transfer_count_reg*/ && (src_y_left == 2) &&(area_src < area_des))begin
                            src_x_left <= area_des % srcx_transfer_count;
//                        src_x_transfer_count_remaining <= area_des % srcx_transfer_count;
                    end
//                        if((ycase5 && y_type == 2) && src_y_transfer_count_remaining == 1 && src_y_left !=1)begin
//                            src_y_transfer_count_remaining <= (src_y_left > srcy_transfer_count_reg)?srcy_transfer_count_reg:src_y_left;
//                            src_addr_reg  <= read_base_addr_INITIAL;
//                        end
//                        else 
//                        src_addr_reg <= src_addr_reg + ( src_yaddr_stride_signed *(2** transize));
                    end
                    else
                        src_x_left <= src_x_left;
                        if(ycase3 && src_y_left ==1 )
                            done_signal <=1;
                end
            endcase
            
            if((rd_state == RD_R&& RLAST)||(rd_state == RD_WRAP_FILL && fill_count == 0)||(ycase2))
                wr_start <= 1;
        end
    end
    
    
    // wr_fsm_seq
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
           //wr_pause_state <= W_IDLE;
         AWVALID      <= 0;
           WVALID       <= 0;
      //  WLAST <= 0;
            BREADY       <= 0;
            DONE <= 0;
            des_addr_reg <= 0;
       fifo_rptr   <= 0;
       des_x_left_initial<=0;
         initial_tmplt_addr_des <= 0;
       des_y_left <= 0;
        des_x_left    <= 0;
           trig_out_req <= 0;
           STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
           //WLAST <= 0;
           awr_error<=0;
           AWLEN <= 'd0;
           AWADDR <= 0;
           l <= 0;
           des_x_transfer_count_remaining <= 0;
           des_x_transfer_count_remaining_2d <= 0;
           WDATA <= 0;
           AWID <= 0;
           AWSIZE <= 0;
           DONE_temp <= 0;
           AWBURST <= 0;
           bus_error_w <= 'd0;
           des_yaddr_stride_reg <= 'd0;
    end 
    else begin
            AWVALID      <= 0;
          //  WLAST        <= 0;
          WVALID       <= 0;
            BREADY       <= 0;
           DONE         <= stop_cmd_apb? 1: 0;
           DONE_temp <= (rd_state ==RD_CONFIG)?0:DONE_temp;
           trig_out_req <= 0;
           // STAT_RESUMEWAIT_DATA <= 'd0;
           // STAT_PAUSED_DATA <= 'd0;
            STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
              des_addr_reg <= des_ADDR;
            //STAT_SRCTRIGINWAIT_DATA <= 1'b0;
           // STAT_DESTRIGINWAIT_DATA <= 1'b0;
        if( l == des_tmplt_size )
                   initial_tmplt_addr_des  <= AWADDR + ((des_tmplt_size + 1) - p) *(2**transize);
                   
           else if(wr_state == W_IDLE)
            initial_tmplt_addr_des <= des_ADDR;
               // wr_pause_state <= (wr_next_st  != W_PAUSED )? wr_next_st :wr_pause_state; 
            case (wr_state)
W_IDLE: begin
    l <= 0;
     
    
//                   if((restart_cnt_reg > 0 || cmd_restart_en)&& !DONE_temp)begin
                               
//                                des_addr_reg <= des_ADDR;
//                                end 
                        if((cmd_restart_en || restart_cnt_reg != 0) && src_x_left == 0) begin
                            if(reg_reload_type == 0)begin
                            
                            des_addr_reg <= 0;
                            end
                           
                            
                            else if(reg_reload_type == 5)begin
                            
                            des_addr_reg <= des_addr_reload;end
                            
                            else if(reg_reload_type == 7)begin
                            
                            des_addr_reg <= des_addr_reload;end
                            else
                                begin des_addr_reg <= des_addr_reg;end
                                end
                        else
                               begin des_addr_reg <= des_addr_reg; end
    des_yaddr_stride_reg <= des_yaddr_stride_signed;
    des_y_left           <= des_y_transfer_count;
    des_x_left_initial   <= des_x_left;
    //des_x_left_initial_integer <= des_x_left;
    //initial_tmplt_addr_des <= des_ADDR;
    des_x_transfer_count_remaining  <= desx_transfer_count_reg;
    des_x_transfer_count_remaining_2d<= desx_transfer_count_reg;

    if (stat_error_intr_reg == 0) begin
        awr_error  <= 0;
        bus_error_w <= 0;
    end

    fifo_rptr <= 0;

    //------------------------------------------
    // MAIN CASE HANDLING
    //------------------------------------------
    if (((ycase1 || ycase2) && (y_type != 0)) || (case1)) begin
        des_x_left <= 0;

    end 
    else if (case2 || ycase2) begin
        if ((x_type == 3 && case2) || (ycase2 && y_type == 3 && x_type == 3)) begin
            des_x_left <= desx_transfer_count;
        end
    end 

    else if (case3 || ycase3) begin
        des_x_left <= 0;
    end 

    //------------------------------------------
    // YCASE5 BLOCK (CLEANED)
    //------------------------------------------
    else if (ycase5) begin

        if (srcx_transfer_count == desx_transfer_count) begin
            des_x_left <= desx_transfer_count;

            case (y_type)
                0: des_y_left <= 0;
                1: des_y_left <= src_y_transfer_count;
                2: des_y_left <= des_y_transfer_count;
                3: des_y_left <= des_y_transfer_count;
                default: des_y_left <= des_y_transfer_count;
            endcase
        end 

        else if (srcx_transfer_count > desx_transfer_count) begin

            if (src_y_transfer_count >= des_y_transfer_count) begin
                des_y_left <= des_y_transfer_count;
                des_x_left <= desx_transfer_count;
            end

            else begin
                if (x_type == 2 || x_type == 3) begin
                    des_x_left <= desx_transfer_count;

                    case (y_type)
                        0: des_y_left <= des_y_transfer_count;
                        1: des_y_left <= src_y_transfer_count;
                        2: des_y_left <= des_y_transfer_count;
                        3: des_y_left <= des_y_transfer_count;
                        default: des_y_left <= des_y_transfer_count;
                    endcase
                end

                else if (((srcx_transfer_count * src_y_transfer_count) % desx_transfer_count == 0) && (x_type == 1)) begin
                    des_x_left <= desx_transfer_count;

                    case (y_type)
                        0: des_y_left <= des_y_transfer_count;
                        1: des_y_left <= (srcx_transfer_count * src_y_transfer_count) / desx_transfer_count;
                        2: des_y_left <= des_y_transfer_count;
                        3: des_y_left <= des_y_transfer_count;
                        default: des_y_left <= des_y_transfer_count;
                    endcase
                end

                else if (((srcx_transfer_count * src_y_transfer_count) % desx_transfer_count != 0) && (x_type == 1)) begin
                    des_x_left <= desx_transfer_count;

                    case (y_type)
                        0: des_y_left <= des_y_transfer_count;
                        1: begin
                            des_y_left <= (area_src > area_des) ? 
                                          des_y_transfer_count : 
                                          ((srcx_transfer_count * src_y_transfer_count) / desx_transfer_count) + 1;
                        end
                        2: des_y_left <= des_y_transfer_count;
                        3: des_y_left <= des_y_transfer_count;
                        default: des_y_left <= des_y_transfer_count;
                    endcase
                end
            end
        end 

        else if (srcx_transfer_count < desx_transfer_count) begin
            if (src_y_transfer_count >= des_y_transfer_count && x_type !=1) begin

                case (x_type)
                    0: begin
                        des_x_left <= 0;
                    end

                    1: begin
                        des_x_left <= srcx_transfer_count;
                    end

                    2: begin
                        des_x_left <= desx_transfer_count;
                        des_y_left <= des_y_transfer_count;
                    end

                    3: begin
                        des_x_left <= desx_transfer_count;
                        des_y_left <= des_y_transfer_count;
                    end

                    default: begin
                        des_x_left <= srcx_transfer_count;
                        //config_error_case6 <= 1;
                    end
                endcase
            end
           else if(src_y_transfer_count >= des_y_transfer_count && x_type == 1)begin
                    if(area_src % desx_transfer_count == 0)
                    begin
                        des_x_left <= desx_transfer_count;
                        case(y_type)
                            0 : des_y_left <= des_y_transfer_count;
                            1 : des_y_left <= area_src/desx_transfer_count; //continue
                            2 : des_y_left <= des_y_transfer_count; // wrap unknown
                            3 : des_y_left <= des_y_transfer_count; //fill  
                        default: des_y_left <= des_y_transfer_count;
                        endcase
                    end
                    
                    
                     else if((((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) != 0) && x_type == 1)
                                        begin
                                       des_x_left <= desx_transfer_count;
                                        case(y_type)
                                            0 : des_y_left <= src_y_transfer_count;
                                            1 : des_y_left <= (area_src > area_des) ? des_y_transfer_count :((srcx_transfer_count * src_y_transfer_count) / desx_transfer_count) + 1; //continue
                                            2 : des_y_left <= des_y_transfer_count; // wrap
                                            3 : des_y_left <= des_y_transfer_count; //fill
                                        default: des_y_left <= des_y_transfer_count;
                                        endcase
                                       end 
                    
                end 
                 else if(src_y_transfer_count < des_y_transfer_count) begin
                    if(x_type == 2)begin
                        des_x_left <= desx_transfer_count;
                            case(y_type)
                                0 : des_y_left <= des_y_transfer_count;
                                1 : des_y_left <= src_y_transfer_count; //continue
                                2 : des_y_left <= des_y_transfer_count; // wrap
                                3 : des_y_left <= des_y_transfer_count; //fill
                            default: des_y_left <= des_y_transfer_count;
                            endcase
                        end
                        else if(x_type == 3)begin
                        des_x_left <= desx_transfer_count;
                            case(y_type)
                                0 : des_y_left <= des_y_transfer_count;
                                1 : des_y_left <= src_y_transfer_count; //continue
                                2 : des_y_left <= des_y_transfer_count; // wrap
                                3 : des_y_left <= des_y_transfer_count; //fill
                            default: des_y_left <= des_y_transfer_count;
                            endcase
                        end
                        else if(x_type == 1 /*&& (((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) == 0) */)begin

                            case(y_type)
                                0 : begin
                                    des_x_left <= desx_transfer_count;
                                    des_y_left <= des_y_transfer_count;
                                end
                                1 :  begin
                                    des_x_left <= desx_transfer_count;
                                    des_y_left <= (((srcx_transfer_count * src_y_transfer_count)% desx_transfer_count ) == 0) ? (area_src)/desx_transfer_count : ((area_src)/desx_transfer_count + 1);
                                end //continue
                                2 : begin
                                    des_x_left <= desx_transfer_count;
                                    des_y_left <= des_y_transfer_count;
                                end// wrap
                                3 :  begin
                                    des_x_left <= desx_transfer_count;
                                    des_y_left <= des_y_transfer_count/*(area_src)/desx_transfer_count*/;// should add fill y count
                                end //fill
                            default: begin
                                    des_x_left <= desx_transfer_count;
                                    des_y_left <= des_y_transfer_count;
                                end 
                            endcase
                        end                
                end
        end
    end

    //------------------------------------------
    // OTHER CASES (FIXED DUPLICATE ycase5)
    //------------------------------------------
    else if (case4 || case5) begin
        des_x_left <= desx_transfer_count;
    end 

    else if (case6) begin
        case (x_type)
            0: begin
                des_x_left <= 0;
            end

            1: begin
                des_x_left <= srcx_transfer_count;
            end

            2: begin
                des_x_left <= desx_transfer_count;
            end

            3: begin
                des_x_left <= desx_transfer_count;
            end

            default: begin
                des_x_left <= desx_transfer_count;
            end
        endcase
    end

end
                W_AW: begin
                   // AWVALID <= 1;
                    
                    if(des_tmplt_size != 0)begin
                            if(des_tmplt[l] == 0) begin
                          
                            if(l >= des_tmplt_size)
                                   l <= 0;
                             else
                                  l <= l + 1;
                            end
                         if(des_tmplt[l] )
                           begin
                            AWVALID <= 1;
                               AWADDR <= initial_tmplt_addr_des + l * (2**transize);   end                         
                   end
                   else begin
                         AWADDR  <= /*(des_x_transfer_count_remaining == des_x_left) ? AWADDR :*/ des_addr_reg + (desx_transfer_count_reg - des_x_transfer_count_remaining)  *  (( 2**transize)*des_xaddr_inc_sign);
                         AWVALID <= 1; end
                     if(des_tmplt_size > 0)
                        AWLEN <= 'd0;
                     else if(des_trig_req_type_reg == 'd0 && use_des_trigin  || (des_xaddr_inc > 1) || (des_xaddr_inc < 0)) 
                        AWLEN <= 'd0;
                    else if(des_trig_req_type_reg == 'd2) begin 
                        if(ycase5 && ((((srcx_transfer_count_reg * srcy_transfer_count_reg)% desx_transfer_count_reg ) != 0) && x_type == 1)&& y_type == 1 /*&& srcx_transfer_count_reg > desx_transfer_count_reg*/ && (des_y_left == 1) &&(area_src < area_des))
                            AWLEN <= ((des_x_left - 1) > des_max_burst_len) ? {4'd0,des_max_burst_len} : des_x_left - 1;
                        else
                           AWLEN <= ((des_x_transfer_count_remaining - 1) > des_max_burst_len) ? {4'd0,des_max_burst_len} : des_x_transfer_count_remaining - 1;//(case6 && x_type == 1)? srcx_transfer_count - 1: desx_transfer_count - 1;
                    end
//                    AWLEN <= ((des_x_transfer_count_remaining - 1) > des_max_burst_len) ? des_max_burst_len : des_x_transfer_count_remaining - 1;//(case6 && x_type == 1)? srcx_transfer_count - 1: desx_transfer_count - 1;
                    AWBURST <= (des_xaddr_inc == 1) ? 2'b01 : 2'b00;
                    AWSIZE  <= transize;
                    AWID    <= 0;
                    //AWVALID <= (!stop_cmd_apb)?AWVALID:0;
                end
               
             W_W:
             begin
                     
                     WVALID <= ((WREADY && WLAST)||(empty)||(stop_cmd_apb)) ? 0 : 1;
                     WDATA     <= fifo_mem[fifo_rptr[4:0]];
                     if(WVALID && WREADY && WLAST) begin
                        des_x_transfer_count_remaining <= des_x_transfer_count_remaining - (AWLEN + 1);
                        des_x_transfer_count_remaining_2d <= des_x_transfer_count_remaining_2d - (AWLEN + 1);
                     end
                    
                    if (WREADY && des_x_left > 0 && WVALID) begin                       
                      WDATA     <=  !(WREADY && WLAST) ? fifo_mem[fifo_rptr_t[4:0]]: WDATA; 
                       des_x_left  <= des_x_left - 1;
                       fifo_rptr <= fifo_rptr + 1;
                    end
                end              
             
             
                         
                W_B: begin
                    //BREADY <= (!stop_cmd_apb)?1:0;
                    BREADY <= 1;
                    if (BRESP >= 2) begin
                        awr_error<= 1;
                        bus_error_w <= 1;
                    end
                end                
                W_TRIG_OUT: begin
                    if (use_trigout && trigout_type == 'b10)
                    trig_out_req <= 1;                    
                    if (use_trigout && !trig_out_ack_sw && trigout_type == 'b00)
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else if (use_trigout && !trig_out_ack && trigout_type == 'b10)
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b1;
                    else 
                        STAT_TRIGOUTACKWAIT_DATA <= 1'b0;
                end
                
                W_DONE_ST: begin
                    DONE <= (restart_cnt_reg !=0 || cmd_restart_en)? 0 : 1;
                    DONE_temp <= 1;
                    //STAT_DONE_DATA <= !link_en ? 1 : 0;
                end
                W_ROWS: begin
                  WVALID <= 0;
                 if(des_x_left == 0)
                            des_y_left <= des_y_left - 1; 
         
                    if(des_y_left > 1 )
                    begin
                    if(ycase5 && ((((srcx_transfer_count_reg * srcy_transfer_count_reg)% desx_transfer_count_reg ) != 0) && x_type == 1)&& y_type == 1 /*&& srcx_transfer_count_reg > desx_transfer_count_reg*/ && (des_y_left == 2) &&(area_src < area_des))begin
                            des_x_left <= area_src % desx_transfer_count;
                            des_x_transfer_count_remaining_2d <= area_src % desx_transfer_count; 
                   end
                    else begin
                        des_x_left <= des_x_left_initial;
                         des_x_transfer_count_remaining_2d <= des_x_left_initial ;

                        end
                        des_x_transfer_count_remaining <= des_x_left_initial;
                        
                        des_addr_reg <= des_addr_reg + (des_yaddr_stride_signed *(2** transize));
                    end
                    
                    else
                        des_x_left <= des_x_left;
                end
            endcase
        end
    end 
    
endmodule
 

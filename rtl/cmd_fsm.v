

module cmd_fsm
#(parameter DATA_W = 128)
 (
    input clk, 
    input resetn,
    input wire rst_posedge,
    input wire [3:0] ch_prio,
    input [31:0]next_cmd_addr,// fro intern reg
    input link_enable,// fro intern reg
    input data_done,// fro intern reg
    input wire wr_en,//or of every write enable 
    input wire stat_disable_intr_reg,
    // AR signals
    input ARREADY,
    output reg [3:0] ARID,
    output reg [7:0] ARLEN,
    output reg[2:0] ARSIZE,
    output reg [1:0] ARBURST,
    output reg ARVALID,
    output reg [31:0]ARADDR,
    output reg [3:0] ARQOS,

    // R signals
    input [3:0]RID,
    input [DATA_W - 1:0]RDATA_I,//32
    input [1:0]RRESP,
    input RLAST,
    input RVALID,
    output  RREADY, //combo
    output reg [31:0]RDATA_O,//32
    output reg [31:0] LINK_HEADER,
    output reg [4:0] wptr,
    // ERROR and STATUS signals
    output  reg cmd_done_1,// to mux_logic as select ( 1cycle pulse)
    output reg LINKHDRERR,
    output reg CMD_DONE,//done signal to data fsm
    output reg STAT_CMD_DONE, //done signal to muxlogic
    output reg AXIRDRESPERR,//address out of range error
    output reg AXIRDPOISERR,//corrupted data error
    output reg BUSERR,//any axi error assterts this
    input wire STAT_ERROR_PARTSEL
    );
    reg [4:0] temp_wptr,temp_rptr;
    reg [DATA_W - 1 : 0] fifo_temp [0:31]; 
    reg wr_en_reg;
    reg [3:0] current_state, next_state;
    reg [7:0] count;   
    reg [7:0] count1;
    reg [7:0] count2;
    reg rst_posedge_reg;
    reg  max_transfer_count;
    reg data_done_reg;
    reg link_enable_reg;
    reg STAT_ERROR_reg;
    integer i,j;
    reg count_flag;
    reg [$clog2(DATA_W/32)-1:0] chunk_cnt;
reg [DATA_W-1:0] aligned_data;
wire [$clog2(DATA_W/8)-1:0] byte_offset;

    wire cmd_error = (LINKHDRERR | AXIRDRESPERR | AXIRDPOISERR | BUSERR);
    localparam IDLE   = 4'b0001;
    localparam AR     = 4'b0010;
    localparam R      = 4'b0100;  
    localparam COUNT  = 4'b1000;
    
    assign RREADY = (current_state == R)? 1:0;
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn) begin
            data_done_reg <= 'd0;
            link_enable_reg <= 'd0;
            STAT_ERROR_reg <= 'd0;
            rst_posedge_reg <= 0;
        end
        else begin
            data_done_reg <= data_done;
            rst_posedge_reg <= rst_posedge;
            link_enable_reg <= link_enable;
            STAT_ERROR_reg <= STAT_ERROR_PARTSEL;
        end
    end
    
    always@(posedge clk or negedge resetn)
    begin
        if(!resetn)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end
    
    //combo always
    always@(*)
    begin
        case(current_state)
            IDLE:
                if(link_enable_reg && (data_done /*|| rst_posedge_reg*/) && !cmd_error && !stat_disable_intr_reg)
                next_state = AR;
                else
                next_state = IDLE;
            
            AR:
                if(cmd_error)
                next_state = IDLE;
                else if(ARREADY && ARVALID)
                next_state = R;
                else
                next_state = AR;
            
            R:
                if(cmd_error)
                next_state = IDLE;
                else if(RVALID && RREADY && RLAST && count == 0)
                next_state = COUNT;
                else  if(RVALID && RREADY && RLAST) 
                begin
                    if((((count - 1 + (byte_offset/4))/(DATA_W/32)) > 'd15) && max_transfer_count == 0 )
                    next_state = AR;
                    else
                    next_state = IDLE;
                end
                else 
                next_state = R;
            
            COUNT : begin
                if(cmd_error)
                next_state = IDLE;
                else 
                next_state = AR;
            end
            
            default : next_state = IDLE;
        endcase
    end
    
    always@(*) begin
        aligned_data = RDATA_I >> (byte_offset * 8);
        count1 = count;
        if(current_state == IDLE  ) 
            count1 = 0; 
        else if(current_state == COUNT)begin
            count1 = 0;
            for( i = 0 ; i < 32 ; i = i + 1) 
                if(!(i == 0 || i == 1 || i == 23||i == 25 || i == 27))
                    count1 = count1 + LINK_HEADER[i];
        end 
    end
    
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
            count<='d0;
        else
            count <= count1;
    end
    
    always@(posedge clk or negedge resetn)
    begin
        if(!resetn)
            wr_en_reg <= 'd0;
        else
            wr_en_reg <= wr_en;
    end
    
//    always@(posedge clk or negedge resetn) begin
//        if(!resetn)
//        RDATA_O <= 0;
//        else
//            if(ARLEN == temp_wptr) begin
//                RDATA_O <= fifo_temp[temp_rptr];
//                temp_rptr <= temp_rptr + 1;
//                end
//    end

assign byte_offset = ARADDR[$clog2(DATA_W/8)-1:0];

always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        RDATA_O   <= 32'd0;
        CMD_DONE <= 0;
        temp_rptr <= 0;
        chunk_cnt <= 0;
        wptr <= 0;
        count2 <= 0;
    end
    else begin
        CMD_DONE <= 1;
        if(temp_wptr == 0)
            temp_rptr <= 0;
        if(current_state == IDLE)
        CMD_DONE <= ( (data_done || count2 > 0) ? 0 : 1) ;
        else if (current_state == AR || current_state == COUNT )
         CMD_DONE <= 0;
        else if (current_state == R)
        CMD_DONE <= ( (count2==0 && count_flag ) ? 1 : CMD_DONE) ;

//        if(count1 > 0 && current_state == AR)
//            count2 <= count1  ;
        if(current_state == AR ) begin
            wptr <= ((count1 == 0) && !max_transfer_count)? 0 :wptr;
            chunk_cnt <= byte_offset/4;
            if(!max_transfer_count)
             count2 <= (count1 > 0)?count1:count2  ;
            else
             count2<=count2;
        end 
        // FIFO not empty
        else if (temp_rptr != temp_wptr && count2 !='h0) begin
            
            // align data for narrow / unaligned transfer
            count2 <= count2 -1 ;
           // if(count2 == 1) CMD_DONE = 1; 
            // output 32-bit chunk
            RDATA_O <= fifo_temp[temp_rptr][chunk_cnt*32 +: 32];//aligned_data[chunk_cnt*32 +: 32];
            wptr <= wptr + 1;
            // chunk progression
            if (chunk_cnt == (DATA_W/32 - 1)) begin
                chunk_cnt <= 0;
                temp_rptr <= temp_rptr + 1;   // move to next FIFO word
            end 
            else begin
                chunk_cnt <= chunk_cnt + 1;
            end
        end
    end
end
    // ERROR HANDLING ISSUE 
    always@(posedge clk or negedge resetn)
    begin
        if(!resetn)
        begin
            for(j=0;j<32;j=j+1) begin
                fifo_temp[j] <= 'd0;end
            count_flag <= 0;
            //CMD_DONE <= 0; //done signal to data fsm
            AXIRDRESPERR <= 0;//address out of range error
            AXIRDPOISERR <= 0;//corrupted data error
            BUSERR <= 0;//any axi error assterts this
            ARADDR <= 0;
            ARID   <= 0;
            ARLEN  <= 0;
            ARSIZE <= 'd2;
            ARBURST <=0;
            max_transfer_count <= 0;
             temp_wptr <= 0;
            ARVALID <=0;
            ARQOS <= 0;
           // RDATA_O <= 0;
            LINKHDRERR <= 0;
            LINK_HEADER <= 0;
            STAT_CMD_DONE <= 1'b0;
            cmd_done_1 <= 1'b0;
            
        end
        else
        begin
            //CMD_DONE <= 1'b1; 
            cmd_done_1 <= 1'b0;
            STAT_CMD_DONE <= cmd_done_1 ;
           // max_transfer_count <= (count - 1 + (byte_offset/4))/(DATA_W/32);
            ARQOS <= 0;
            case(current_state)
            
                IDLE:
                begin
                    count_flag <= 0;
                    cmd_done_1 <= (!CMD_DONE && count2 ==0  && link_enable_reg) ;
                    ARADDR <= 0;
                    ARID   <= 1;
                     max_transfer_count <= 0;
                    ARLEN  <= 0;
                    ARSIZE <= 'd2;
                    ARBURST <=0;
                    ARVALID <=0;
                    if(count2 ==0) begin
                        temp_wptr <= 0;
                        //temp_rptr <= 0;
                    end
                    if(~STAT_ERROR_PARTSEL)
                    begin
                        BUSERR <= 0;
                        AXIRDPOISERR <= 0;
                        AXIRDRESPERR <= 0;
                        LINKHDRERR <= 0;
                    end
                    if(data_done) begin
                        //CMD_DONE <= 0; 
                    end
                    if(wr_en_reg)         
                        LINK_HEADER <= 0;
                end
                
                AR: 
                begin
                    count_flag <= 0;
                    ARSIZE <= ($clog2(DATA_W/8)) ;//
                    //CMD_DONE <= 0;
                    ARVALID <= 1; 
                    ARQOS <= ch_prio;         
                    if (count == 0) begin
                        ARADDR <= next_cmd_addr;
                        ARLEN <= 0;
                         ARBURST <= 1;
                    end
                    else begin
                        ARADDR <= (max_transfer_count) ? next_cmd_addr + 20 : next_cmd_addr + 4;
                      
                        if (max_transfer_count) begin
                            ARLEN <= ((count - 1 + (byte_offset/4)) / (DATA_W/32)) - 'd15;
                        end 
                        else begin
                            if (((count - 1 + (byte_offset/4)) / (DATA_W/32)) > 'd15) begin
                                ARLEN <= 'd15;
                            end 
                            else begin
                                ARLEN <= ((count - 1 + (byte_offset/4)) / (DATA_W/32));
                            end
                        end

                        //ARLEN <= ( (max_transfer_count)? ((count - 1 + (byte_offset/4))/(DATA_W/32))-'d15 : ((count - 1 + (byte_offset/4))/(DATA_W/32)) > 'd15) ? 'd15 : ((count - 1 + (byte_offset/4))/(DATA_W/32))  ;
                        ARBURST <= 1;  //changes done
                    end
                end
                
                R:
                begin
                    //CMD_DONE <= 0;
                    ARVALID <= 0;  
                    if(RREADY && RVALID) begin
                        if(count!=0)begin
                            fifo_temp[temp_wptr] <= RDATA_I ;
                            //wptr <= wptr + 1; 
                            temp_wptr <= temp_wptr +1;
                        end
                        else if(RLAST  && !(|(( (RDATA_I >> ((ARADDR[$clog2(DATA_W/8)-1:0]) * 8)) ) & 32'hffffFFFF)))
                            LINKHDRERR <= 1;
                        else if(RLAST  && (|(((RDATA_I >> ((ARADDR[$clog2(DATA_W/8)-1:0]) * 8))) & 32'hffffFFFF)) && count ==0)begin 
                            LINK_HEADER <=(((RDATA_I >> ((ARADDR[$clog2(DATA_W/8)-1:0]) * 8))) & 32'hffffFFFF);// RDATA_I >> (byte_offset * 8);
                            temp_wptr <= 0; 
                            
                        end
                        
                        if((RRESP == 2'b00 || RRESP == 2'b01) && RLAST) 
                        begin
                            if(count!=0) begin
                                max_transfer_count <= 1;
                                //CMD_DONE <= 1'b1;
                                //cmd_done_1 <=(count2 ==1 ) 1'b1: 0;
                            end
                        end
                        else if(RRESP == 2'b11)    
                        begin
                            BUSERR <= 1'b1;
                            AXIRDRESPERR <=1'b1;
                        end
                        else if(RRESP == 2'b10)
                        begin
                            BUSERR <=1'b1;
                            AXIRDPOISERR <= 1'b1;
                        end
                    end
                end
                
                COUNT : begin
                    count_flag <= 1;
                    //CMD_DONE <= 0;               
                end
                
                default:
                begin
                    count_flag <= 0;
                    ARADDR <= 0;
                    ARID   <= 0;
                    ARLEN  <= 0;
                    ARSIZE <= 3'b111;
                    ARBURST <=0;
                    ARVALID <=0;
                end
            endcase 
        end
    end
    
endmodule   
 

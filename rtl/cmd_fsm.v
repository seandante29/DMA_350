module cmd_fsm (
    input clk, 
    input resetn,
    input [31:0]LINKADDR,// fro intern reg
    input link_enable,// fro intern reg
    input data_done,// fro intern reg
    input wire wr_en,//or of every write enable 
    input wire stat_disable_intr_reg,
    // AR signals
    input ARREADY,
    output reg [3:0] ARID,
    output reg [3:0] ARLEN,
    output reg[2:0] ARSIZE,
    output reg [1:0] ARBURST,
    output reg ARVALID,
    output reg [31:0]ARADDR,
    // R signals
    input [3:0]RID,
    input [127:0]RDATA_I,//32
    input [1:0]RRESP,
    input RLAST,
    input RVALID,
    output reg RREADY,
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
    
    reg wr_en_reg;
    reg [3:0] current_state, next_state;
    reg [3:0] count;   
    reg [3:0] count1;
    reg data_done_reg;
    reg link_enable_reg;
    reg STAT_ERROR_reg;
    integer i;
    wire cmd_error = (LINKHDRERR | AXIRDRESPERR | AXIRDPOISERR | BUSERR);
    localparam IDLE   = 4'b0001;
    localparam AR     = 4'b0010;
    localparam R      = 4'b0100;  
    localparam COUNT  = 4'b1000;
    
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn) begin
            data_done_reg <= 'd0;
            link_enable_reg <= 'd0;
            STAT_ERROR_reg <= 'd0;
        end
        else begin
            data_done_reg <= data_done;
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
                if(link_enable_reg && data_done && !cmd_error && !stat_disable_intr_reg)
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
                next_state = IDLE;
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
        count1 = count;
        if(current_state == IDLE  ) 
            count1 = 0; 
        else if(current_state == COUNT)begin
            count1 = 0;
            for( i = 1 ; i < 31 ; i = i + 1) 
                count1 = count1 + RDATA_I[i];
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
    
    // ERROR HANDLING ISSUE 
    always@(posedge clk or negedge resetn)
    begin
        if(!resetn)
        begin
            CMD_DONE <= 0; //done signal to data fsm
            AXIRDRESPERR <= 0;//address out of range error
            AXIRDPOISERR <= 0;//corrupted data error
            BUSERR <= 0;//any axi error assterts this
            ARADDR <= 0;
            ARID   <= 0;
            ARLEN  <= 0;
            ARSIZE <= 'd2;
            ARBURST <=0;
            ARVALID <=0;
            RREADY <= 0;
            RDATA_O <= 0;
            LINKHDRERR <= 0;
            LINK_HEADER <= 0;
            STAT_CMD_DONE <= 1'b0;
            cmd_done_1 <= 1'b0;
            wptr <= 0;
        end
        else
        begin
            CMD_DONE <= 1'b1; 
            cmd_done_1 <= 1'b0;
            STAT_CMD_DONE <= cmd_done_1 ; 
            case(current_state)
            
                IDLE:
                begin
                    ARADDR <= 0;
                    ARID   <= 1;
                    ARLEN  <= 0;
                    ARSIZE <= 'd2;
                    ARBURST <=0;
                    ARVALID <=0;
                    RREADY <= 0;
                    if(~STAT_ERROR_PARTSEL)
                    begin
                        BUSERR <= 0;
                        AXIRDPOISERR <= 0;
                        AXIRDRESPERR <= 0;
                        LINKHDRERR <= 0;
                    end
                    if(data_done) begin
                        CMD_DONE <= 0; 
                    end
                    if(wr_en_reg)         
                        LINK_HEADER <= 0;
                end
                
                AR: 
                begin
                    ARSIZE <= 'd2;
                    CMD_DONE <= 0;
                    ARVALID <= 1;          
                    RREADY <= 0;
                    if (count == 0) begin
                        ARADDR <= LINKADDR;
                        ARLEN <= 0;
                    end
                    else begin
                        ARADDR <= LINKADDR + 4;
                        ARLEN <= count - 1;
                    end
                end
                
                R:
                begin
                    CMD_DONE <= 0;
                    RREADY  <= 1;
                    ARVALID <= 0;  
                    if(RREADY && RVALID) begin
                        if(count!=0)begin
                            RDATA_O <= RDATA_I [31:0];
                            wptr <= wptr + 1; 
                        end
                        else if(RLAST  && !(|RDATA_I[31:0]))
                            LINKHDRERR <= 1;
                        else if(RLAST  && (|RDATA_I[31:0]) && count ==0)begin 
                            LINK_HEADER <= RDATA_I[31:0];
                            wptr <= 0;
                        end
                    
                        if((RRESP == 2'b00 || RRESP == 2'b01) && RLAST) 
                        begin
                            if(count!=0) begin
                                CMD_DONE <= 1'b1;
                                cmd_done_1 <= 1'b1;
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
                    CMD_DONE <= 0;
                end
                
                default:
                begin
                    ARADDR <= 0;
                    ARID   <= 0;
                    ARLEN  <= 0;
                    ARSIZE <= 3'b111;
                    ARBURST <=0;
                    ARVALID <=0;
                    RREADY <= 0;
                end
            endcase 
        end
    end
    
endmodule   

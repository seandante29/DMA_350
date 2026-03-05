module apb_slave #( parameter DATA_WIDTH = 32,
     parameter ADDR_WIDTH = 32, 
     parameter STRB_WIDTH = DATA_WIDTH/8
      )
     (
     //APB4 signals
     input wire PCLK,
     input wire PRESETn,
     input wire [ ADDR_WIDTH-1 : 0 ] PADDR,
     input wire PWRITE,
     input wire PSEL,
     input wire PENABLE,
     input wire [ DATA_WIDTH-1 : 0 ]PWDATA,
     input wire [ STRB_WIDTH-1 : 0 ] PSTRB,
     output reg [ DATA_WIDTH-1 : 0 ]PRDATA,
     output wire PREADY,
     output reg PSLVERR,
     
     //REGISTER BANK signals
     input wire [ DATA_WIDTH-1 : 0 ]cfg_rdata,//from reg to apb
     output reg [ DATA_WIDTH-1 : 0 ]cfg_wdata,// to reg bank
     output reg [ ADDR_WIDTH-1 : 0 ]cfg_addr,// to reg bank
     output reg cfg_wr_en,cfg_rd_en// to reg bank
     );
    localparam IDLE_ST   = 3'b001;
    localparam SETUP_ST  = 3'b010;
    localparam ACCESS_ST = 3'b100;
    
    
    reg [2:0] current_state, next_state;
    reg PWRITE_q;
    reg [ DATA_WIDTH-1 : 0 ]PWDATA_q;
    reg [ STRB_WIDTH-1 : 0 ]PSTRB_q;
    
    wire strobe_error_q;
    assign strobe_error_q = PWRITE_q && (PSTRB_q != {STRB_WIDTH{1'b1}});
    wire RO_error = (( cfg_addr == 'h80 | cfg_addr == 'h8C | cfg_addr == 'h90 ) & PWRITE_q);
    wire address_error = (! (cfg_addr >=0 && cfg_addr <=144));
    assign PREADY = (current_state == ACCESS_ST)? 1 : 0;
    
    always@(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
        current_state <= IDLE_ST;
        else
        current_state <= next_state;
    end
    
    always@(*)
    begin
        case(current_state)
        
            IDLE_ST:
            begin
                next_state = (PSEL && !PENABLE) ? SETUP_ST : IDLE_ST;
            end
            
            SETUP_ST:
            begin
                next_state = (PSEL && PENABLE) ? ACCESS_ST : SETUP_ST;
            end
            
            ACCESS_ST:
            begin
                next_state = (PREADY) ? (PSEL ? SETUP_ST : IDLE_ST) : ACCESS_ST; 
            end
            
            default: 
            begin
                next_state = IDLE_ST;
            end
        endcase
    end
    
    always@(posedge PCLK or negedge PRESETn)
    begin
        if(!PRESETn)
        begin
            PWRITE_q <= 1'b0;
            PWDATA_q <= {DATA_WIDTH{1'b0}};
            PSLVERR   <= 'd0;
            PSTRB_q <= {STRB_WIDTH{1'b0}};
            cfg_wr_en <= 1'b0;            
            cfg_rd_en <= 1'b0;               
            cfg_addr  <= {ADDR_WIDTH{1'b0}}; 
            cfg_wdata <= {DATA_WIDTH{1'b0}}; 
            PRDATA <= 'd0;
        end
        else begin
            cfg_wr_en <= 1'b0;
            cfg_rd_en <= 1'b0;
            PSLVERR   <= 1'b0; 
            case(current_state)
            
                SETUP_ST:
                begin
                    cfg_addr <= PADDR;
                    PWRITE_q <= PWRITE;
                    PWDATA_q <= PWDATA;
                    PSTRB_q  <= PSTRB;
                    PSLVERR   <= 1'b0;  
                    cfg_rd_en <= (!PWRITE)? 1'b1 : 1'b0;
                end
                
                ACCESS_ST:
                begin
                    PSLVERR <= strobe_error_q | RO_error | address_error;
                    if(PWRITE_q) begin
                        cfg_wdata <= PWDATA_q;
                        cfg_wr_en <= 1'b1;
                    end
                    else begin
                        PRDATA    <= cfg_rdata;
                    end
                end
                
                default:
                begin
                    PSLVERR <= 1'b0;
                end
            endcase
        end
    end 
endmodule
     

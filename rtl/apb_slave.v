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
     input wire enable_cmd_to_apb,
     input wire PENABLE,
     input wire [ DATA_WIDTH-1 : 0 ]PWDATA,
     input wire [ STRB_WIDTH-1 : 0 ] PSTRB,
     output reg [ DATA_WIDTH-1 : 0 ]PRDATA,
   //  output wire PREADY,
     output reg PREADY,
     output reg PSLVERR,
     
     //REGISTER BANK signals
     input wire [ DATA_WIDTH-1 : 0 ]cfg_rdata,//from reg to apb
     output reg [ DATA_WIDTH-1 : 0 ]cfg_wdata,// to reg bank
     output reg [ ADDR_WIDTH-1 : 0 ]cfg_addr,// to reg bank
     output reg cfg_wr_en,cfg_rd_en,// to reg bank
    input wire [31:0] read_base_addr_UPDATED,cfg_read_base_addr,
    input wire [31:0]  write_base_addr_UPDATED,cfg_write_base_addr,
    input wire [31:0]  x_transfer_count_UPDATED,cfg_x_transfer_count,y_transfer_count_UPDATED,cfg_y_transfer_count,
    output wire stop_cmd_apb
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
     assign stop_cmd_apb = (current_state == ACCESS_ST && PREADY && PWRITE == 1 && PENABLE && PADDR == 'h1000 && PWDATA[3] && enable_cmd_to_apb)?1:0;
    wire RO_error = (( cfg_addr == 'h1080 | cfg_addr == 'h108C | cfg_addr == 'h1090 ) & PWRITE_q);
    wire address_error = (! (cfg_addr >='h1000 && cfg_addr <='h1090));
 //   assign PREADY = (current_state == ACCESS_ST)? 1 : 0;
    always@(*)begin
      if(current_state == ACCESS_ST && PREADY && PWRITE == 0 && PENABLE )
         begin
         if((cfg_addr == 'h1010))
                      PRDATA = (enable_cmd_to_apb) ?  read_base_addr_UPDATED : cfg_read_base_addr;
         else if((cfg_addr == 'h1018))
                      PRDATA = (enable_cmd_to_apb) ? write_base_addr_UPDATED : cfg_write_base_addr;
         else if((cfg_addr == 'h1020))
                     PRDATA = (enable_cmd_to_apb) ? x_transfer_count_UPDATED : cfg_x_transfer_count;
        else if((cfg_addr == 'h103C))
                     PRDATA = (enable_cmd_to_apb) ? y_transfer_count_UPDATED : cfg_y_transfer_count;
          else
                      PRDATA = cfg_rdata;
    end
    else
                        PRDATA = 0;
    end
    reg [4:0]count;


       always@(*)
    begin
        if(current_state == ACCESS_ST)
        begin
            if(PWRITE)
                PREADY =1;
            else 
            begin
                if( ((((cfg_addr == 'h1010)||(cfg_addr == 'h1018)||(cfg_addr == 'h1020)||(cfg_addr == 'h103C))  && enable_cmd_to_apb) || cfg_addr == 'h1004)) begin
                    if(((cfg_addr == 'h1004)&&count == 6)||((cfg_addr == 'h1010)&&count == 1) ||(((cfg_addr == 'h1018)&&count == 1))||(((cfg_addr == 'h1020)&&count == 1 ||(cfg_addr == 'h103C) && count == 1 /*&& enable_cmd_to_apb*/)))
                        PREADY =1;
                    else 
                        PREADY =0;    end
                else if((((cfg_addr == 'h1020) || (cfg_addr == 'h1018) || (cfg_addr == 'h1010) ||(cfg_addr == 'h1090)||(cfg_addr == 'h1088) ||(cfg_addr == 'h108C)
                || (cfg_addr == 'h1078) ||(cfg_addr == 'h1074)||(cfg_addr == 'h1054) ||(cfg_addr == 'h1050) ||(cfg_addr == 'h104C) ||(cfg_addr == 'h1048) ||(cfg_addr == 'h1044)
                 ||(cfg_addr == 'h1040) ||(cfg_addr == 'h103C) ||(cfg_addr == 'h1038) ||(cfg_addr == 'h1034) ||(cfg_addr == 'h1030) ||(cfg_addr == 'h102C) 
                 ||(cfg_addr == 'h1028) ||(cfg_addr == 'h100C) ||(cfg_addr == 'h1008) ) && count == 2) ||((cfg_addr == 'h1000) && count ==3))
                     PREADY =1;
                    
                else 
                    PREADY =0;
            end
        end
        else
            PREADY =0;
    end
 
    
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
                next_state = (PREADY && PENABLE) ? (PSEL ? SETUP_ST : IDLE_ST) : ACCESS_ST; 
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
            count<=0;
            PWRITE_q <= 1'b0;
            PWDATA_q <= {DATA_WIDTH{1'b0}};
            PSLVERR   <= 'd0;
            PSTRB_q <= {STRB_WIDTH{1'b0}};
            cfg_wr_en <= 1'b0;            
            cfg_rd_en <= 1'b0;               
            cfg_addr  <= {ADDR_WIDTH{1'b0}}; 
            cfg_wdata <= {DATA_WIDTH{1'b0}}; 
        end
        else begin
            cfg_wr_en <= 1'b0;
            cfg_rd_en <= 1'b0;
            PSLVERR   <= 1'b0; 
            if(current_state== ACCESS_ST)
                 begin
                if((cfg_addr == 'h1004))
                    count <= count[3:0]+1;
                else if((cfg_addr == 'h1020) && enable_cmd_to_apb)
                    count <= count[3:0]+1;
                else if((cfg_addr == 'h1010) || (cfg_addr == 'h1018))
                    count <= count[3:0]+1;
//               else if(((cfg_addr == 'h1010) || (cfg_addr == 'h1018))&& (count == 2) && !enable_cmd_to_apb)
//                   count <= 0; 
                else if(((cfg_addr == 'h1010) || (cfg_addr == 'h1018) || (cfg_addr == 'h1020))&& (count == 1) && enable_cmd_to_apb)
                   count <= 0; 
                else if((cfg_addr == 'h1038) || (cfg_addr == 'h1020) || (cfg_addr == 'h1078)||(cfg_addr == 'h1074) ||(cfg_addr == 'h1054)
                 ||(cfg_addr == 'h1050) ||(cfg_addr == 'h104C) ||(cfg_addr == 'h1044)
                 ||(cfg_addr == 'h1040) ||(cfg_addr == 'h103C) ||(cfg_addr == 'h1038) ||(cfg_addr == 'h1034)||(cfg_addr == 'h1030) ||(cfg_addr == 'h102C) 
                 ||(cfg_addr == 'h1028) ||(cfg_addr == 'h100C) ||(cfg_addr == 'h1008) ||(cfg_addr == 'h1000)
                  ||(cfg_addr == 'h1090)||(cfg_addr == 'h1088) ||(cfg_addr == 'h108C) )
                    count <= count[3:0]+1;      
                   
           
                 end
                else
                   begin
                      count<=0;
                   end
            case(current_state)
            
                SETUP_ST:
                begin
                    cfg_addr <= PADDR;
                    PWRITE_q <= PWRITE;
                    PWDATA_q <= (cfg_addr == 'h1000 && enable_cmd_to_apb)?{PWDATA[31:1],1'b0}:PWDATA;
                    PSTRB_q  <= PSTRB;
                    PSLVERR   <= 1'b0;  
                    cfg_rd_en <= (!PWRITE)? 1'b1 : 1'b0;
                end
                
                ACCESS_ST:
                begin
                    cfg_rd_en <= (!PWRITE)? 1'b1 : 1'b0;
                    PSLVERR <= strobe_error_q | RO_error | address_error;
                    if(PWRITE_q) begin
                        cfg_wdata <= PWDATA_q;
                        cfg_wr_en <= 1'b1;
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
     
 

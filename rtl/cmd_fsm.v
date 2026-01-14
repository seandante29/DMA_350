`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/08/2026 12:16:27 PM
// Design Name: 
// Module Name: cmd_fsm
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

module cmd_fsm (input clk, 
      input resetn,
      input [31:0]LINKADDR,
      input link_enable,
      input data_done,
      // AR signals
      input ARREADY,
      output reg [3:0] ARID,
      output reg [3:0] ARLEN,
      output reg[2:0] ARSIZE,
      output reg [1:0] ARBURST,
      output reg ARVALID,
      output reg [31:0]ARADDR,
      // R signals
      input RID,
      input [31:0]RDATA_I,
      input [1:0]RRESP,
      input RLAST,
      input RVALID,
      output reg RREADY,
      output reg [31:0]RDATA_O,
      output reg [31:0] LINK_HEADER,
      output reg [5:0] wptr,
      // ERROR and STATUS signals
      output reg LINKHDRERR,
      output reg CMD_DONE, //done signal to data fsm
      output reg AXIRDRESPERR,//address out of range error
      output reg AXIRDPOISERR,//corrupted data error
      output reg BUSERR,//any axi error assterts this
      input wire STAT_ERROR
      );
      
   reg [3:0] current_state, next_state;
   reg [4:0] count;
    reg [4:0] count1;
   reg [5:0] i;
   localparam IDLE   = 4'b0001;
   localparam AR     = 4'b0010;
   localparam R      = 4'b0100;  
   localparam COUNT  = 4'b1000;
   
   
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
        if(link_enable && data_done && !STAT_ERROR)
         next_state = AR;
        else
         next_state = IDLE;
         
       AR:
        if(ARREADY && ARVALID)
         next_state = R;
        else
         next_state = AR;
         
       R:
        //if((RVALID && RREADY && RLAST && count == 0) )//|| (|RDATA_I != 1))///RDATAI/ rdatao?
          //  next_state = IDLE;
          if(STAT_ERROR)
        next_state = IDLE;
       else if(RVALID && RREADY && RLAST && count == 0)
        //if(RRESP==2'b00 || RRESP==2'b01)
         next_state = COUNT;
        else  if(RVALID && RREADY && RLAST)  //and |RDATA != 1 nextstate = idle
         next_state = IDLE;
        else 
         next_state = R;
         
       COUNT : begin
         next_state = AR;
        end
             
       default : next_state = IDLE;
       endcase
   end
   
   always@(*) begin
        if(current_state == IDLE ) 
            count = 0;
        if(current_state == COUNT && count == 0 )
            for( i = 1 ; i < 31 ; i = i + 1) count = count + RDATA_I[i];
   end
   
   always@(posedge clk or negedge resetn)
    begin
    if(!resetn)
    count1<='d0;
    else if(count1 == count)
    count1<=0;
    else if(current_state == COUNT && count == 0 )
    count1<=count1+1;
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
        ARSIZE <= 4'b1111;
        ARBURST <=0;
        ARVALID <=0;
        RREADY <= 0;
        RDATA_O <= 0;
        LINKHDRERR <= 0;
   end
   else
   begin
        CMD_DONE <= 1; // temp fix for deasserting
        case(current_state)
            IDLE:
            begin
                ARADDR <= 0;
                ARID   <= 0;
                ARLEN  <= 0;
                ARSIZE <= 4'b1111;
                ARBURST <=0;
                ARVALID <=0;
                RREADY <= 0;
                if(~STAT_ERROR)
                 begin
                  BUSERR <= 0;
                  AXIRDPOISERR <= 0;
                  AXIRDRESPERR <= 0;
                  LINKHDRERR <= 0;
                 end
              //  RDATA_O <= 0;
            end
            
            AR: 
            begin
             CMD_DONE <= 0;
                if (count == 0) begin
                    ARADDR <= LINKADDR;
                    ARLEN <= 0;
                   
               end
               else begin
                    ARADDR <= LINKADDR + 4;
                    ARLEN <= count - 1;
               end
               ARVALID <= 1;          
            end
            
            R:
            begin
             CMD_DONE <= 0;
                RREADY  <= 1;
                ARVALID <= 0;  //just added
                if(RREADY && RVALID) begin
                    if(count!=0)begin
                    RDATA_O <= RDATA_I;
                    wptr <= wptr + 1; 
                    end
                    if(RLAST  && !(|RDATA_I))
                        LINKHDRERR <= 1;
                    if(RLAST  && (|RDATA_I) && count ==0)begin //count==0
                        LINK_HEADER <= RDATA_I;
                        wptr <= 0;
                        end
                 end
                        
                if((RRESP == 2'b00 || RRESP == 2'b01) && RLAST) 
                // if(RRESP == 2'b00 || RRESP == 2'b01)
                    begin
                    if(count!=0)
                    CMD_DONE <= 1'b1;
                    end
                else if(RRESP == 2'b11)    // error handling TBD
                    begin
                        if(RLAST)begin
                        BUSERR <= 1'b1;
                        AXIRDRESPERR <=1'b1;
                        end
                    end
                else if(RRESP == 2'b10)
                    begin
                        if(RLAST)begin
                        BUSERR <=1'b1;
                        AXIRDPOISERR <= 1'b1;
                        end
                    end
            end
            
            COUNT : begin
             CMD_DONE <= 0;
              //  for( i = 1 ; i < 31 ; i = i + 1) count = count + rdata[i];
            end
            
            default:
            begin
                ARADDR <= 0;
                ARID   <= 0;
                ARLEN  <= 0;
                ARSIZE <= 4'b1111;
                ARBURST <=0;
                ARVALID <=0;
                RREADY <= 0;
              //  RDATA_O <= 0;
            end
            endcase 
   end
   end
   
endmodule
 
 
 

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
      input [31:0]LINKADDR,// fro intern reg
      input link_enable,// fro intern reg
      input data_done,// fro intern reg
      input wire cmd_done_stop,//not used
      input wire wr_en,//or of every write enable 
      input wire STAT_DISABLE_DATA,
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
      output  reg cmd_done_1,// to mux_logic as select ( 1cycle pulse)
      output reg LINKHDRERR,
      output reg CMD_DONE,//done signal to data fsm
      output reg STAT_CMD_DONE, //done signal to muxlogic
      output reg AXIRDRESPERR,//address out of range error
      output reg AXIRDPOISERR,//corrupted data error
      output reg BUSERR,//any axi error assterts this
      input wire STAT_ERROR_PARTSEL
      );
    //reg cmd_done_1;// to mux_logic as select ( 1cycle pulse)
    reg wr_en_reg;
    reg [3:0] current_state, next_state;
    reg [4:0] count;
   // reg [4:0] count1;
    reg [5:0] i;
    reg data_done_reg;
    reg link_enable_reg;
    reg STAT_ERROR_reg;
    wire cmd_error = !(LINKHDRERR | AXIRDRESPERR | AXIRDPOISERR | BUSERR);
   localparam IDLE   = 4'b0001;
   localparam AR     = 4'b0010;
   localparam R      = 4'b0100;  
   localparam COUNT  = 4'b1000;
   //temp fix
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
        if(link_enable_reg && data_done && cmd_error)
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
          if(STAT_ERROR_PARTSEL)
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
        if(current_state == IDLE  ) 
            count = 0;
        if(current_state == COUNT && count == 0 )
            for( i = 1 ; i < 31 ; i = i + 1) count = count + RDATA_I[i];
   end
   
  /* always@(posedge clk or negedge resetn)
    begin
    if(!resetn)
    count1<='d0;
    else if(count1 == count)
    count1<=0;
    else if(current_state == COUNT && count == 0 )
    count1<=count1+1;
    end*/
   
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
        ARSIZE <= 4'b1111;
        ARBURST <=0;
        ARVALID <=0;
        RREADY <= 0;
        RDATA_O <= 0;
        LINKHDRERR <= 0;
        LINK_HEADER <= 0;
        STAT_CMD_DONE <= 1'b0;
        cmd_done_1 <= 1'b0;
   end
   else
   begin
     CMD_DONE <= 1'b1; // temp fix for deasserting
     cmd_done_1 <= 1'b0;
     STAT_CMD_DONE <= cmd_done_1 ; 
      if(wr_en_reg)         LINK_HEADER <= 0;
       //CMD_DONE <= (cmd_done_stop) ? 'b0 :  'b1; //
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
                if(~STAT_ERROR_PARTSEL)
                 begin
                  BUSERR <= 0;
                  AXIRDPOISERR <= 0;
                  AXIRDRESPERR <= 0;
                  LINKHDRERR <= 0;
                 end
                 //STAT_CMD_DONE <= 1'b0;
                 if(data_done) begin
                    CMD_DONE <= 0; 
                   /// STAT_CMD_DONE <= 1'b0;
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
               RREADY <= 0;
            end
            
            R:
            begin
             CMD_DONE <= 0;
                RREADY  <= 1;
                ARVALID <= 0;  //just added
               // if(wptr + 1 == count && count != 0) //STAT_CMD_DONE <= 1; 
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
                 
                        
                    if((RRESP == 2'b00 || RRESP == 2'b01) && RLAST) 
                    // if(RRESP == 2'b00 || RRESP == 2'b01)
                        begin
                        if(count!=0) begin
                            CMD_DONE <= 1'b1;
                           cmd_done_1 <= 1'b1;
                          // STAT_CMD_DONE <= 1; 
                            end
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

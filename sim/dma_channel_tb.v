_channel_tb(   );
parameter WIDTH = 32;

     reg clk,resetn;                 
     reg [(WIDTH * 14) -1:0] reg_chn_in;


     reg ARREADY;
     reg RID;
     reg [31:0]RDATA_I;
     reg [1:0]RRESP;
     reg RLAST;
     reg RVALID;
     reg data_done;
     reg linkaddren;
     
       wire [(WIDTH*2)-1 : 0] chn_reg_out;                       
       wire IRQ;
       wire [3:0] ARID;
       wire [3:0] ARLEN;
       wire[2:0] ARSIZE;
       wire [1:0] ARBURST;
       wire ARVALID;
       wire [31:0]ARADDR;
       wire RREADY;
       
     
     dma_channel dut( .clk(clk),
                                     .resetn(resetn),
                                     .ARREADY(ARREADY),
                                     .RID(RID),
                                     .RDATA_I(RDATA_I),
                                     .RRESP(RRESP),
                                     .RLAST(RLAST),
                                     .RVALID(RVALID),
                                     .data_done(data_done),
                                     .linkaddren(linkaddren),
                                     
                                     .chn_reg_out(chn_reg_out),
                                     .IRQ(IRQ),
                                     .ARID(ARID),
                                     .ARLEN(ARLEN),
                                     .ARSIZE(ARSIZE),
                                     .ARBURST(ARBURST),
                                     .ARVALID(ARVALID),
                                    . ARADDR(ARADDR),
                                    .RREADY(RREADY)
     );  
       
     
     always #5 clk = ~clk;
     
     
     initial begin
     
     $monitor (" cmd_data_in %h \n,concat_cmd %h\n,mux_out_reg %h",dut.dut3.cmd_data_in,dut.dut3.concat_cmd,dut.dut3.mux_out_reg);
     end
     initial 
     begin
     
     clk = 0;
     resetn = 0;
     #20 resetn = 1;
     data_done = 1;
     linkaddren = 1;
     reg_chn_in = 'hAAAAAAAA_AABBBBAA_AACCCCAA_BBAABBAA;
    
     #20;
     ARREADY = 1;
     #30
     ARREADY = 0;
     RVALID = 1;
     RRESP = 'b00;
     RDATA_I = 'h055C;
     RLAST = 1;
     #10 RLAST = 0;
     ARREADY = 1;
     #30
     ARREADY = 0;
     RDATA_I = 'hABC0;
     #10 RDATA_I = 'hABC1;
     #10 RDATA_I = 'hABC2;
     #10 RDATA_I = 'hABC3;
     #10 RDATA_I = 'hABC4;
     #10 RDATA_I = 'hABC5;
     RLAST = 1;
     #10 RLAST = 0;
     
     #200 $finish;
     
     end
        
endmodule


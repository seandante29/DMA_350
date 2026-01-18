module register_bank #(parameter WIDTH = 32,
      parameter DEPTH = 145)
     (input wire clk,
      input wire resetn,
      input wire cfg_rd_en,cfg_wr_en,chn_wr_en_i,// write enable from apb to reg, channel
      input wire [ WIDTH-1 : 0] cfg_data_in,//from apb to reg
      input wire [ 7:0 ] addr_in,// from apb
      input wire [(WIDTH*2)-1 : 0] chn_reg_in,// from channel 
      output reg [ WIDTH-1 : 0] cfg_data_out, // to apb
     // output wire chn_wr_en_o, //to channel
      output wire [(WIDTH * 15) -1 : 0] reg_chn_out); // to  channel
      
      reg [ WIDTH-1:0 ] reg_mem [ 0:DEPTH-1 ];
      wire [7:0] addr_w; 
      assign addr_w = addr_in & 8'b11111100;
      assign reg_chn_out = { reg_mem[120],reg_mem[84],reg_mem[80],reg_mem[76],reg_mem[56],reg_mem[48],reg_mem[44],reg_mem[40],reg_mem[32],
                             reg_mem[24],reg_mem[16],reg_mem[12],reg_mem[8],reg_mem[4],reg_mem[0]};
          // assign reg_chn_out = { reg_mem[0],reg_mem[4],reg_mem[8],reg_mem[12],reg_mem[16],reg_mem[24],reg_mem[32],reg_mem[40],reg_mem[44],
             //                reg_mem[48],reg_mem[56],reg_mem[76],reg_mem[80],reg_mem[84],reg_mem[120]};
    //  assign chn_wr_en_o = cfg_wr_en;
      integer i;
      always @(posedge clk or negedge resetn)
  begin
  if(!resetn) begin
   for(i=0;i<DEPTH;i=i+1)
    reg_mem [i] <= {WIDTH{1'b0}};
   cfg_data_out <= {WIDTH{1'b0}};                       //IS THIS REQUIRED?
   end
  else 
   begin
   if(cfg_wr_en)begin
    if(reg_mem[0][0]) 
    reg_mem[addr_w] <= reg_mem[addr_w];
    else
    reg_mem [addr_w] <= cfg_data_in;
    end
   else if(chn_wr_en_i)
    {reg_mem [4] , reg_mem[144]} <= chn_reg_in;
     
   else if(cfg_rd_en)
    cfg_data_out <= reg_mem [addr_w];
   end
  end
endmodule 

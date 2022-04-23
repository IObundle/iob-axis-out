`timescale 1ns/1ps
`include "iob_lib.vh"
`include "iob_axistream_out_swreg_def.vh"

module iob_axistream_out 
  # (
     parameter DATA_W = 32, //PARAM CPU data width
     parameter ADDR_W = `iob_axistream_out_swreg_ADDR_W, //MACRO CPU address section width
	  parameter FIFO_DEPTH_LOG2 = 15
     )

  (

   //CPU interface
`include "iob_s_if.vh"

   //additional inputs and outputs
   `IOB_OUTPUT(tdata, 8),
   `IOB_OUTPUT(tvalid, 1),
   `IOB_INPUT(tready, 1),
   `IOB_OUTPUT(tlast, 1), 
`include "gen_if.vh"
   );

//BLOCK Register File & Configuration control and status register file.
`include "iob_axistream_out_swreg.vh"
`include "iob_axistream_out_swreg_gen.vh"

   //FIFO RAM
   `IOB_WIRE(ext_mem_w_en, 1)                                                                                                                                                                                                                                       
   `IOB_WIRE(ext_mem_w_data, 9)
   `IOB_WIRE(ext_mem_w_addr, FIFO_DEPTH_LOG2)
   `IOB_WIRE(ext_mem_r_en, 1)
   `IOB_WIRE(ext_mem_r_data, 9)
   `IOB_WIRE(ext_mem_r_addr, FIFO_DEPTH_LOG2)
   
   `IOB_WIRE(fifo_empty, 1)
   `IOB_WIRE(fifo_write, 1)
   `IOB_WIRE(axi_stream_next_delayed, 1)
   //Only allow 1 clock with fifo_write enabled between toggles of AXISTREAMOUT_NEXT
   `IOB_REG(clk, axi_stream_next_delayed, AXISTREAMOUT_NEXT) always @(posedge CLK) OUT <= IN;
   assign fifo_write = AXISTREAMOUT_NEXT & ~axi_stream_next_delayed;
   
  
   iob_fifo_sync
     #(
       .W_DATA_W (9),
       .R_DATA_W (9),
       .ADDR_W (FIFO_DEPTH_LOG2)
       )
   fifo
     (
      .arst            (1'd0),
      .rst             (rst),
      .clk             (clk),
      .ext_mem_w_en    (ext_mem_w_en),
      .ext_mem_w_data  (ext_mem_w_data),
      .ext_mem_w_addr  (ext_mem_w_addr),
      .ext_mem_r_en    (ext_mem_r_en),
      .ext_mem_r_addr  (ext_mem_r_addr),
      .ext_mem_r_data  (ext_mem_r_data),
      //read port
      .r_en            (tready),
      .r_data          ({tdata, tlast}),
      .r_empty         (fifo_empty),
      //write port
      .w_en            (fifo_write),
      .w_data          ({AXISTREAMOUT_IN,AXISTREAMOUT_TLAST}), //Store TLAST signal in lsb
      .w_full          (AXISTREAMOUT_FULL),
      .level           ()
      );
  
   `IOB_WIRE2WIRE(~fifo_empty, tvalid)

   //FIFO RAM
   iob_ram_2p #(
      .DATA_W (9),
      .ADDR_W (FIFO_DEPTH_LOG2)
    )
   input_fifo_memory
   (
      .clk      (clk),
      .w_en     (ext_mem_w_en),
      .w_data   (ext_mem_w_data),
      .w_addr   (ext_mem_w_addr),
      .r_en     (ext_mem_r_en),
      .r_data   (ext_mem_r_data),
      .r_addr   (ext_mem_r_addr)
   );

   
endmodule



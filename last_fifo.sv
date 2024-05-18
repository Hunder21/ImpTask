module last_fifo
#
(
    parameter DATA_DEPTH = 8
)
(
    input logic clk,
    input logic rst_n,
    input logic s_data_i,
    // input logic s_last_i,
    // input logic s_valid_i,
    input logic push, 
    input logic pop,
    // output logic fifo_ready,
    
    output logic full,
    output logic empty,

    output logic read_data,
    // output logic keep_o
    output logic any_up
);

    logic [DATA_DEPTH-1:0] internal_memmory;
    localparam ADDRESS_WIDTH = $clog2(DATA_DEPTH);
    logic [ADDRESS_WIDTH-1:0] rd_pointer, wr_pointer;
    logic [ADDRESS_WIDTH:0] ext_rd_pointer, ext_wr_pointer;

    assign rd_pointer = ext_rd_pointer[ADDRESS_WIDTH-1:0];
    assign wr_pointer = ext_wr_pointer[ADDRESS_WIDTH-1:0];

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            ext_rd_pointer <= '0;
        else if (pop) begin
            ext_rd_pointer <= ext_rd_pointer + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            ext_wr_pointer <= '0;
        else if (push)
            ext_wr_pointer <= ext_rd_pointer + 1'b1;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n)
            internal_memmory <= '0;
				
        else begin 
		  if (push)
            internal_memmory[wr_pointer] <= s_data_i;
		  if(pop)
			   internal_memmory[rd_pointer] <= 1'b0;
			end
    end

    assign read_data = internal_memmory[rd_pointer];

    assign full = (rd_pointer == wr_pointer) & (ext_rd_pointer[ADDRESS_WIDTH] == ext_wr_pointer[ADDRESS_WIDTH]);

    assign empty = (rd_pointer == wr_pointer) & (ext_rd_pointer[ADDRESS_WIDTH] != ext_wr_pointer[ADDRESS_WIDTH]);

    assign any_up = |internal_memmory;
endmodule
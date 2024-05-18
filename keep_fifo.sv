module keep_fifo
#
(
    parameter DATA_DEPTH = 8,
              T_DATA_RATIO = 2
)
(
    input logic clk,
    input logic rst_n,
    input logic [T_DATA_RATIO-1:0] s_data_i,
    // input logic s_last_i,
    // input logic s_valid_i,
    input logic push, 
    input logic pop,
    // output logic fifo_ready,
    
    output logic full,
    output logic empty,

    output logic [T_DATA_RATIO-1:0] read_data
    // output logic keep_o
);

    logic [T_DATA_RATIO-1:0] internal_memmory[DATA_DEPTH];
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
            ext_wr_pointer <= ext_wr_pointer + 1'b1;
    end

    always_ff @(posedge clk) begin
        if (push)
            internal_memmory[wr_pointer] <= s_data_i;
    end

    assign read_data = internal_memmory[rd_pointer];

    assign full = (rd_pointer == wr_pointer) & (ext_rd_pointer[ADDRESS_WIDTH] == ext_wr_pointer[ADDRESS_WIDTH]);

    assign empty = (rd_pointer == wr_pointer) & (ext_rd_pointer[ADDRESS_WIDTH] != ext_wr_pointer[ADDRESS_WIDTH]);
endmodule
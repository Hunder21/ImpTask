`timescale 1ns/1ns
module testbench;

logic clk, rst_n;
logic [31:0] s_data_i;
logic s_last_i;
logic s_valid_i;
logic s_ready_o;
logic [31:0] m_data_o [2];
logic [1:0] m_keep_o;
logic m_last_o;
logic m_valid_o;
logic m_ready_i;



stream_upsize #(.T_DATA_WIDTH(32), .T_DATA_RATIO(2)) DUT
(
    .clk(clk),
    .rst_n(rst_n),
    .s_data_i(s_data_i),
    .s_last_i(s_last_i),
    .s_valid_i(s_valid_i),
    .s_ready_o(s_ready_o),
    .m_data_o(m_data_o),
    .m_keep_o(m_keep_o),
    .m_last_o(m_last_o),
    .m_valid_o(m_valid_o),
    .m_ready_i(m_ready_i)
);

localparam CLK_PERIOD = 10;

initial begin
    rst_n = 1;
    #1;
    rst_n = 0;
    #10;
    rst_n = 1;
end

initial begin
    wait(rst_n);
    clk = 0;
    forever begin
    #(CLK_PERIOD/2) clk = ~ clk;
    end
end

initial begin
    #5;
    wait(rst_n);
    repeat(20)
    begin
        @(posedge clk);
        s_data_i <= $urandom_range(0, 100);
        s_valid_i <= $urandom();
        s_last_i <= $urandom();
        m_ready_i <= 1;
        #1;
        while(~s_ready_o) begin
        @(posedge clk);
        #1;
        end
    end
    $stop();
    // #5;
    // wait(rst_n);
    // @(posedge clk);
    // s_data_i <= 0;
    // s_valid_i <= 1;
    // s_last_i <= 0;
    // m_ready_i <= 1;
    // #1;
    // while(~s_ready_o) begin
    // @(posedge clk);
    // #1;
    // end
    // @(posedge clk);
    // s_data_i <= 1;
    // s_valid_i <= 1;
    // s_last_i <= 0;
    // m_ready_i <= 1;
    // #1;
    // while(~s_ready_o) begin
    // @(posedge clk);
    // #1;
    // end
    // @(posedge clk);
    // s_data_i <= 2;
    // s_valid_i <= 1;
    // s_last_i <= 1;
    // m_ready_i <= 1;
    // #1;
    // while(~s_ready_o) begin
    // @(posedge clk);
    // #1;
    // end
    // @(posedge clk);
    // s_data_i <= 10;
    // s_valid_i <= 1;
    // s_last_i <= 0;
    // m_ready_i <= 1;
    // #1;
    // while(~s_ready_o) begin
    // @(posedge clk);
    // #1;
    // end
    // @(posedge clk);
    // s_data_i <= 11;
    // s_valid_i <= 1;
    // s_last_i <= 1;
    // m_ready_i <= 1;
    // #1;
    // while(~s_ready_o) begin
    // @(posedge clk);
    // #1;
    // end
    // $stop();
end

// initial begin
//     repeat(100)begin
//     @(posedge clk);
//     end
//     $display("END");
//     $stop();
// end

endmodule 
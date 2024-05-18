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
int i = 0;
event ev;

logic [31:0] firstQ [$];
logic [31:0] secondQ [$];
logic lastFQ [$];
logic lastSQ [$];

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
    forever begin
    wait(s_valid_i & s_ready_o === 1);
    @(posedge clk);
    firstQ.push_front(s_data_i);
    lastFQ.push_front(s_last_i);
    if(~s_last_i) begin
    wait(s_valid_i & s_ready_o === 1);
    @(posedge clk);
    secondQ.push_front(s_data_i);
    lastSQ.push_front(s_last_i);
    end
    end
end
initial begin
    #5;
    wait(rst_n);
    repeat(20)
    begin
        @(posedge clk);
        s_data_i <= i;
        s_valid_i <= (i % 2 == 0);
        s_last_i <= (i % 3 == 0);
        m_ready_i <= 1;
        #1;
        while(~s_ready_o) begin
        @(posedge clk);
        #1;
        end
        i++;
    end
    $display("SUCCESS");
    $stop();
end

initial begin
    #5;
    wait(rst_n);
    forever begin
        wait(m_valid_o & m_ready_i);
        if(m_keep_o[0])
        begin
            if(firstQ.pop_back() !== m_data_o[0]) begin
                $display("VALUE ERROR");
                $stop();
            end
        end
        if(m_keep_o[1])
        begin
            if(secondQ.pop_back() !== m_data_o[1]) begin
                $display("ERROR");
                $stop();
            end
        end
    end
end

endmodule 
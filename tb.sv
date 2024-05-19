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
logic [31:0] temp1, temp2;

logic [31:0] firstQ [$];
logic [31:0] secondQ [$];
logic lastFQ [$];
logic lastSQ [$];
logic last1, last2;
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
    wait(s_valid_i & s_ready_o);
    @(posedge clk);
    firstQ.push_front(s_data_i);
    lastFQ.push_front(s_last_i);
    if(~s_last_i) begin
    @(posedge clk);
    wait(s_valid_i & s_ready_o);
    @(posedge clk);
    secondQ.push_front(s_data_i);
    lastSQ.push_front(s_last_i);
    @(posedge clk);
    end
    else begin
        @(posedge clk);
    end
    end
end
initial begin
    #5;
    wait(rst_n);
    repeat(100)
    begin
        @(posedge clk);
        s_data_i <= i;
        s_valid_i <= (i % 2 == 0);
        s_last_i <= (i % 8 == 0);
        m_ready_i <= 1;
        #1;
        while(~s_ready_o) begin
        @(posedge clk);
        #1;
        end
        i++;
    end
    $display("PASSED");
    $stop();
end

initial begin
    #5;
    wait(rst_n);
    forever begin
        wait(m_valid_o & m_ready_i);
        if(m_keep_o[0])
        begin
            temp1 = firstQ.pop_back();
            last1 = lastFQ.pop_back();
            if(temp1 !== m_data_o[0]) begin
                $display("VALUE ERROR %0d != %0d", temp1, m_data_o[0]);
                $stop();
            end
        end
        if(m_keep_o[1])
        begin
            temp2 = secondQ.pop_back() ;
            last2 = lastSQ.pop_back();
            if(temp2 !== m_data_o[1]) begin
                $display("VALUE ERROR %0d != %0d", temp2, m_data_o[1]);
                $stop();
            end
        end
        else begin
            temp2 = 'x;
            last2 = 1'b0;
        end
        if((last1 | last2) !== m_last_o) begin
            $display("LAST ERROR %0d != %0d", last1 | last2, m_last_o);
            $stop();
        end
        $display("SUCCESS! REAL: {%0d, %0d} EXPECTED: {%0d, %0d}; LAST REAL: %0d EXPECTED: %0d", m_data_o[0], m_data_o[1], temp1, temp2, m_last_o, last1|last2);
        @(posedge clk);
        @(posedge clk);
    end
end

endmodule 
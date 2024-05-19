module stream_upsize #(
    parameter T_DATA_WIDTH = 1,
              T_DATA_RATIO = 2
)
(
    input logic clk,
    input logic rst_n, 
    input logic [T_DATA_WIDTH-1:0] s_data_i,
    input logic s_last_i,
    input logic s_valid_i,
    output logic s_ready_o,
    output logic [T_DATA_WIDTH-1:0] m_data_o [0:T_DATA_RATIO-1],
    output logic [T_DATA_RATIO-1:0] m_keep_o,
    output logic m_last_o,
    output logic m_valid_o,
    input logic m_ready_i
);
    typedef enum logic[1:0] {
        NEW_CYCLE = 2'b00,
        LOAD_TILL_LAST = 2'b01,
        KEEP_STATE = 2'b10
    } State;
    State state, next_state;
    localparam STATES_NUMBER = $clog2(T_DATA_RATIO);
    logic [T_DATA_RATIO-1:0] push;
    logic [T_DATA_RATIO-1:0] pop;
    logic [T_DATA_RATIO-1:0] full;
    logic [T_DATA_RATIO-1:0] empty;
    logic [T_DATA_WIDTH-1:0] data_to_FIFOS [T_DATA_RATIO];
    logic [T_DATA_WIDTH-1:0] data_from_FIFOS [T_DATA_RATIO];
    logic [STATES_NUMBER-1:0] num;
    int k;
    logic push_last, pop_last, full_last, empty_last;
    logic push_keep, pop_keep, full_keep, empty_keep;
    logic [T_DATA_RATIO:0] m_keep_FIFO;
    logic keep_go;
    logic [T_DATA_RATIO-1:0] temp;
    logic [T_DATA_RATIO:0] keep_to_FIFO;
	logic any_up;
	logic last_from_FIFO;
    assign keep_to_FIFO = m_keep_FIFO - 1'b1;
    genvar i;
    
    assign s_ready_o = ~|full & (state != KEEP_STATE);
    generate 
        for(i = 0 ; i < T_DATA_RATIO; i ++) begin : gen_fifos
        fifo #(.T_DATA_WIDTH(T_DATA_WIDTH), .DATA_DEPTH(16)) fifo_i 
        (
            .clk(clk),
            .rst_n(rst_n),
            .s_data_i(data_to_FIFOS[i]),
            .push(push[i]),
            .pop(pop[i]),
            .full(full[i]),
            .empty(empty[i]),
            .read_data(data_from_FIFOS[i])
        );

        assign m_data_o[i] = data_from_FIFOS[i];
        end
    endgenerate
    last_fifo #(.DATA_DEPTH(16)) last_fifo 
    (
        .clk(clk),
        .rst_n(rst_n),
        .s_data_i(s_last_i),
        .push(push_last),
        .pop(pop_last),
        .full(full_last),
        .empty(empty_last),
        .read_data(last_from_FIFO),
        .any_up(any_up)
    );

    keep_fifo #(.DATA_DEPTH(16), .T_DATA_RATIO(T_DATA_RATIO)) keep_fifo
    (
        .clk(clk),
        .rst_n(rst_n),
        .s_data_i(keep_to_FIFO[T_DATA_RATIO-1:0]),
        .push(push_keep),
        .pop(pop_keep),
        .full(full_keep),
        .empty(empty_keep),
        .read_data(m_keep_o)
    );
    assign m_valid_o = ~|empty & any_up & (state != KEEP_STATE);
    assign pop = {T_DATA_RATIO{any_up & (state != KEEP_STATE) & m_ready_i}};
    assign pop_last = any_up & (state != KEEP_STATE) & m_ready_i;
    assign m_last_o = last_from_FIFO;

    assign pop_keep = any_up & (state != KEEP_STATE) & m_ready_i;
    

    always_ff @(posedge clk or negedge rst_n)
    if(~rst_n)
        state <= NEW_CYCLE;
    else
        state <= next_state;

    always_ff @(posedge clk or negedge rst_n) 
    if(~rst_n)
        num <= 1;
	else if ((state == NEW_CYCLE) | (num == T_DATA_RATIO-1))
		  num <= 1;
    else if (state == LOAD_TILL_LAST) begin
        num <= num + 1'b1;
    end

    always_ff@(posedge clk or negedge rst_n)
    if(~rst_n)
        m_keep_FIFO <= 1'b1;
	else if (state == KEEP_STATE)
		  m_keep_FIFO <= 1'b1;
    else if(keep_go)
        m_keep_FIFO <= m_keep_FIFO << 1;

    always_comb begin
        next_state = state;
        push = '0;
        push_last = 1'b0;
        push_keep = 1'b0;
        keep_go = 1'b0;
        temp = '0;
        for(k = 0; k < T_DATA_RATIO; k ++)
        data_to_FIFOS[k] = '0;
        case(state)
        NEW_CYCLE: begin
            if(s_valid_i & s_ready_o & ~s_last_i)
                begin
                    next_state = LOAD_TILL_LAST;
                    push[0] = 1'b1;
                    data_to_FIFOS[0] = s_data_i;
                    keep_go = 1'b1;
                end
            else if (s_valid_i & s_ready_o & s_last_i) 
                begin
                    push = '1;
                    data_to_FIFOS[0] = s_data_i;
                    push_last = 1'b1;
                    keep_go = 1'b1;
                    next_state = KEEP_STATE;
                end
        end
        LOAD_TILL_LAST: begin
                if(s_valid_i & s_ready_o & ~s_last_i)
                    begin
                        push[num] = 1'b1;
                        data_to_FIFOS[num] = s_data_i;
                        keep_go = 1'b1;
                        if(num == T_DATA_RATIO-1) begin
                            next_state = KEEP_STATE;
                            push_last = 1'b1;
                        end
                    end
                if(s_valid_i & s_ready_o & s_last_i)
                    begin
                        temp[num] = 1'b1;
                        push = (~temp ^ (temp-1'b1)) + temp; 
                        data_to_FIFOS[num] = s_data_i;
                        next_state = KEEP_STATE;
                        push_last = 1'b1;
                        keep_go = 1'b1;
                    end
            end
        KEEP_STATE: begin
            next_state = NEW_CYCLE;
            push_keep = 1'b1;
        end
        endcase
    end

endmodule
module LoopDetector #(
    parameter WIDTH = 32
    )(
    input logic clk,
    input logic rst,

    input logic [WIDTH-1:0]PC_F,
    input logic [WIDTH-1:0]PC_EX,
    input logic [WIDTH-1:0]PC_destination,

    input logic branch_en_F,
    input logic branch_en_EX,

    input logic feedback_from_ALU,

    output logic loop_decision,
    output logic LD_en
    );

    logic [7:0]counter_table[255:0];//MSB = Loop_en - Others = Counter
    logic [8:0]memory_table[255:0];//MSB = Loop_en - Others = Counter
    logic [7:0]temp_counter;

    logic [WIDTH-1:0]comparator_out;
    logic loop_en;

    Kogge_Stone Comparator(
        .in0(PC_destination),
        .in1(PC_F),
        .sub_en(1'b1),
        .out(comparator_out)
    );

    assign loop_en = comparator_out[WIDTH-1];

    int i;

    always_ff @(posedge clk, negedge rst)
    begin
        if(!rst)
        begin
            for(i = 0; i < 256 ; i = i+1)
            begin
                counter_table[i] <= 8'd0;
                memory_table[i] <= {1'd0 , 8'd0};
            end
        end

        else
        begin
            if(loop_en && branch_en_F)
            begin
                counter_table[PC_F[7:0]] <= counter_table[PC_F[7:0]] + 8'd1;
                temp_counter <= counter_table[PC_F[7:0]] + 8'd1;
                /*
                counter_table[PC_F[7:0]] <= temp_counter;
                */
            end

            else
            begin
                temp_counter <= counter_table[PC_F[7:0]][7:0];
            end

            if(branch_en_EX)
            begin
                if(feedback_from_ALU)
                begin
                    memory_table[PC_EX[7:0]][7:0] <= counter_table[PC_EX][7:0];
                    memory_table[PC_EX[7:0]][8] <= 1'b1;
                end

                else 
                begin
                    memory_table[PC_EX[7:0]][8] <= 1'd0;
                    counter_table[PC_EX[7:0]][7:0] <= 8'd0;
                end
            end

            else 
            begin

            end
        end
    end

    assign LD_en = memory_table[PC_F[7:0]][8];

    assign loop_decision = (LD_en) ? (memory_table[PC_F[7:0]][7:0] - counter_table[PC_F[7:0]] >= 0) ? 1'b1 : 1'b0 : 1'b0;


    

endmodule
`include "RISC_top.v"

module MIPS32_PIP_tb();

    reg clk1,clk2;
    integer k;  

    MIPS32_PIP DUT(clk1,clk2);

    initial begin
        repeat(20) begin
            clk1 = 0; clk2 = 0;
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end

    initial begin
        for (k=0; k<20; k++) begin
            DUT.Reg[k] = k;
        end

        DUT.Mem[0] = 32'h2801000a; //ADDI R1 R0 10
        DUT.Mem[1] = 32'h28020014; //ADDI R2 R0 20
        DUT.Mem[2] = 32'h28030019; //ADDI R3 R0 25
        DUT.Mem[3] = 32'h0ce77800; //OR R7 R7 R7
        DUT.Mem[4] = 32'h0ce77800; //OR R7 R7 R7
        DUT.Mem[5] = 32'h00222000; //ADD R4 R1 R2
        DUT.Mem[6] = 32'h0ce77800; //OR R7 R7 R7
        DUT.Mem[7] = 32'h00832800; //ADD R5 R4 R3
        DUT.Mem[8] = 32'hfc000000; //HLT

        DUT.HLTDT = 0;
        DUT.PC = 0;
        DUT.BRDT = 0;

        #280
        for (k=0; k<6; k++) begin
            $display("R%1d - %2d", k, DUT.Reg[k]);
        end
    end

    initial begin
        $dumpfile("pip.vcd");
        $dumpvars(0,MIPS32_PIP_tb);
        #300 $finish;
    end


endmodule
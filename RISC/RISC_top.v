module MIPS32_PIP( 
    clk1, clk2
);

    input clk1,clk2;
    reg [31:0] PC, IF_ID_NPC, IF_ID_IR;
    reg [31:0] ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_IMM, ID_EX_IR;
    reg [2:0] ID_EX_TYPE, EX_MEM_TYPE, MEM_WB_TYPE;
    reg [31:0] EX_MEM_COND, EX_MEM_ALUout, EX_MEM_B, EX_MEM_IR ;
    reg [31:0] MEM_WB_LMD, MEM_WB_ALUout, MEM_WB_IR;

    reg [31:0] Reg [0:31];
    reg [31:0] Mem [0:1023];

    reg HLTDT;
    reg BRDT;

    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011, SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000, SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100, BNEQZ=6'b001101, BEQZ=6'b001110;
    parameter RR_ALU=3'h0, RM_ALU=3'h1, LOAD=3'h2, STORE=3'h3, BRANCH=3'h4, HALT=3'h5;

    //IF STAGE
    always @(posedge clk1) begin
        if(!HLTDT) begin
            if((EX_MEM_IR[31:26]==BEQZ && EX_MEM_COND==1)||(EX_MEM_IR[31:26]==BNEQZ && EX_MEM_COND==0)) begin
                BRDT <= #1 1;
                IF_ID_IR <= #1 Mem[EX_MEM_ALUout];
                IF_ID_NPC <= #1 EX_MEM_ALUout;
                PC <= #1 EX_MEM_ALUout;
            end
            else begin
                IF_ID_IR <= #1 Mem[PC];
                IF_ID_NPC <= #1 PC+1;
                PC <= #1 PC+1; 
            end
        end
    end

    //ID STAGE
    always @(posedge clk2) begin
        if(!HLTDT) begin
            ID_EX_NPC <= #1 IF_ID_NPC;
            ID_EX_IR <= #1 IF_ID_IR;
            ID_EX_IMM <= #1 {{16{IF_ID_IR[15]}},{IF_ID_IR[15:0]}};

            ID_EX_A <= #1 Reg[IF_ID_IR[25:21]];
            ID_EX_B <= #1 Reg[IF_ID_IR[20:16]];

            #1 case (IF_ID_IR[31:26])
                ADD,SUB,AND,OR,SLT,MUL : ID_EX_TYPE <= RR_ALU;
                ADDI,SUBI,SLTI : ID_EX_TYPE <= RM_ALU;
                HLT : ID_EX_TYPE <= HALT;
                LW : ID_EX_TYPE <= LOAD;
                SW : ID_EX_TYPE <= STORE;
                BEQZ,BNEQZ : ID_EX_TYPE <= BRANCH;
                default: ID_EX_TYPE <= HALT;
            endcase 

        end
    end 

    //EX STAGE
    always @(posedge clk1) begin
        if(!HLTDT) begin
            EX_MEM_B <= #1 ID_EX_B;
            EX_MEM_TYPE <= #1 ID_EX_TYPE;
            EX_MEM_IR <= #1 ID_EX_IR;
            BRDT <= #1 0;

            EX_MEM_COND <= #1 !ID_EX_A;

            #1 case (ID_EX_TYPE)
                RR_ALU : begin
                            case(ID_EX_IR[31:26])
                                ADD : EX_MEM_ALUout <= ID_EX_A + ID_EX_B;
                                SUB : EX_MEM_ALUout <= ID_EX_A - ID_EX_B;
                                AND : EX_MEM_ALUout <= ID_EX_A & ID_EX_B;
                                OR : EX_MEM_ALUout <= ID_EX_A | ID_EX_B;
                                SLT : EX_MEM_ALUout <= ID_EX_A < ID_EX_B;
                                MUL : EX_MEM_ALUout <= ID_EX_A * ID_EX_B;
                                default : EX_MEM_ALUout <= 32'hxxxxxxxx;
                            endcase
                        end
                RM_ALU : begin
                            case(ID_EX_IR[31:26])
                                ADDI : EX_MEM_ALUout <= ID_EX_A + ID_EX_IMM;
                                SUBI : EX_MEM_ALUout <= ID_EX_A - ID_EX_IMM;
                                SLTI : EX_MEM_ALUout <= ID_EX_A < ID_EX_IMM;
                                default : EX_MEM_ALUout <= 32'hxxxxxxxx;
                            endcase
                        end
                LOAD, STORE : EX_MEM_ALUout <= ID_EX_A + ID_EX_IMM;
                BRANCH : EX_MEM_ALUout <= ID_EX_NPC + ID_EX_IMM;
            endcase 

        end
    end


    //MEM STAGE
    always @(posedge clk2) begin
        if(!HLTDT) begin
            MEM_WB_TYPE <= #1 EX_MEM_TYPE;
            MEM_WB_IR <= #1 EX_MEM_IR;

            #1 case(EX_MEM_TYPE)
                RR_ALU,RM_ALU : MEM_WB_ALUout <= EX_MEM_ALUout;
                LOAD : MEM_WB_LMD <= Mem[EX_MEM_ALUout]; 
                STORE : if(!BRDT) Mem[EX_MEM_ALUout] <= EX_MEM_B;
            endcase
        end
    end 

    //WB STAGE
    always @(posedge clk1) begin
        if(!BRDT) begin
            #1 case(MEM_WB_TYPE)
                RR_ALU : Reg[MEM_WB_IR[15:11]] <= MEM_WB_ALUout;
                RM_ALU : Reg[MEM_WB_IR[20:16]] <= MEM_WB_ALUout;
                LOAD : Reg[MEM_WB_IR[20:16]] <= MEM_WB_LMD;
                HALT : HLTDT <= 1;
            endcase
        end
    end 

endmodule
module Inst_reco
(
    input[31:0]                     inst,

    output[14:0]                    arithmetic,
    output[7:0]                     logic,
    output[5:0]                     shift,
    output[11:0]                    branch,
    output[3:0]                     move,
    output[2:0]                     trap,
    output[11:0]                    memory,
    output[1:0]                     special
);

    wire[5:0]   opcode  =   inst[31:26];
    wire[4:0]   rs      =   inst[25:21];
    wire[4:0]   rt      =   inst[20:16];
    wire[4:0]   rd      =   inst[15:11];
    wire[5:0]   funct   =   inst[5:0];

    wire        addi    =	(opcode==6'b001000),                                //Arithmetic operation instruction       
                addiu   =	(opcode==6'b001001),
                add     =	(opcode==6'b000000 & funct==6'b100000),
                addu    =	(opcode==6'b000000 & funct==6'b100001),
                sub     =	(opcode==6'b000000 & funct==6'b100010),
                subu    =	(opcode==6'b000000 & funct==6'b100011),
                slt     =	(opcode==6'b000000 & funct==6'b101010),
                slti    =	(opcode==6'b001010),
                sltu    =	(opcode==6'b000000 & funct==6'b101011),
                sltiu   =	(opcode==6'b001011),
                mul     =   (opcode==6'b011100 & funct==6'b000010),
                mult    =	(opcode==6'b000000 & funct==6'b011000),
                multu   =	(opcode==6'b000000 & funct==6'b011001),
                div     =	(opcode==6'b000000 & funct==6'b011010),
                divu    =	(opcode==6'b000000 & funct==6'b011011),
                lui     =   (opcode==6'b001111),                                //Logical operation instruction
                ori     =	(opcode==6'b001101),
                And     =	(opcode==6'b000000 & funct==6'b100100),
                Or      =	(opcode==6'b000000 & funct==6'b100101),
                Xor     =	(opcode==6'b000000 & funct==6'b100110),
                Nor     =	(opcode==6'b000000 & funct==6'b100111),
                andi    =	(opcode==6'b001100),
                xori    =	(opcode==6'b001110),
                sll     =	(opcode==6'b000000 & funct==6'b0& (|inst[20:11])),  //Shift operation instruction
                srl     =	(opcode==6'b000000 & funct==6'h2),
                sra     =	(opcode==6'b000000 & funct==6'h3),
                sllv    =	(opcode==6'b000000 & funct==6'h4),
                srlv    =	(opcode==6'b000000 & funct==6'h6),
                srav    =	(opcode==6'b000000 & funct==6'h7),
                mfhi    =	(opcode==6'b000000 & funct==6'h10),                 //Data movement instruction
                mthi    =	(opcode==6'b000000 & funct==6'h11),
                mflo    =	(opcode==6'b000000 & funct==6'h12),
                mtlo    =	(opcode==6'b000000 & funct==6'h13),
                beq     =	(opcode==6'b000100),                                //Branch jump instruction
                bne     =	(opcode==6'b000101),
                blez    =	(opcode==6'b000110),
                bgtz    =	(opcode==6'b000111),
                bltz    =	(opcode==6'b000001 & rt==6'b000000),
                bgez    =	(opcode==6'b000001 & rt==6'h1),     
                bgezal  =   (opcode==6'b000001 & rt==6'h11),
                bltzal  =   (opcode==6'b000001 & rt==6'h10),
                j       =	(opcode==6'b000010),
                jal     =	(opcode==6'b000011),
                jr      =	(opcode==6'b000000 & funct==6'h8),
                jalr    =	(opcode==6'b000000 & funct==6'h9),                                       
                lb      =	(opcode==6'b100000),                                //Memory access insruction
                lbu     =	(opcode==6'b100100),
                lh      =	(opcode==6'b100001),
                lhu     =	(opcode==6'b100101),
                lw      =	(opcode==6'b100011),
                lwl     =   (opcode==6'b100010),
                lwr     =   (opcode==6'b100110),
                sb      =	(opcode==6'h28),
                sh      =	(opcode==6'h29),
                sw      =	(opcode==6'b101011),
                swl     =   (opcode==6'b101010),
                swr     =   (opcode==6'h2e),    
                eret    =	(inst==32'h42000018),          
                break   =   (opcode==6'b000000 & funct==6'b001101), 
                syscall =   (opcode==6'b000000 & funct==6'b001100),
                mfc0    =	(opcode==6'b010000 & rs==5'b00000),
                mtc0    =	(opcode==6'b010000 & rs==5'b00100);

    assign arithmetic = {add,addu,sub,subu,slt,sltu,mul,slti,addi,addiu,sltiu,mult,multu,div,divu};    // 15
    assign logic      = {And,Nor,Or,Xor,lui,ori,andi,xori};                                            //8                                     
    assign shift      = {sll,sra,srl,sllv,srav,srlv};                                                  //6                                      
    assign branch     = {beq,bne,bgez,bgtz,blez,bltz,bltzal,bgezal,jal,jalr,j,jr};                     //12                                      
    assign move       = {mfhi,mflo,mthi,mtlo};                                                         //4                                      
    assign trap       = {break,syscall,eret};                                                          //3                                      
    assign memory     = {lb,lbu,lh,lhu,lw,lwl,lwr,sb,sh,sw,swl,swr};                                   //12
    assign special    = {mfc0,mtc0};                                                                   //2                                     
                                                                              

endmodule
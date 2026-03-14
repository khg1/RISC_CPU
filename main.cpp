#include<iostream>
#include<string>
#include<vector>
#include<bitset>
#include<fstream>


using namespace std;

#define MemSize 1000 // memory size, in reality, the memory size should be 2^32, but for this lab, for the space resaon, we keep it as this large number, but the memory is still 32-bit addressable.

struct IFStruct {
    bitset<32>  PC;
    bool        nop;
};

struct IDStruct {
    bitset<32> Instr;
    bitset<32> PC;
    bool       nop;
};

struct EXStruct {
    bitset<32>  Read_data1;
    bitset<32>  Read_data2;
    bitset<32>  Imm;
    bitset<5>   Rs;
    bitset<5>   Rt;
    bitset<5>   Wrt_reg_addr;
    bitset<32>  PC;
    bitset<4>   funct;
    
    bitset<2>   is_I_type;
    bool        rd_mem;
    bool        wrt_mem;
    bitset<2>   alu_op;
    bool        wrt_enable;
    bool        branch;
    bool        mem_to_reg;
    bool        nop;
};

struct MEMStruct {
    bitset<32>  ALUresult;
    bitset<32>  Store_data;
    bitset<5>   Rs;
    bitset<5>   Rt;
    bitset<5>   Wrt_reg_addr;
    bool        alu_zero;
    
    bool        rd_mem;
    bool        wrt_mem;
    bool        wrt_enable;
    bool        branch;
    bool        mem_to_reg;
    
    bool        nop;
};

struct WBStruct {
    bitset<32>  Wrt_data;
    bitset<32>  ALU_data;
    bitset<5>   Rs;
    bitset<5>   Rt;
    bitset<5>   Wrt_reg_addr;
    bool   wrt_enable;
    bool   mem_to_reg;
    
    bool        nop;
};

struct stateStruct {
    IFStruct    IF;
    IDStruct    ID;
    EXStruct    EX;
    MEMStruct   MEM;
    WBStruct    WB;
};

class InsMem
{
    public:
        string id, ioDir;
        InsMem(string name, string ioDir) {
            id = name;
            IMem.resize(MemSize);
            ifstream imem;
            string line;
            int i=0;
            imem.open(ioDir + "/imem.txt");
            if (imem.is_open())
            {
                while (getline(imem,line))
                {
                    if(line.size() != 8){
                        line.pop_back();
                    }
                    IMem[i] = bitset<8>(line);
                    i++;
                }
            }
            else cout<<"Unable to open IMEM input file.";
            imem.close();
        }

        bitset<32> readInstr(bitset<32> ReadAddress) {
            // read instruction memory
            bitset<32> return_value;
            unsigned long imem_index = 0;
            imem_index = ReadAddress.to_ulong();
            if(imem_index % 4 == 0){
                for(int i = 0; i<=3; i++){
                    bitset<32> temp(IMem[imem_index+i].to_ulong());
                    return_value = return_value | temp;
                    if(i!=3){
                        return_value = return_value << 8;
                    }
                }
            }
            return return_value;
        }
      
    private:
        vector<bitset<8> > IMem;
};
      
class DataMem
{
    public:
        string id, opFilePath, ioDir;
    DataMem(string name, string ioDir) : id{name}, ioDir{ioDir} {
            DMem.resize(MemSize);
            opFilePath = ioDir + "/" + name + "_DMEMResult.txt";
            ifstream dmem;
            string line;
            int i=0;
            dmem.open(ioDir + "/dmem.txt");
            if (dmem.is_open())
            {
                while (getline(dmem,line))
                {
                    if(line.size() != 8){
                        line.pop_back();
                    }
                    DMem[i] = bitset<8>(line);
                    i++;
                }
            }
            else cout<<"Unable to open DMEM input file.";
                dmem.close();
        }
        
        bitset<32> readDataMem(bitset<32> Address) {
            // read data memory
            bitset<32> return_value;
            unsigned long dmem_index = 0;
            dmem_index = Address.to_ulong();
            if(dmem_index % 4 == 0){
                for(int i = 0; i<=3; i++){
                    bitset<32> temp(DMem[dmem_index+i].to_ulong());
                    return_value = return_value | temp;
                    if(i!=3){
                        return_value = return_value << 8;
                    }
                }
            }
            return return_value;
        }
            
        void writeDataMem(bitset<32> Address, bitset<32> WriteData) {
            // write into memory
            bitset<32> bit_mask(0xFF000000);
            bitset<8> temp(0x0000);
            for(int i = 0; i<=3; i++){
                temp = (bitset<8>)((bit_mask & WriteData) >> ((3-i)*8)).to_ulong();
                DMem[Address.to_ulong()+i] = temp;
                bit_mask = bit_mask >> 8;
            }
        }
                     
        void outputDataMem() {
            ofstream dmemout;
            dmemout.open(opFilePath, std::ios_base::trunc);
            if (dmemout.is_open()) {
                for (int j = 0; j< 1000; j++)
                {
                    dmemout << DMem[j]<<endl;
                }
            }
            else cout<<"Unable to open "<<id<<" DMEM result file." << endl;
            dmemout.close();
        }

    private:
        vector<bitset<8> > DMem;
};

class RegisterFile
{
    public:
        string outputFile;
    RegisterFile(string ioDir): outputFile {ioDir + "RFResult.txt"} {
            Registers.resize(32);
            Registers[0] = bitset<32> (0);
        }
    
        bitset<32> readRF(bitset<5> Reg_addr) {
            // Fill in
            if((Reg_addr.to_ulong() >=0) & (Reg_addr.to_ulong() < 32)){
                return Registers[Reg_addr.to_ulong()];
            }
            return 0;
        }
    
        void writeRF(bitset<5> Reg_addr, bitset<32> Wrt_reg_data) {
            // Fill in
            if((Reg_addr.to_ulong() > 0) & (Reg_addr.to_ulong() < 32)){
                Registers[Reg_addr.to_ulong()] = Wrt_reg_data;
            }
        }
         
        void outputRF(int cycle) {
            ofstream rfout;
            if (cycle == 0)
                rfout.open(outputFile, std::ios_base::trunc);
            else
                rfout.open(outputFile, std::ios_base::app);
            if (rfout.is_open())
            {
                rfout<< "----------------------------------------------------------------------" << endl;
                rfout<<"State of RF after executing cycle:"<<cycle<<endl;
                for (int j = 0; j<32; j++)
                {
                    rfout << Registers[j]<<endl;
                }
            }
            else cout<<"Unable to open RF output file."<<endl;
            rfout.close();
        }
            
    private:
        vector<bitset<32> > Registers;
};

enum Format{
    LW = 3,
    I = 19,
    R = 51,
    S = 35,
    B = 99,
    J = 111,
    HALT = 127
};

class Core {
    public:
        RegisterFile myRF;
        int cycle = 0;
        int instruction = 0;
        bool halted = false;
        string ioDir;
        struct stateStruct state, nextState;
        InsMem ext_imem;
        DataMem *ext_dmem;
    
        bitset<3> funct3 = 0;
        bitset<7> funct7 = 0;
        bitset<7> opcode = 0;
        bitset<4> funct = 0;

        bool branch = false;
        bool memRead = false;
        bool memtoReg = false;
        bool alu_zero = false;
        bitset<2> aluop = 0;
        bool memWrite = false;
        bitset<2> aluSrc = 0;
        bool regWrite = false;
        
    Core(string ioDir, InsMem &imem, DataMem &dmem): myRF{ioDir}, ioDir{ioDir}, ext_imem {imem}, ext_dmem {&dmem} {}

        virtual void step() {}

        virtual void printState() {}
    
        bitset<32> imm_gen(bitset<32> instr){                              //function to extract immediate from various instructions types and to sign extend it to 32 bits
            bitset<7> opcode = bitset<7>((instr & (bitset<32>)0x0000007F).to_ulong());
            bitset<32> imm_val(0x00000000);
            int sign_bit = 0;
            if(opcode.to_ulong() == 3 | opcode.to_ulong() == 19){
                imm_val = (bitset<32>)((instr & (bitset<32>)0xFFF00000) >> 20).to_ulong();
                sign_bit = 12;
            } else if (opcode.to_ulong()==35){
                imm_val = (bitset<32>)(((instr & (bitset<32>)0xFE000000) >> 20).to_ulong()
                                            + ((instr & (bitset<32>)0x00000F80) >> 7).to_ulong());
                sign_bit = 12;
            } else if (opcode.to_ulong()==99){
                imm_val = (bitset<32>)(((instr & (bitset<32>)0x80000000) >> 20).to_ulong()
                                            +((instr & (bitset<32>)0x00000080) << 3).to_ulong()
                                            +((instr & (bitset<32>)0x7E000000) >> 21).to_ulong()
                                            +((instr & (bitset<32>)0x00000E00) >> 8).to_ulong());
                sign_bit = 12;
            } else if (opcode.to_ulong()==111){
                imm_val = (bitset<32>)(((instr & (bitset<32>)0x80000000) >> 12).to_ulong()
                                            +((instr & (bitset<32>)0x7FE00000) >> 21).to_ulong()
                                            +((instr & (bitset<32>)0x00100000) >> 10).to_ulong()
                                            +((instr & (bitset<32>)0x000FF000) >> 1).to_ulong());
                sign_bit = 20;
            } else{
                return 0;
            }
            
            if(imm_val.test(sign_bit-1)){
                bitset<32> mask(0xFFFFFFFF);
                imm_val |= (mask << sign_bit);
            }
            return imm_val;
        }
    
        bitset<32> shift_left_one(bitset<32> imm_data){                     //shifting immediate field for the branching instructions
            return (imm_data << 1);
        }
    
        bitset<32> ALU_Block(bitset<32> op1, bitset<32> op2, bitset<4> control){            //ALU block for performing arithmetic operation
            bitset<32> res;
            if(control.to_ulong() == 2){
                res = (bitset<32>)(op1.to_ulong() + op2.to_ulong());
            } else if (control.to_ulong() == 6){
                res = (bitset<32>)(op1.to_ulong() - op2.to_ulong());
            } else if (control.to_ulong() == 0){
                res = op1 & op2;
            } else if (control.to_ulong() == 1){
                res = op1 | op2;
            } else if (control.to_ulong() == 4){
                res = op1 ^ op2;
            }
            if(res == 0){
                alu_zero = true;
            }else{
                alu_zero = false;
            }
            return res;
        }
        
        bitset<4> ALU_control(bitset<4> funct, bitset<2> aluop){            //function to determine operation type performed by ALU block
            bitset<4> ret_val(0x0000);
            switch (aluop.to_ulong()) {
                case 0:
                    ret_val = (bitset<4>)2;
                    break;
                case 1:
                    ret_val = (bitset<4>)6;
                    break;
                case 2:
                    if((funct & (bitset<4>)0x7).to_ulong() == 0){
                        if((funct & (bitset<4>)0x8).to_ulong() == 8){
                            ret_val = (bitset<4>)6;
                        } else{
                            ret_val = (bitset<4>)2;
                        }
                    } else if ((funct & (bitset<4>)0x7).to_ulong() == 7){
                        ret_val = (bitset<4>)0;
                    } else if ((funct & (bitset<4>)0x7).to_ulong() == 6){
                        ret_val = (bitset<4>)1;
                    } else if((funct & (bitset<4>)0x7).to_ulong() == 4){
                        ret_val = (bitset<4>)4;
                    }
                    break;
                case 3:
                    if((funct & (bitset<4>)0x7).to_ulong() == 0){
                        ret_val = (bitset<4>)2;
                    }else if ((funct & (bitset<4>)0x7).to_ulong() == 7){
                        ret_val = (bitset<4>)0;
                    } else if ((funct & (bitset<4>)0x7).to_ulong() == 6){
                        ret_val = (bitset<4>)1;
                    } else if((funct & (bitset<4>)0x7).to_ulong() == 4){
                        ret_val = (bitset<4>)4;
                    }
                    break;
                default:
                    break;
            }
            return ret_val;
        }
        
        void control_logic(bitset<7> opcode){               //function to generate control signals for sub modules
            switch (opcode.to_ulong()) {
                case LW:
                    aluop = 0;
                    aluSrc = 1;
                    branch = 0;
                    memRead = 1;
                    memWrite = 0;
                    regWrite = 1;
                    memtoReg = 1;
                    break;
                case I:
                    aluop = 3;
                    aluSrc = 1;
                    branch = 0;
                    memRead = 0;
                    memWrite = 0;
                    regWrite = 1;
                    memtoReg = 0;
                    break;
                case R:
                    aluop = 2;
                    aluSrc = 0;
                    branch = 0;
                    memRead = 0;
                    memWrite = 0;
                    regWrite = 1;
                    memtoReg = 0;
                    break;
                case S:
                    aluop = 0;
                    aluSrc = 1;
                    branch = 0;
                    memRead = 0;
                    memWrite = 1;
                    regWrite = 0;
                    memtoReg = 0;
                    break;
                case B:
                    aluop = 1;
                    aluSrc = 0;
                    branch = 1;
                    memRead = 0;
                    memWrite = 0;
                    regWrite = 0;
                    memtoReg = 0;
                    break;
                case J:
                    aluop = 0;
                    aluSrc = 2;
                    branch = 1;
                    memRead = 0;
                    memWrite = 0;
                    regWrite = 1;
                    memtoReg = 0;
                    break;
                default:
                    aluop = 0;
                    aluSrc = 0;
                    branch = 0;
                    memRead = 0;
                    memWrite = 0;
                    regWrite = 0;
                    memtoReg = 0;
                    break;
            }
        }
    
};

class SingleStageCore : public Core {
    public:
    SingleStageCore(string ioDir, InsMem &imem, DataMem &dmem): Core(ioDir + "/SS_", imem, dmem), opFilePath{ioDir + "/StateResult_SS.txt"}, metFilePath{ioDir + "/PerformanceMetrics_Result.txt"} {}

        void step() {
            /* Your implementation*/
            if(cycle == 0){
                state.IF.PC = 0x00000000;       //initializing program counter before the first instruction
                state.IF.nop = false;           //initializing no operation flag to be false
            }
            if(!state.IF.nop){                                              //checking for no operation flag
                instruction += 1;
                state.ID.Instr = ext_imem.readInstr(state.IF.PC);           //fetching the instruction to be decoded
                funct3 = (bitset<3>)((state.ID.Instr & (bitset<32>)0x00007000) >> 12).to_ulong();       //decoding funct3 field from the instruction
                funct7 = (bitset<7>)((state.ID.Instr & (bitset<32>)0xFE000000) >> 25).to_ulong();       //decoding funct7 field from the instruction
                opcode = (bitset<7>)(state.ID.Instr & (bitset<32>)0x0000007F).to_ulong();           //decoding opcode to determine instruction type
                if(opcode != HALT){                                                                         //checking if instruction needs execution
                    state.EX.Rs = (bitset<5>)((state.ID.Instr & (bitset<32>)0x000F8000) >> 15).to_ulong();      //first register operand
                    state.EX.Rt = (bitset<5>)((state.ID.Instr & (bitset<32>)0x01F00000) >> 20).to_ulong();      //second register operand
                    state.EX.Wrt_reg_addr = (bitset<5>)((state.ID.Instr & (bitset<32>)0x00000F80) >> 7).to_ulong();     //destination register
                    state.EX.Imm = imm_gen(state.ID.Instr);     //signed immediate field
                    control_logic(opcode);      //assigning control signals based on the instruction type
                    state.EX.Read_data1 = myRF.readRF(state.EX.Rs);         //reading operand 1 from the register file
                    state.EX.Read_data2 = myRF.readRF(state.EX.Rt);         //reading operand 2 from the register file
                    funct = (bitset<4>)(((state.ID.Instr & (bitset<32>)0x40000000) >> 27).to_ulong()
                                        + ((state.ID.Instr & (bitset<32>)0x00007000) >> 12).to_ulong());        //input to the ALU control block for determining ALU operation
                    
                    if(aluSrc.to_ulong() == 1){             //mux to select second input to the ALU block depending on the instruction type
                        state.MEM.ALUresult = ALU_Block(state.EX.Read_data1, state.EX.Imm, ALU_control(funct, aluop));      //I-type, LW-type, S-type
                    }else if(aluSrc.to_ulong() == 0){
                        state.MEM.ALUresult = ALU_Block(state.EX.Read_data1, state.EX.Read_data2, ALU_control(funct, aluop));   //R-type, B-type
                    }else{
                        state.MEM.ALUresult = ALU_Block(state.IF.PC, (bitset<32>)4, ALU_control(funct, aluop));     //J-type
                    }
                    
                    if(memWrite){           //writing ALU result to memory if memWrite flag is set
                        ext_dmem->writeDataMem(state.MEM.ALUresult, state.EX.Read_data2);
                    }
                    if(memRead){            //reading from data memory if memRead flag is set
                        state.WB.Wrt_data = ext_dmem->readDataMem(state.MEM.ALUresult);
                    }
                    if(regWrite){           //flag to enable register write
                        if(memtoReg){       //flag to select data source to be written back to the register file
                            myRF.writeRF(state.EX.Wrt_reg_addr, state.WB.Wrt_data);
                        }else{
                            myRF.writeRF(state.EX.Wrt_reg_addr, state.MEM.ALUresult);
                        }
                    }
                    
                    if(((funct3.to_ulong() == 0) & alu_zero & branch) | (((funct3.to_ulong() == 1) & !alu_zero & branch)) | (branch & regWrite)){    //combinational logic to update the program counter
                        nextState.IF.PC = (bitset<32>)(state.IF.PC.to_ulong() + static_cast<int32_t>(shift_left_one(state.EX.Imm).to_ulong()));
                    }else{
                        nextState.IF.PC = (bitset<32>)(state.IF.PC.to_ulong() + 4);
                    }
                    nextState.IF.nop = false;       //disable the no operation flag for the next instruction
                }else{
                    nextState.IF.nop = true;        //set the flag if the current instruction is HALT
                }
            }
            
            if (state.IF.nop){
                halted = true;          //halt the processor execution if the current no operation flag is set
            }
            
            myRF.outputRF(cycle); // dump RF
            printState(nextState, cycle); //print states after executing cycle 0, cycle 1, cycle 2 ...
            
            state = nextState; // The end of the cycle and updates the current state with the values calculated in this cycle
            cycle++;
        }

        void printState(stateStruct state, int cycle) {
            ofstream printstate;
            if (cycle == 0)
                printstate.open(opFilePath, std::ios_base::trunc);
            else
                printstate.open(opFilePath, std::ios_base::app);
            if (printstate.is_open()) {
                printstate<<"----------------------------------------------------------------------"<<endl;
                printstate<<"State after executing cycle: "<<cycle<<endl;
                
                printstate<<"IF.PC: "<<state.IF.PC.to_ulong()<<endl;
                printstate<<"IF.nop: "<<(state.IF.nop ? "True" : "False")<<endl;
            }
            else cout<<"Unable to open SS StateResult output file." << endl;
            printstate.close();
        }
    
    private:
        string opFilePath;
        string metFilePath;
    
};

class FiveStageCore : public Core{
    public:
        
        FiveStageCore(string ioDir, InsMem &imem, DataMem &dmem): Core(ioDir + "/FS_", imem, dmem), opFilePath(ioDir + "/StateResult_FS.txt") {}

        void step() {

            /* --------------------- WB stage --------------------- */
            if(cycle < 4){                                                  //if cycle is less than 4, no operation is performed by write-back stage
                state.WB.nop = true;
            }
            if(!state.WB.nop){
                if(state.WB.wrt_enable){                                    //check if updating the register file
                    if(state.WB.mem_to_reg){                                //if the source is memory or ALU result
                        myRF.writeRF(state.WB.Wrt_reg_addr, state.WB.Wrt_data);
                    }else{
                        myRF.writeRF(state.WB.Wrt_reg_addr, state.WB.ALU_data);
                    }
                }
            }
            
            /* --------------------- MEM stage -------------------- */
            if(cycle < 3){                                                  //if cycle is less than 3, no operation is performed by memory stage
                state.MEM.nop = true;
            }
            
            if(!state.MEM.nop){                         //check for reading or writing from memory
                if(state.MEM.wrt_mem){                  //for writing to memory check for wrt_mem flag
                    ext_dmem->writeDataMem(state.MEM.ALUresult, state.MEM.Store_data);
                } else if(state.MEM.rd_mem){           //for reading from memory check for rd_mem flag
                    MEMWB_mem_data = ext_dmem->readDataMem(state.MEM.ALUresult);
                }
                /*---Updating MEM/WB registers----*/
                MEMWB_ALUresult = state.MEM.ALUresult;
                MEMWB_reg_write = state.MEM.wrt_enable;
                MEMWB_memto_reg = state.MEM.mem_to_reg;
                MEMWB_write_reg_addr = state.MEM.Wrt_reg_addr;
                MEMWB_rs1 = state.MEM.Rs;
                MEMWB_rs2 = state.MEM.Rt;
            }
            
            /* --------------------- EX stage --------------------- */
            if(cycle < 2){                                                      //if cycle is less than 2, no operation is performed by execution stage
                state.EX.nop = true;
            }
            
            if(!state.EX.nop){
                forward_unit(state.EX.Rs, state.EX.Rt);                     //check and if necessary forward from memory or write back stage
                if(state.EX.is_I_type.to_ulong() == 1){                     //if to check for the format of instruction for passing which operands to ALU module
                    EXMEM_ALUresult = ALU_Block(state.EX.Read_data1, state.EX.Imm, ALU_control(state.EX.funct, state.EX.alu_op));
                }else if(state.EX.is_I_type.to_ulong() == 0){
                    EXMEM_ALUresult = ALU_Block(state.EX.Read_data1, state.EX.Read_data2, ALU_control(state.EX.funct, state.EX.alu_op));
                }else{
                    EXMEM_ALUresult = ALU_Block(state.EX.PC, (bitset<32>)4, ALU_control(state.EX.funct, state.EX.alu_op));      //for Jump instruction to store PC+4 in rd
                }
                /*---Updating EX/MEM registers----*/
                EXMEM_data2 = state.EX.Read_data2;
                EXMEM_write_reg_addr = state.EX.Wrt_reg_addr;
                EXMEM_mem_read = state.EX.rd_mem;
                EXMEM_mem_write = state.EX.wrt_mem;
                EXMEM_reg_write = state.EX.wrt_enable;
                EXMEM_branch = state.EX.branch;
                EXMEM_memto_reg = state.EX.mem_to_reg;
                EXMEM_rs1 = state.EX.Rs;
                EXMEM_rs2 = state.EX.Rt;
            }
            
            /* --------------------- ID stage --------------------- */
            if(cycle < 1){
                state.ID.nop = true;
            }
            
            if(!state.ID.nop){
                IDEX_PC = state.ID.PC;                                                                           //loading program counter in PC register
                IDEX_rs1 = (bitset<5>)((state.ID.Instr & (bitset<32>)0x000F8000) >> 15).to_ulong();              //decoding source register 1 address in rs1 register
                IDEX_data1 = myRF.readRF(IDEX_rs1);                                                              //reading rs1 register into data1 register
                IDEX_rs2 = (bitset<5>)((state.ID.Instr & (bitset<32>)0x01F00000) >> 20).to_ulong();              //decoding source register 2 address in rs2 register
                IDEX_data2 = myRF.readRF(IDEX_rs2);                                                              //reading rs2 register into data2 register
                IDEX_imm = imm_gen(state.ID.Instr);                                                              //decoding immediate value into imm register
                IDEX_write_reg_addr = (bitset<5>)((state.ID.Instr & (bitset<32>)0x00000F80) >> 7).to_ulong();   //decoding destination register address into write_reg_addr
                IDEX_funct = (bitset<4>)(((state.ID.Instr & (bitset<32>)0x40000000) >> 27).to_ulong()
                                         + ((state.ID.Instr & (bitset<32>)0x00007000) >> 12).to_ulong());       //decoding funct3 and funct7 field
                control_logic(bitset<7>((state.ID.Instr & (bitset<32>)0x0000007F).to_ulong()));                 //initializing control signals according to instruction
                hazard_detection_unit();                                                                        //calling hazard detection unit
                if(!haz_det){
                    if(branch){                                                         //if hazard is not detected, checking if it is branch instruction
                        branch_forward_unit(IDEX_rs1, IDEX_rs2);                        //calling forward unit responsible for forwarding data during branch instruction
                        branch_unit();                                                  //function to assign a branch control signal if detected
                        if(branch_det){
                            state.IF.nop = true;                                        //if branch is detected, make the fetching stage no operation
                        }
                    }
                } else{
                    control_logic((bitset<7>)0);                                    //if hazard is detected, make all control signals as zero.
                }
                if((state.ID.Instr & (bitset<32>)0x0000007F).to_ulong() == HALT){
                    state.IF.nop = true;                                            //if HALT instruction is decoded, make the fetching stage no opeation
                }
            }

            
            /* --------------------- IF stage --------------------- */
            if(cycle == 0){                                     //during start of the program make the program counter = 0, and no operation flag false
                state.IF.PC = 0x00000000;
                state.IF.nop = false;
            }
            
            if(!haz_det & !state.IF.nop){                   //if hazard is not detected and nop flag is false for fetch, write to the PC and instruction register
                IFID_PC = state.IF.PC;
                IFID_instr = ext_imem.readInstr(state.IF.PC);
                instruction += 1;                           //variable for calculating CPI
            }
            if(IFID_instr.all()){
                state.IF.nop = true;
            }
            
            updateStates();     //function to update the states
            
            if (state.IF.nop && state.ID.nop && state.EX.nop && state.MEM.nop && state.WB.nop)
                halted = true;
        
            myRF.outputRF(cycle); // dump RF
            printState(nextState, cycle); //print states after executing cycle 0, cycle 1, cycle 2 ...
       
            state = nextState; //The end of the cycle and updates the current state with the values calculated in this cycle
            cycle++;
        }

        void printState(stateStruct state, int cycle) {
            ofstream printstate;
            if (cycle == 0)
                printstate.open(opFilePath, std::ios_base::trunc);
            else
                printstate.open(opFilePath, std::ios_base::app);
            if (printstate.is_open()) {
                printstate<<"----------------------------------------------------------------------"<<endl;
                printstate<<"State after executing cycle:"<<cycle<<endl;

                printstate<<"IF.nop:"<<(state.IF.nop ? "True" : "False")<<endl;
                printstate<<"IF.PC:"<<state.IF.PC.to_ulong()<<endl;
                
                printstate<<"ID.nop:"<<(state.ID.nop ? "True" : "False")<<endl;
                printstate<<"ID.Instr:"<<state.ID.Instr<<endl;

                printstate<<"EX.nop:"<<(state.EX.nop ? "True" : "False")<<endl;
                printstate<<"EX.Read_data1:"<<state.EX.Read_data1<<endl;
                printstate<<"EX.Read_data2:"<<state.EX.Read_data2<<endl;
                printstate<<"EX.Imm:"<<state.EX.Imm<<endl;
                printstate<<"EX.Rs:"<<state.EX.Rs<<endl;
                printstate<<"EX.Rt:"<<state.EX.Rt<<endl;
                printstate<<"EX.Wrt_reg_addr:"<<state.EX.Wrt_reg_addr<<endl;
                printstate<<"EX.is_I_type:"<<state.EX.is_I_type<<endl;
                printstate<<"EX.rd_mem:"<<state.EX.rd_mem <<endl;
                printstate<<"EX.wrt_mem:"<<state.EX.wrt_mem <<endl;
                printstate<<"EX.alu_op:"<<state.EX.alu_op<<endl;
                printstate<<"EX.wrt_enable:"<<state.EX.wrt_enable <<endl;

                printstate<<"MEM.nop:"<<(state.MEM.nop ? "True" : "False")<<endl;
                printstate<<"MEM.ALUresult:"<<state.MEM.ALUresult<<endl;
                printstate<<"MEM.Store_data:"<<state.MEM.Store_data<<endl;
                printstate<<"MEM.Rs:"<<state.MEM.Rs<<endl;
                printstate<<"MEM.Rt:"<<state.MEM.Rt<<endl;
                printstate<<"MEM.Wrt_reg_addr:"<<state.MEM.Wrt_reg_addr<<endl;
                printstate<<"MEM.rd_mem:"<<state.MEM.rd_mem<<endl;
                printstate<<"MEM.wrt_mem:"<<state.MEM.wrt_mem<<endl;
                printstate<<"MEM.wrt_enable:"<<state.MEM.wrt_enable<<endl;
                
                printstate<<"WB.nop:"<<(state.WB.nop ? "True" : "False")<<endl;
                printstate<<"WB.Wrt_data:"<<state.WB.Wrt_data<<endl;
                printstate<<"WB.Rs:"<<state.WB.Rs<<endl;
                printstate<<"WB.Rt:"<<state.WB.Rt<<endl;
                printstate<<"WB.Wrt_reg_addr:"<<state.WB.Wrt_reg_addr<<endl;
                printstate<<"WB.wrt_enable:"<<state.WB.wrt_enable<<endl;
            }
            else cout<<"Unable to open FS StateResult output file." << endl;
            printstate.close();
        }
    
        void updateStates(){            //function to update flip-flops for every stage after executing a single clock cycle
            
            /*------IF stage------*/
            if(haz_det | state.IF.nop){         //if hazard is detected or fetching stage is set to no operation
                if(branch_det){                 //if branching condition is true, update the program counter for jumping to the address
                    nextState.IF.PC = (bitset<32>)(state.ID.PC.to_ulong() + static_cast<int32_t>(shift_left_one(IDEX_imm).to_ulong()));
                } else{
                    nextState.IF.PC = state.IF.PC;      //if not keep the current program counter value
                }
            } else{
                nextState.IF.PC = state.IF.PC.to_ulong() + 4;       //if there is no hazard or branching, go to the next instruction
            }
            if(branch_det){                                     //if branch is detected make the no operation flag for the fetch stage false
                nextState.IF.nop = false;
            } else{
                nextState.IF.nop = state.IF.nop;                //otherwise maintain the flag
            }
            branch_det = false;                                 //update branch flag for next instructions to use it if required
            
            /*----ID stage------*/
            nextState.ID.nop = state.IF.nop;
            if(!nextState.ID.nop){                              //only update if the current state was valid and not no operation
                nextState.ID.Instr = IFID_instr;
                nextState.ID.PC = IFID_PC;
            }
            
            /*----EX stage------*/
            nextState.EX.nop = state.ID.nop;
            if(!nextState.EX.nop){                              //only update if the current state was valid and not no operation
                nextState.EX.Read_data1 = IDEX_data1;
                nextState.EX.Read_data2 = IDEX_data2;
                nextState.EX.Imm = IDEX_imm;
                nextState.EX.Wrt_reg_addr = IDEX_write_reg_addr;
                nextState.EX.funct = IDEX_funct;
                nextState.EX.PC = IDEX_PC;
                nextState.EX.Rs = IDEX_rs1;
                nextState.EX.Rt = IDEX_rs2;
                nextState.EX.nop = state.ID.nop;
                
                nextState.EX.is_I_type = aluSrc;
                nextState.EX.alu_op = aluop;
                nextState.EX.rd_mem = memRead;
                nextState.EX.wrt_mem = memWrite;
                nextState.EX.wrt_enable = regWrite;
                nextState.EX.branch = branch;
                nextState.EX.mem_to_reg = memtoReg;
            }
            
            /*----MEM stage------*/
            nextState.MEM.nop = state.EX.nop;
            if(!nextState.MEM.nop){                                 //only update if the current state was valid and not no operation
                nextState.MEM.ALUresult = EXMEM_ALUresult;
                nextState.MEM.Store_data = EXMEM_data2;
                nextState.MEM.alu_zero = EXMEM_aluZero;
                nextState.MEM.Wrt_reg_addr = EXMEM_write_reg_addr;
                nextState.MEM.Rs = EXMEM_rs1;
                nextState.MEM.Rt = EXMEM_rs2;
                
                
                nextState.MEM.rd_mem = EXMEM_mem_read;
                nextState.MEM.wrt_mem = EXMEM_mem_write;
                nextState.MEM.wrt_enable = EXMEM_reg_write;
                nextState.MEM.branch = EXMEM_branch;
                nextState.MEM.mem_to_reg = EXMEM_memto_reg;
            }
            
            /*----WB stage-----*/
            nextState.WB.nop = state.MEM.nop;
            if(!nextState.WB.nop){                                      //only update if the current state was valid and not no operation
                nextState.WB.Wrt_data = MEMWB_mem_data;
                nextState.WB.ALU_data = MEMWB_ALUresult;
                nextState.WB.Wrt_reg_addr = MEMWB_write_reg_addr;
                nextState.WB.Rs = MEMWB_rs1;
                nextState.WB.Rt = MEMWB_rs2;
                
                
                nextState.WB.mem_to_reg = MEMWB_memto_reg;
                nextState.WB.wrt_enable = MEMWB_reg_write;
            }
        }
            
        void forward_unit(bitset<5> rs1, bitset<5> rs2){            //forwarding module to forward data from MEM/WB to EX stage if required
            if((state.MEM.wrt_enable) & (state.MEM.Wrt_reg_addr.to_ulong() != 0) & (state.MEM.Wrt_reg_addr.to_ulong() == rs1.to_ulong()) & (!state.MEM.nop)){
                state.EX.Read_data1 = state.MEM.ALUresult;
            } else if((state.WB.wrt_enable) & (state.WB.Wrt_reg_addr.to_ulong() != 0) & (state.WB.Wrt_reg_addr.to_ulong() == rs1.to_ulong()) & (!state.WB.nop)){
                if(state.WB.mem_to_reg){
                    state.EX.Read_data1 = state.WB.Wrt_data;
                }else{
                    state.EX.Read_data1 = state.WB.ALU_data;
                }
            }
            if((state.MEM.wrt_enable) & (state.MEM.Wrt_reg_addr.to_ulong() != 0) & (state.MEM.Wrt_reg_addr.to_ulong() == rs2.to_ulong()) & (!state.MEM.nop)){
                state.EX.Read_data2 = state.MEM.ALUresult;
            } else if((state.WB.wrt_enable) & (state.WB.Wrt_reg_addr.to_ulong() != 0) & (state.WB.Wrt_reg_addr.to_ulong() == rs2.to_ulong()) & (!state.WB.nop)){
                if(state.WB.mem_to_reg){
                    state.EX.Read_data2 = state.WB.Wrt_data;
                }else{
                    state.EX.Read_data2 = state.WB.ALU_data;
                }
            }
        }
    
        void branch_forward_unit(bitset<5> rs1, bitset<5> rs2){         //forwarding module to forward data from EX/MEM/WB to ID stage if required for branching
            if((state.EX.wrt_enable) & (state.EX.Wrt_reg_addr.to_ulong() != 0) & (state.EX.Wrt_reg_addr.to_ulong() == rs1.to_ulong()) & (!state.EX.nop)){
                IDEX_data1 = EXMEM_ALUresult;
            } else if((state.MEM.wrt_enable) & (state.MEM.Wrt_reg_addr.to_ulong() != 0) & (state.MEM.Wrt_reg_addr.to_ulong() == rs1.to_ulong()) & (!state.MEM.nop)){
                IDEX_data1 = state.MEM.ALUresult;
            } else if((state.WB.wrt_enable) & (state.WB.Wrt_reg_addr.to_ulong() != 0) & (state.WB.Wrt_reg_addr.to_ulong() == rs1.to_ulong()) & (!state.WB.nop)){
                if(state.WB.mem_to_reg){
                    IDEX_data1 = state.WB.Wrt_data;
                }else{
                    IDEX_data1 = state.WB.ALU_data;
                }
            }
            if((state.EX.wrt_enable) & (state.EX.Wrt_reg_addr.to_ulong() != 0) & (state.EX.Wrt_reg_addr.to_ulong() == rs2.to_ulong()) & (!state.EX.nop)){
                IDEX_data2 = EXMEM_ALUresult;
            } else if((state.MEM.wrt_enable) & (state.MEM.Wrt_reg_addr.to_ulong() != 0) & (state.MEM.Wrt_reg_addr.to_ulong() == rs2.to_ulong()) & (!state.MEM.nop)){
                IDEX_data2 = state.MEM.ALUresult;
            } else if((state.WB.wrt_enable) & (state.WB.Wrt_reg_addr.to_ulong() != 0) & (state.WB.Wrt_reg_addr.to_ulong() == rs2.to_ulong()) & (!state.WB.nop)){
                if(state.WB.mem_to_reg){
                    IDEX_data2 = state.WB.Wrt_data;
                }else{
                    IDEX_data2 = state.WB.ALU_data;
                }
            }
        }
    
        void hazard_detection_unit(){       //hazard detection module for stalling pipeline if required
            if(state.EX.rd_mem & !state.EX.nop & ((state.EX.Wrt_reg_addr.to_ulong() == IDEX_rs1.to_ulong()) | ((state.EX.Wrt_reg_addr.to_ulong() == IDEX_rs2.to_ulong())))){
                haz_det = true;
                state.ID.nop = true;
            }
            else{
                haz_det = false;
            }
        }
    
        void branch_unit(){                 //function for checking branching condition
            bitset<32> res;
            res = (bitset<32>)(IDEX_data1.to_ulong() - IDEX_data2.to_ulong());
            if(regWrite){
                branch_det = true;
            } else if(((IDEX_funct & (bitset<4>)0x7).to_ulong() == 0) & (res.to_ulong() == 0)){
                branch_det = true;
                state.ID.nop = true;
            } else if(((IDEX_funct & (bitset<4>)0x7).to_ulong() == 1) & (res.to_ulong() != 0)){
                branch_det = true;
                state.ID.nop = true;
            } else{
                branch_det = false;
                state.ID.nop = true;
            }
        }
            
    private:
        string opFilePath;
        
        bool haz_det;
        bool branch_det;
    
    /*-----------IF/ID FLIP_FLOP---------------*/
        bitset<32> IFID_PC;
        bitset<32> IFID_instr;

    /*-----------ID/EX FLIP_FLOP---------------*/
        bitset<32> IDEX_PC;
        bitset<32> IDEX_data1;
        bitset<32> IDEX_data2;
        bitset<32> IDEX_imm;
        bitset<4> IDEX_funct;
        bitset<5> IDEX_write_reg_addr;
        bitset<5> IDEX_rs1;
        bitset<5> IDEX_rs2;
    
    /*-----------EX/MEM FLIP_FLOP---------------*/
        bitset<32> EXMEM_ALUresult;
        bitset<32> EXMEM_data2;
        bitset<5> EXMEM_write_reg_addr;
        bitset<5> EXMEM_rs1;
        bitset<5> EXMEM_rs2;
        bool EXMEM_aluZero;
    
        bool EXMEM_branch;
        bool EXMEM_mem_read;
        bool EXMEM_mem_write;
        bool EXMEM_reg_write;
        bool EXMEM_memto_reg;
    
    /*-----------MEM/WB FLIP_FLOP---------------*/
        bitset<32> MEMWB_mem_data;
        bitset<32> MEMWB_ALUresult;
        bitset<5> MEMWB_write_reg_addr;
        bitset<5> MEMWB_rs1;
        bitset<5> MEMWB_rs2;
    
        bool MEMWB_reg_write;
        bool MEMWB_memto_reg;
        
};

void printMetric(string metFilePath, int ss_cycle, int fs_cycle, int ss_instruction, int fs_instruction){
    ofstream printmetric;
    printmetric.open(metFilePath);
    if(printmetric.is_open()){
        printmetric << "Performance of Single Stage:" << endl;
        printmetric << "#Cycles -> " << ss_cycle << endl;
        printmetric << "#Instructions -> " << ss_instruction << endl;
        printmetric << "CPI -> " << (double)ss_cycle/(double)ss_instruction << endl;
        printmetric << "IPC -> " << (double)ss_instruction/(double)ss_cycle << endl;
        printmetric << "\n";
        printmetric << "Performance of Five Stage:" << endl;
        printmetric << "#Cycles -> " << fs_cycle << endl;
        printmetric << "#Instructions -> " << fs_instruction << endl;
        printmetric << "CPI -> " << (double)fs_cycle/(double)fs_instruction << endl;
        printmetric << "IPC -> " << (double)fs_instruction/(double)fs_cycle << endl;
    }
    else cout<< "Unable to open Performance Metrics file." << endl;
    printmetric.close();
}

 int main(int argc, char* argv[]) {
     string ioDir = "";
     if (argc == 1) {
         cout << "Enter path containing the memory files: ";
         cin >> ioDir;
     }
     else if (argc > 2) {
         cout << "Invalid number of arguments. Machine stopped." << endl;
         return -1;
     }
     else {
         ioDir = argv[1];
         cout << "IO Directory: " << ioDir << endl;
     }

    InsMem imem = InsMem("Imem", ioDir);
    DataMem dmem_ss = DataMem("SS", ioDir);
    DataMem dmem_fs = DataMem("FS", ioDir);

    SingleStageCore SSCore(ioDir, imem, dmem_ss);
    FiveStageCore FSCore(ioDir, imem, dmem_fs);
    

    while (1) {
        if (!SSCore.halted)
            SSCore.step();
        
        if (!FSCore.halted)
            FSCore.step();

        if (SSCore.halted && FSCore.halted)
            break;
    }
    
    printMetric(ioDir + "/PerformanceMetrics.txt", SSCore.cycle, FSCore.cycle, SSCore.instruction, FSCore.instruction);
    
    // dump SS and FS data mem.
    dmem_ss.outputDataMem();
    dmem_fs.outputDataMem();

    return 0;
}

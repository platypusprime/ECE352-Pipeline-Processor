// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	a simple processor which operates basic mathematical
//					operations as follow:
//					(1)loading, (2)storing, (3)adding, (4)subtracting,
//					(5)shifting, (6)oring, (7)branch if zero,
//					(8)branch if not zero, (9)branch if positive zero
//					 
// Input(s):		1. KEY0(reset): clear all values from registers,
//									reset flags condition, and reset
//									control FSM
//					2. KEY1(clock): manual clock controls FSM and all
//									synchronous components at every
//									positive clock edge
//
//
// Output(s):		1. HEX Display: display registers value K3 to K1
//									in hexadecimal format
//
//					** For more details, please refer to the document
//					   provided with this implementation
//
// ---------------------------------------------------------------------

module multicycle
(
SW, KEY, HEX0, HEX1, HEX2, HEX3,
HEX4, HEX5, LEDR
);

// ------------------------ PORT declaration ------------------------ //
input	[1:0] KEY;
input	[4:0] SW;
output [6:0] HEX0, HEX1, HEX2, HEX3;
output [6:0] HEX4, HEX5;
output reg [17:0] LEDR;

// ------------------------- Registers/Wires ------------------------ //
wire	clock, reset;
wire	IRRFLoad, IREXLoad, IRWBLoad;
wire	MDRLoad, MemRead, MemWrite, PCWrite, RegIn, AddrSel;
wire	ALUOutWrite, FlagWrite, R1R2Load, R1Sel, RFWrite;
wire	[7:0] R2wire, PCwire, R1wire, RFout1wire, RFout2wire;
wire	[7:0] ALU1wire, ALU2wire, ALUwire, ALUOut, MDRwire, MEMwire, MEMwire_pc;
wire	[7:0] IR_RF, IR_EX, IR_WB;
wire	[7:0] SE4wire, ZE5wire, ZE3wire, AddrWire, RegWire;
wire	[7:0] reg0, reg1, reg2, reg3;
wire	[7:0] constant;
wire	[2:0] ALUOp, ALU2;
wire	[1:0] R1_in;
wire	[7:0] PCin, PCAdderWire;
wire	[2:0] const_addop; 
wire	PCSel, narnia;
wire	Nwire, Zwire;
reg		N, Z;

wire	[15:0] PfmCntrWire;
reg 	[15:0] PfmCntr;

wire	stopWire;
reg	stop;

// ------------------------ Input Assignment ------------------------ //
assign	clock = KEY[1];
assign	reset =  ~KEY[0]; // KEY is active high


// ------------------- DE2 compatible HEX display ------------------- //
HEXs	HEX_display(
	.in0(reg0),.in1(reg1),.in2(reg2),.in3(reg3),.in4(PfmCntrWire),.selH(SW[0]),
	.out0(HEX0),.out1(HEX1),.out2(HEX2),.out3(HEX3),
	.out4(HEX4),.out5(HEX5)
);
// ----------------- END DE2 compatible HEX display ----------------- //


PipelineControl		Control(
	.reset(reset),.clock(clock),.N(N),.Z(Z),
	.instr_RF(IR_RF[3:0]),.instr_EX(IR_EX[3:0]),.instr_WB(IR_WB[3:0]),
	.PCwrite(PCWrite),.PCSel(PCSel),.MemRead(MemRead),.MemWrite(MemWrite),
	.IRRFLoad(IRRFLoad),.IREXLoad(IREXLoad),.IRWBLoad(IRWBLoad),
	.R1Sel(R1Sel),.RWSel(RWSel),.MDRload(MDRLoad),.R1R2Load(R1R2Load),.ALU2(ALU2),.ALUop(ALUOp),
	.ALUOutWrite(ALUOutWrite),.RFWrite(RFWrite),.RegIn(RegIn),.FlagWrite(FlagWrite),
	.Stop(stopWire)
);

memory	DataMem(
	.MemRead(MemRead),.wren(MemWrite),.clock(clock),
	.address(R2wire),.address_pc(PCwire),.data(R1wire),
	.q(MEMwire),.q_pc(MEMwire_pc)
);

ALU		ALU(
	.in1(R1wire),.in2(ALU2wire),.out(ALUwire),
	.ALUOp(ALUOp),.N(Nwire),.Z(Zwire)
);

RF		RF_block(
	.clock(clock),.reset(reset),.RFWrite(RFWrite),
	.dataw(RegWire),.reg1(R1_in),.reg2(IR_RF[5:4]),
	.regw(RW_in),.data1(RFout1wire),.data2(RFout2wire),
	.r0(reg0),.r1(reg1),.r2(reg2),.r3(reg3)
);

register_8bit	IR_RF_reg(
	.clock(clock),.aclr(reset),.enable(IRRFLoad),
	.data(MEMwire_pc),.q(IR_RF)
);

register_8bit	IR_EX_reg(
	.clock(clock),.aclr(reset),.enable(IREXLoad),
	.data(IR_RF),.q(IR_EX)
);

register_8bit	IR_WB_reg(
	.clock(clock),.aclr(reset),.enable(IRWBLoad),
	.data(IR_EX),.q(IR_WB)
);

register_8bit	MDR_reg(
	.clock(clock),.aclr(reset),.enable(MDRLoad),
	.data(MEMwire),.q(MDRwire)
);

mux2to1_8bit	PCSel_mux(
	.data0x(PCAdderWire),.data1x(ALUwire),
	.sel(PCSel),.result(PCin)
);

ALU		PCAdder(
	.in1(PCWire),.in2(constant),.out(PCAdderWire),
	.ALUOp(const_addop),.N(narnia),.Z(narnia)
);

register_8bit	PC(
	.clock(clock),.aclr(reset),.enable(PCWrite),
	.data(PCin),.q(PCwire)
);

register_8bit	R1(
	.clock(clock),.aclr(reset),.enable(R1R2Load),
	.data(RFout1wire),.q(R1wire)
);

register_8bit	R2(
	.clock(clock),.aclr(reset),.enable(R1R2Load),
	.data(RFout2wire),.q(R2wire)
);

register_8bit	ALUOut_reg(
	.clock(clock),.aclr(reset),.enable(ALUOutWrite),
	.data(ALUwire),.q(ALUOut)
);

mux2to1_2bit		R1Sel_mux(
	.data0x(IR_RF[7:6]),.data1x(constant[1:0]),
	.sel(R1Sel),.result(R1_in)
);

mux2to1_2bit		RWSel_mux(
	.data0x(IR_WB[7:6]),.data1x(constant[1:0]),
	.sel(RWSel),.result(RW_in)
);

mux2to1_8bit 		RegMux(
	.data0x(ALUOut),.data1x(MDRwire),
	.sel(RegIn),.result(RegWire)
);

mux5to1_8bit 		ALU2_mux(
	.data0x(R2wire),.data1x(constant),.data2x(SE4wire),
	.data3x(ZE5wire),.data4x(ZE3wire),.sel(ALU2),.result(ALU2wire)
);

sExtend		SE4(.in(IR_RF[7:4]),.out(SE4wire));
zExtend		ZE3(.in(IR_RF[5:3]),.out(ZE3wire));
zExtend		ZE5(.in(IR_RF[7:3]),.out(ZE5wire));
// define parameter for the data size to be extended
defparam	SE4.n = 4;
defparam	ZE3.n = 3;
defparam	ZE5.n = 5;

always@(posedge clock or posedge reset)
begin
if (reset)
	begin
	N <= 0;
	Z <= 0;
	stop <= 0;
	PfmCntr <= 16'b0;
	end
else
if (FlagWrite)
	begin
	N <= Nwire;
	Z <= Zwire;
	if(~stop)
		PfmCntr <= PfmCntr + 1;
	end
else
if (stopWire)
	stop <= stopWire;
else
if(~stop)
	PfmCntr <= PfmCntr + 1;
end

// ------------------------ Assign Constants ------------------------ //
assign	constant = 1;
assign	PfmCntrWire = PfmCntr;
assign	const_addop = 3'b000;

// ------------------------- LEDs Indicator ------------------------- //
always @ (*)
begin

    case({SW[4],SW[3]})
    2'b00:
    begin
      LEDR[9] = 0;
      LEDR[8] = 0;
      LEDR[7] = PCWrite;
      LEDR[6] = PCSel;
      LEDR[5] = MemRead;
      LEDR[4] = MemWrite;
      //LEDR[3] = IRLoad;
      LEDR[2] = R1Sel;
      LEDR[1] = MDRLoad;
      LEDR[0] = R1R2Load;
    end

    2'b01:
    begin
      //LEDR[9] = ALU1;
      LEDR[8:6] = ALU2[2:0];
      LEDR[5:3] = ALUOp[2:0];
      LEDR[2] = ALUOutWrite;
      LEDR[1] = RFWrite;
      LEDR[0] = RegIn;
    end

    2'b10:
    begin
      LEDR[9] = 0;
      LEDR[8] = 0;
      LEDR[7] = FlagWrite;
      LEDR[6:2] = constant[7:3];
      LEDR[1] = N;
      LEDR[0] = Z;
    end

    2'b11:
    begin
      LEDR[9:0] = 10'b0;
    end
  endcase
end
endmodule

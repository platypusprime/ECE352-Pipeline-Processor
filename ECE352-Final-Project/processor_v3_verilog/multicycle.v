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
input 	[4:0] SW;
output	[6:0] HEX0, HEX1, HEX2, HEX3;
output	[6:0] HEX4, HEX5;
output reg [17:0] LEDR;

// ------------------------- Registers/Wires ------------------------ //
wire	clock, reset;
wire	/*IRDELoad,*/ IRRFLoad, IREXLoad, IRWBLoad;
wire	MDRLoad, MemRead, MemWrite, PCWrite, PCSel, RegIn;
wire	ALUOutWrite, FlagWrite, R1R2Load, R1Sel, RWSel, RFWrite;
wire	[7:0] R2wire, PCin, PCwire, ALU_PCout, R1wire, RFout1wire, RFout2wire;
wire	[7:0] ALU1wire, ALU2wire, ALUwire, ALUOut, MDRwire, MemDataWire, MemInstrWire;
wire	[7:0] /*IRDE,*/ IRRF, IREX, IRWB;
wire	[7:0] SE4wire, ZE5wire, ZE3wire, AddrWire, RegWire;
wire	[7:0] reg0, reg1, reg2, reg3;
wire	[7:0] c_ONE;
wire	ALU1;
wire	[2:0] ALUOp, ALU_PCop, ALU2;
wire	[1:0] R1_in, RW_in;
wire	Nwire, Zwire;
reg		N, Z;
wire	[15:0] cycles;

// ------------------------ Input Assignment ------------------------ //
assign	clock = KEY[1];
assign	reset =  ~KEY[0]; // KEY is active high


// ------------------- DE2 compatible HEX display ------------------- //
HEXs	HEX_display(
	.in0(reg0),.in1(reg1),.in2(reg2),.in3(reg3),.selH(SW[0]),
	.out0(HEX0),.out1(HEX1),.out2(HEX2),.out3(HEX3),
	.out4(HEX4),.out5(HEX5)
);
// ----------------- END DE2 compatible HEX display ----------------- //

PipelineControl		Control(
	.reset(reset),.clock(clock),.N(N),.Z(Z),
	/*.instrDE(IRDE[3:0]),*/.instrRF(IRRF[3:0]),.instrEX(IREX[3:0]),.instrWB(IRWB[3:0]),
	.PCwrite(PCWrite),.MemRead(MemRead),.MemWrite(MemWrite),
	/*.IRDEload(IRDELoad),*/.IRRFload(IRRFLoad),.IREXload(IREXLoad),.IRWBload(IRWBLoad),
	.R1Sel(R1Sel),.RWSel(RWSel),.MDRload(MDRLoad),.R1R2Load(R1R2Load),
	.PCSel(PCSel),.ALUOutWrite(ALUOutWrite),.RFWrite(RFWrite),.RegIn(RegIn),
	.FlagWrite(FlagWrite),.ALU1(ALU1),.ALU2(ALU2),.ALUop(ALUOp),.ALU_PCop(ALU_PCop),
	.cycles(cycles)
);

memory	DataMem(
	.MemRead(MemRead),.wren(MemWrite),.clock(clock),
	.address(R2wire),.address_pc(PCwire),.data(R1wire),
	.q(MemDataWire),.q_pc(MemInstrWire)
);

ALU		ALU(
	.in1(ALU1wire),.in2(ALU2wire),.out(ALUwire),
	.ALUOp(ALUOp),.N(Nwire),.Z(Zwire)
);

RF		RF_block(
	.clock(clock),.reset(reset),.RFWrite(RFWrite),
	.dataw(RegWire),.reg1(R1_in),.reg2(IRRF/*DE*/[5:4]),
	.regw(RW_in),.data1(RFout1wire),.data2(RFout2wire),
	.r0(reg0),.r1(reg1),.r2(reg2),.r3(reg3)
);

/*register_8bit	IRDE_reg(
	.clock(clock),.aclr(reset),.enable(IRDELoad),
	.data(MemInstrWire),.q(IRDE)
);*/

register_8bit	IRRF_reg(
	.clock(clock),.aclr(reset),.enable(IRRFLoad),
	.data(MemInstrWire),.q(IRRF)
);

register_8bit	IREX_reg(
	.clock(clock),.aclr(reset),.enable(IREXLoad),
	.data(IRRF),.q(IREX)
);

register_8bit	IRWB_reg(
	.clock(clock),.aclr(reset),.enable(IRWBLoad),
	.data(IREX),.q(IRWB)
);

register_8bit	MDR_reg(
	.clock(clock),.aclr(reset),.enable(MDRLoad),
	.data(MemDataWire),.q(MDRwire)
);

register_8bit	PC(
	.clock(clock),.aclr(reset),.enable(PCWrite),
	.data(PCin),.q(PCwire)
);

ALU		ALU_PC(
	.in1(PCwire),.in2(c_ONE),.ALUOp(ALU_PCop),
	.out(ALU_PCout)
);

mux2to1_8bit	PCSel_mux(
	.data0x(ALU_PCout),.data1x(ALUwire),
	.sel(PCSel),.result(PCin)
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
	.data0x(IRRF/*DE*/[7:6]),.data1x(c_ONE[1:0]),
	.sel(R1Sel),.result(R1_in)
);

mux2to1_2bit		RWSel_mux(
	.data0x(IRWB[7:6]),.data1x(c_ONE[1:0]),
	.sel(RWSel),.result(RW_in)
);

mux2to1_8bit 		RegMux(
	.data0x(ALUOut),.data1x(MDRwire),
	.sel(RegIn),.result(RegWire)
);

mux2to1_8bit 		ALU1_mux(
	.data0x(/*PCwire*/ALU_PCout),.data1x(R1wire),
	.sel(ALU1),.result(ALU1wire)
);

mux5to1_8bit 		ALU2_mux(
	.data0x(R2wire),.data1x(c_ONE),.data2x(SE4wire),
	.data3x(ZE5wire),.data4x(ZE3wire),.sel(ALU2),.result(ALU2wire)
);

sExtend		SE4(.in(IREX[7:4]),.out(SE4wire));
zExtend		ZE3(.in(IREX[5:3]),.out(ZE3wire));
zExtend		ZE5(.in(IREX[7:3]),.out(ZE5wire));
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
	end
else
if (FlagWrite)
	begin
	N <= Nwire;
	Z <= Zwire;
	end
end

// ------------------------ Assign c_ONE 1 ----------------------- //
assign	c_ONE = 1;

// ------------------------- LEDs Indicator ------------------------- //
always @ (*)
begin

    case({SW[4],SW[3]})
    2'b00:
    begin
      LEDR[9] = 0;
      LEDR[8] = 0;
      LEDR[7] = PCWrite;
      LEDR[6] = 0;
      LEDR[5] = MemRead;
      LEDR[4] = MemWrite;
      LEDR[3] = 0;
      LEDR[2] = R1Sel;
      LEDR[1] = MDRLoad;
      LEDR[0] = R1R2Load;
    end

    2'b01:
    begin
      LEDR[9] = ALU1;
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
      LEDR[6:2] = c_ONE[7:3];
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

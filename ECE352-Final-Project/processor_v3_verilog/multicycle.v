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
wire	[15:0] cycles;
wire	Nwire, Zwire;
reg		N, Z;

//// register enables ////
wire	RFLoad, EXLoad, WBLoad, PCWrite, WBRegWrite, FlagWrite;
wire	MemRead, MemWrite, RFWrite;
//// register outputs ////
wire	[7:0] reg0, reg1, reg2, reg3;
wire	[7:0] IRRF, IREX, IRWB;
wire	[7:0] PCout, R1RegOut, R2RegOut, RFout1, RFout2, WBRegOut;
wire	[7:0] MemOut_data, MemOut_instr;

//// mux selects ////
wire	PCSel, RFin1Sel, RWSel, R1inSel, R2inSel, WBRegSel;
wire	[1:0] ALU1Sel;
wire	[2:0] ALU2Sel, ALUOp, ALUPCOp;
//// mux outputs ////
wire	[1:0] RFin1, RFWin;
wire	[7:0] PCin, R1in, R2in, ALUOutInWire;

//// operation inputs ////
wire	[7:0] ALUin1, ALUin2, ALUout;
wire	[7:0] c_ONE;
//// operation outputs ////
wire	[7:0] ALU_PCout, SE4wire, ZE5wire, ZE3wire;

//// removed ////
//wire	MDRLoad, RegIn, R1R2Load, AddrWire, RegWire, MDRwire;



// ------------------------ Input Assignment ------------------------ //
assign	clock = KEY[1];
assign	reset =  ~KEY[0]; // KEY is active high


// ------------------- DE2 compatible HEX display ------------------- //
HEXs	HEX_display( // TODO
	.in0(reg0),.in1(reg1),.in2(reg2),.in3(reg3),.selH(SW[0]),
	.out0(HEX0),.out1(HEX1),.out2(HEX2),.out3(HEX3),
	.out4(HEX4),.out5(HEX5)
);
// ----------------- END DE2 compatible HEX display ----------------- //

PipelineControl		Control(
	.reset(reset),.clock(clock),.N(N),.Z(Z),
	.instrRF(IRRF),.instrEX(IREX),.instrWB(IRWB),
	.RFLoad(RFLoad),.EXLoad(EXLoad),.WBLoad(WBLoad),
	.PCwrite(PCWrite),.WBRegWrite(WBRegWrite),.FlagWrite(FlagWrite),
	.MemRead(MemRead),.MemWrite(MemWrite),.RFWrite(RFWrite),.PCSel(PCSel),.RFin1Sel(RFin1Sel),
	.RWSel(RWSel),.R1inSel(R1inSel),.R2inSel(R2inSel),.WBRegSel(WBRegSel),
	.ALU1Sel(ALU1Sel),.ALU2Sel(ALU2Sel),.ALUop(ALUOp),.ALUPCOp(ALUPCOp),
	.cycles(cycles)
);

memory	DataMem(
	.MemRead(MemRead),.wren(MemWrite),.clock(clock),
	.address(/*R2RegOut*/ALUin2),.address_pc(PCout),.data(/*R1RegOut*/ALUin1),
	.q(MemOut_data),.q_pc(MemOut_instr)
);

ALU		ALU(
	.in1(ALUin1),.in2(ALUin2),.out(ALUout),
	.ALUOp(ALUOp),.N(Nwire),.Z(Zwire)
);

RF		RF_block(
	.clock(clock),.reset(reset),.RFWrite(RFWrite),
	.dataw(WBRegOut),.reg1(RFin1),.reg2(IRRF[5:4]),
	.regw(RFWin),.data1(RFout1),.data2(RFout2),
	.r0(reg0),.r1(reg1),.r2(reg2),.r3(reg3)
);

register_8bit	IRRF_reg(
	.clock(clock),.aclr(reset),.enable(RFLoad),
	.data(MemOut_instr),.q(IRRF)
);

register_8bit	IREX_reg(
	.clock(clock),.aclr(reset),.enable(EXLoad),
	.data(IRRF),.q(IREX)
);

register_8bit	IRWB_reg(
	.clock(clock),.aclr(reset),.enable(WBLoad),
	.data(IREX),.q(IRWB)
);

mux2to1_8bit	PCSel_mux(
	.data0x(ALU_PCout),.data1x(ALUout),
	.sel(PCSel),.result(PCin)
);

register_8bit	PC(
	.clock(clock),.aclr(reset),.enable(PCWrite),
	.data(PCin),.q(PCout)
);

ALU		ALU_PC(
	.in1(PCout),.in2(c_ONE),.ALUOp(ALUPCOp),
	.out(ALU_PCout)
);

mux2to1_8bit	R1DataSel_mux(
	.data0x(WBRegOut),.data1x(RFout1),
	.sel(R1inSel),.result(R1in)
);

register_8bit	R1(
	.clock(clock),.aclr(reset),.enable(EXLoad/*R1R2Load*/),
	.data(R1in),.q(R1RegOut)
);

mux2to1_8bit	R2DataSel_mux(
	.data0x(WBRegOut),.data1x(RFout2),
	.sel(R2inSel),.result(R2in)
);

register_8bit	R2(
	.clock(clock),.aclr(reset),.enable(EXLoad/*R1R2Load*/),
	.data(R2in),.q(R2RegOut)
);

mux2to1_8bit	WBRegSel_mux(
	.data0x(ALUout),.data1x(MemOut_data),
	.sel(WBRegSel),.result(ALUOutInWire)
);

register_8bit	WB_reg(
	.clock(clock),.aclr(reset),.enable(WBRegWrite),
	.data(ALUOutInWire),.q(WBRegOut)
);

mux2to1_2bit		R1Sel_mux(
	.data0x(IRRF[7:6]),.data1x(c_ONE[1:0]),
	.sel(RFin1Sel),.result(RFin1)
);

mux2to1_2bit		RWSel_mux(
	.data0x(IRWB[7:6]),.data1x(c_ONE[1:0]),
	.sel(RWSel),.result(RFWin)
);

mux3to1_8bit 		ALU1_mux(
	.data0x(ALU_PCout),.data1x(R1RegOut),.data2x(WBRegOut),
	.sel(ALU1Sel),.result(ALUin1)
);

mux5to1_8bit 		ALU2_mux(
	.data0x(R2RegOut),.data1x(WBRegOut),.data2x(SE4wire),
	.data3x(ZE5wire),.data4x(ZE3wire),.sel(ALU2Sel),.result(ALUin2)
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
      LEDR[2] = RFin1Sel;
      //LEDR[1] = MDRLoad;
      //LEDR[0] = R1R2Load;
    end

    2'b01:
    begin
      LEDR[9] = ALU1Sel;
      LEDR[8:6] = ALU2Sel[2:0];
      LEDR[5:3] = ALUOp[2:0];
      LEDR[2] = WBRegWrite;
      LEDR[1] = RFWrite;
      //LEDR[0] = RegIn;
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

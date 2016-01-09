module PipelineControl
(
reset, clock, N, Z,
instr_RF, instr_EX, instr_WB,
PCwrite, PCSel, MemRead,MemWrite, 
IRRFLoad, IREXLoad, IRWBLoad,
R1Sel, RWSel, MDRload, R1R2Load, ALU2, ALUop,
ALUOutWrite, RFWrite, RegIn, FlagWrite,
Stop
);
	// I/O
	input	reset, clock, N, Z;
	input	[3:0] instr_RF, instr_EX, instr_WB;
	output	PCwrite, PCSel, MemRead, MemWrite;
	output	IRRFLoad, IREXLoad, IRWBLoad;
	output	R1Sel, RWSel, MDRload, R1R2Load;
	output	ALUOutWrite, RFWrite, RegIn, FlagWrite, Stop;
	output	[2:0] ALU2, ALUop;

	// internal registers
	reg			isStopped;
	reg			PCwrite, PCSel, MemRead, MemWrite;
	reg			IRRFLoad, IREXLoad, IRWBLoad;
	reg			R1Sel, RWSel, MDRload, R1R2Load;
	reg			ALUOutWrite, RFWrite, RegIn, FlagWrite, Stop;
	reg	[2:0]	ALU2, ALUop;
	
	// determines the next state based upon the current state; supports
	// asynchronous reset
	always @(posedge clock or posedge reset)
	begin
		if (reset) isStopped = 0;		
		else begin
			case(isStopped)
				0:	begin
					if (instr_EX == 4'b0001) isStopped = 1;
					else isStopped = 0;
				end
				1:		isStopped = 1;
			endcase
		end
	end
	
	// sets the control sequences based upon the current state and instruction
	always @(*)
	begin
		if (isStopped == 1) begin
			Stop = 1;
			PCwrite = 0;
			IRRFLoad = 0;
			IREXLoad = 0;
			IRWBLoad = 0;
			R1R2Load = 0;
			MemRead = 0;
			MemWrite = 0;
			ALU2 = 3'b000;
			ALUop = 3'b000;
			ALUOutWrite = 0;
			FlagWrite = 0;
			PCSel = 0;
			RWSel = 0;
			RegIn = 0;
			RFWrite = 0;
			ALUOutWrite = 0;
			R1Sel = 0;
			MDRload = 0;
			// TODO make sure things are stopped
		end
		else begin
			IRRFLoad = 1;
			IREXLoad = 1;
			IRWBLoad = 1;
			Stop = 0;

			// RF stage
			R1R2Load = 1;
			MemRead = 1;
			if (instr_RF[2:0] == 3'b111) R1Sel = 1;
			else R1Sel = 0;
			
			// EX stage
			PCwrite = 1;
			if (instr_EX == 4'b0100) begin			// add
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b000;
				ALUop = 3'b000;
				ALUOutWrite = 1;
				FlagWrite = 1;
				PCSel = 0;
				Stop = 0;
			end
			else if (instr_EX == 4'b0110) begin		// sub
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b000;
				ALUop = 3'b001;
				ALUOutWrite = 1;
				FlagWrite = 1;
				PCSel = 0;
				Stop = 0;
			end
			else if (instr_EX == 4'b1000) begin		// nand
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b000;
				ALUop = 3'b011;
				ALUOutWrite = 1;
				FlagWrite = 1;
				PCSel = 0;
				Stop = 0;
			end
			else if (instr_EX[2:0] == 3'b011) begin	// shift
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b100;
				ALUop = 3'b100;
				ALUOutWrite = 1;
				FlagWrite = 1;
				PCSel = 0;
				Stop = 0;
			end
			else if (instr_EX[2:0] == 3'b111) begin	// ori
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b011;
				ALUop = 3'b010;
				ALUOutWrite = 1;
				FlagWrite = 1;
				PCSel = 0;
				Stop = 0;
			end
			else if (instr_EX == 4'b0010) begin		// store
				MemWrite = 1;
				MDRload = 0;
				ALU2 = 3'b000;
				ALUop = 3'b000;
				ALUOutWrite = 0;
				FlagWrite = 0;
				PCSel = 0;
				Stop = 0;
			end
			else if (instr_EX == 4'b0000) begin		// load
				MemWrite = 0;
				MDRload = 1;
				ALU2 = 3'b000;
				ALUop = 3'b000;
				ALUOutWrite = 0;
				FlagWrite = 0;
				PCSel = 0;
				Stop = 0;
			end
			else if (instr_EX == 4'b1101) begin		// bpz
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b010;
				ALUop = 3'b000;
				ALUOutWrite = 0;
				FlagWrite = 0;
				PCSel = ~N;
				Stop = 0;
			end
			else if (instr_EX == 4'b0101) begin		// bz
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b011;
				ALUop = 3'b010;
				ALUOutWrite = 1;
				FlagWrite = 1;
				PCSel = Z;
				Stop = 0;
			end
			else if (instr_EX == 4'b1001) begin		// bnz
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b011;
				ALUop = 3'b010;
				ALUOutWrite = 1;
				FlagWrite = 1;
				PCSel = ~Z;
				Stop = 0;
			end
			else if (instr_EX == 4'b0001) begin		// stop
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b000;
				ALUop = 3'b000;
				ALUOutWrite = 0;
				FlagWrite = 0;
				PCSel = 0;
				Stop = 1;
			end
			else begin								// default
				MemWrite = 0;
				MDRload = 0;
				ALU2 = 3'b000;
				ALUop = 3'b000;
				ALUOutWrite = 0;
				FlagWrite = 0;
				PCSel = 0;
				Stop = 0;
			end
			
			// EX stage
			if (instr_WB == 4'b0100 | instr_WB == 4'b0110 | instr_WB == 4'b1000 | 
				instr_WB[2:0] == 3'b011 ) begin		// ALU operations except ori
				RWSel = 0;
				RegIn = 0;
				RFWrite = 1;
				ALUOutWrite = 0;
			end
			if (instr_WB[2:0] == 3'b111) begin		// ori
				RWSel = 1;
				RegIn = 0;
				RFWrite = 1;
				ALUOutWrite = 0;
			end
			else if (instr_WB == 4'b0000) begin		// load
				RWSel = 0;
				RegIn = 1;
				RFWrite = 1;
				ALUOutWrite = 1;
			end
			else begin								// default
				RWSel = 0;
				RegIn = 0;
				RFWrite = 0;
				ALUOutWrite = 0;
			end
			
		end
	end
	
endmodule

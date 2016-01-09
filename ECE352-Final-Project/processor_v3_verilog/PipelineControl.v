// ---------------------------------------------------------------------
// Copyright (c) 2007 by University of Toronto ECE 243 development team 
// ---------------------------------------------------------------------
//
// Major Functions:	control processor's datapath
// 
// Input(s):	1. instr: input is used to determine states
//				2. N: if branches, input is used to determine if
//					  negative condition is true
//				3. Z: if branches, input is used to determine if 
//					  zero condition is true
//
// Output(s):	control signals
//
//				** More detail can be found on the course note under
//				   "Multi-Cycle Implementation: The Control Unit"
//
// ---------------------------------------------------------------------

module PipelineControl
(
reset, clock, /*instrDE,*/ instrRF, instrEX, instrWB, N, Z,
PCwrite, PCSel, MemRead, MemWrite, /*IRDEload,*/ IRRFload, IREXload, IRWBload, 
MDRload, R1Sel, RWSel, RegIn, RFWrite, R1R2Load, 
ALU1, ALU2, ALUop, ALU_PCop, ALUOutWrite, FlagWrite,
cycles
);
	// inputs
	input	reset, clock;
	input	[3:0] /*instrDE,*/ instrRF, instrEX, instrWB;
	input	N, Z;
	
	// outputs
	output	PCwrite, PCSel, MemRead, MemWrite, /*IRDEload,*/ IRRFload, IREXload, IRWBload;
	output	MDRload, R1Sel, RWSel, RegIn, RFWrite, R1R2Load;
	output	[2:0] ALU2, ALUop, ALU_PCop;
	output	ALU1, ALUOutWrite, FlagWrite;
	output	[15:0] cycles;
	
	// internal registers
	reg		PCwrite, PCSel, MemRead, MemWrite, /*IRDEload,*/ IRRFload, IREXload, IRWBload;
	reg		MDRload, R1Sel, RWSel, RegIn, RFWrite, R1R2Load;
	reg		[2:0] ALU2, ALUop, ALU_PCop;
	reg		ALU1, ALUOutWrite, FlagWrite;
	reg 	[15:0] cycles;
	reg 	state; // either running or not
	reg 	[2:0] branch_pending;
	
	// state constants
	parameter run_s = 0, stop_s = 1;
	
	// determines whether to keep the processor running; supports asynchronous reset
	always @(posedge clock or posedge reset)
	begin
		if (reset) begin 
			state = run_s;
			cycles <= 16'b0;
		end
		
		else begin
			case(state)
				run_s:	begin
					if( instrRF != 4'b0001 & instrEX != 4'b0001 & instrWB != 4'b0001 )
						cycles = cycles + 1;
					if( instrWB == 4'b0001 )	state = stop_s; // STOP
					else 						state = run_s;
					
					if(instrEX == 4'b1101 & ~N) branch_pending = 3;
					else if(instrEX == 4'b0101 & Z) branch_pending = 3;
					else if(instrEX == 4'b1001 & ~Z) branch_pending = 3;
					else if (branch_pending != 0) branch_pending = branch_pending -1;
				end
				stop_s:	state = stop_s;
			endcase
		end
	end

	// sets the control sequences based upon the current state and instruction
	always @(/*instrRF or instrEX or instrWB*/*)
	begin
		case (state)
			run_s: begin
				// Fetch stage
				MemRead = 1;
				// IRDEload = 1;
				IRRFload = 1;
				
				
				// DEC/RF stage
				IREXload = 1;
				R1R2Load = 1;
				if (instrRF/*DE*/[2:0] == 3'b111)
					R1Sel = 1;
				else
					R1Sel = 0;
				
				// EX stage
				IRWBload = 1;
				PCwrite = 1;
				
				/*if(instrEX == 4'b1101 & ~N) branch_pending = 3;
				else if(instrEX == 4'b0101 & Z) branch_pending = 3;
				else if(instrEX == 4'b1001 & ~Z) branch_pending = 3;
				else if (branch_pending != 0) branch_pending = branch_pending -1;*/
								
				if (instrEX == 4'b0100) begin		// ADD
					PCSel = 0;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 1;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALU_PCop = 3'b000;
					ALUOutWrite = 1;
					// FlagWrite = 1;
					if (branch_pending == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end	
				else if (instrEX == 4'b0110) begin	// SUB
					PCSel = 0;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 1;
					ALU2 = 3'b000;
					ALUop = 3'b001;
					ALU_PCop = 3'b000;
					ALUOutWrite = 1;
					// FlagWrite = 1;
					if (branch_pending == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX == 4'b1000) begin	// NAND
					PCSel = 0;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 1;
					ALU2 = 3'b000;
					ALUop = 3'b011;
					ALU_PCop = 3'b000;
					ALUOutWrite = 1;
					// FlagWrite = 1;
					if (branch_pending == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX[2:0] == 3'b011) begin	// SHIFT
					PCSel = 0;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 1;
					ALU2 = 3'b100;
					ALUop = 3'b100;
					ALU_PCop = 3'b000;
					ALUOutWrite = 1;
					// FlagWrite = 1;
					if (branch_pending == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX[2:0] == 3'b111) begin	// ORI
					PCSel = 0;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 1;
					ALU2 = 3'b011; // TODO check this
					ALUop = 3'b010;
					ALU_PCop = 3'b000;
					ALUOutWrite = 1;
					// FlagWrite = 1;
					if (branch_pending == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX == 4'b0010) begin	// STORE
					PCSel = 0;
					MemWrite = 1;
					MDRload = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALU_PCop = 3'b000;
					ALUOutWrite = 0;
					FlagWrite = 0;
				end
				else if (instrEX == 4'b0000 & cycles > 2 ) begin	// LOAD
					PCSel = 0;
					MemWrite = 0;
					MDRload = 1;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALU_PCop = 3'b000;
					ALUOutWrite = 0;
					FlagWrite = 0;
				end
				else if (instrEX == 4'b1101) begin	// BPZ
					PCSel = ~N;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 0;
					ALU2 = 3'b010;
					ALUop = 3'b000;
					ALU_PCop = 3'b001;
					ALUOutWrite = 0;
					FlagWrite = 0;
				end
				else if (instrEX == 4'b0101) begin	// BZ
					PCSel = Z;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 0;
					ALU2 = 3'b010;
					ALUop = 3'b000;
					ALU_PCop = 3'b001;
					ALUOutWrite = 0;
					FlagWrite = 0;
				end
				else if (instrEX == 4'b1001) begin	// BNZ
					PCSel = ~Z;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 0;
					ALU2 = 3'b010;
					ALUop = 3'b000;
					ALU_PCop = 3'b001;
					ALUOutWrite = 0;
					FlagWrite = 0;
				end
				else begin							// default
					PCSel = 0;
					MemWrite = 0;
					MDRload = 0;
					ALU1 = 0;
					ALU2 = 3'b000;
					ALUop = 3'b000;
					ALU_PCop = 3'b000;
					ALUOutWrite = 0;
					FlagWrite = 0;
				end
				
				// WB stage
				if ( branch_pending == 1 | branch_pending == 2 ) begin
					RWSel = 0;
					RegIn = 0;
					RFWrite = 0;
					end
				else if (instrWB == 4'b0100 | instrWB == 4'b0110 | instrWB[2:0] == 3'b011 
					| instrWB == 4'b1000) begin			// ADD SUB NAND SHIFT
					RWSel = 0;
					RegIn = 0;
					RFWrite = 1;
					// ALUOutWrite = 0;
				end
				else if (instrWB[2:0] == 3'b111) begin	// ORI
					RWSel = 1;
					RegIn = 0;
					RFWrite = 1;
				end
				else if (instrWB == 4'b0000 
						 & cycles > 3) begin			// LOAD
					RWSel = 0;
					RegIn = 1;
					RFWrite = 1;
				end
				else begin								// default
					RWSel = 0;
					RegIn = 0;
					RFWrite = 0;
				end

			end					
			default: begin
				PCwrite = 0;
				MemRead = 0;
				MemWrite = 0;
				// IRDEload = 0;
				IRRFload = 0;
				IREXload = 0;
				IRWBload = 0;
				R1Sel = 0;
				RWSel = 0;
				MDRload = 0;
				R1R2Load = 0;
				PCSel = 0;
				ALU2 = 3'b000;
				ALUop = 3'b000;
				ALU_PCop = 3'b000;
				ALUOutWrite = 0;
				RFWrite = 0;
				RegIn = 0;
				FlagWrite = 0;
			end
		endcase
	end
	
endmodule

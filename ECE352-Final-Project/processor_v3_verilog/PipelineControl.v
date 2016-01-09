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
reset, clock, instrRF, instrEX, instrWB, N, Z,
RFLoad, EXLoad, WBLoad, PCwrite, WBRegWrite, FlagWrite,
MemRead, MemWrite, RFWrite, PCSel, RFin1Sel, RWSel, R1inSel, R2inSel, WBRegSel,
ALU1Sel, ALU2Sel, ALUPCOp, ALUop, cycles
);
	// inputs
	input	reset, clock;
	input	[7:0] instrRF, instrEX, instrWB;
	input	N, Z;
	
	// outputs
	output	RFLoad, EXLoad, WBLoad, PCwrite, WBRegWrite, FlagWrite;
	output	MemRead, MemWrite, RFWrite;
	output	PCSel, RFin1Sel, RWSel, R1inSel, R2inSel, WBRegSel;
	output	[1:0] ALU1Sel;
	output	[2:0] ALU2Sel, ALUop, ALUPCOp;
	output	[15:0] cycles;

	// internal registers
	reg		RFLoad, EXLoad, WBLoad, PCwrite, WBRegWrite, FlagWrite;
	reg		MemRead, MemWrite, RFWrite;
	reg		PCSel, RFin1Sel, RWSel, R1inSel, R2inSel, WBRegSel;
	reg		[1:0] ALU1Sel;
	reg		[2:0] ALU2Sel, ALUop, ALUPCOp;
	reg 	[15:0] cycles;
	reg 	state; // either running or not
	reg 	[2:0] BRCTR;
	
	// state constants
	parameter run_s = 0, stop_s = 1;
	
	// instr constants
	parameter [3:0] LOAD = 4'b0000;
	parameter [3:0] STORE = 4'b0010;
	parameter [3:0] ADD = 4'b0100;
	parameter [3:0] SUB = 4'b0110;
	parameter [3:0] NAND = 4'b1000;
	parameter [2:0] ORI = 3'b111;
	parameter [2:0] SHIFT = 3'b011;
	parameter [3:0] BZ = 4'b0101;
	parameter [3:0] BNZ = 4'b1001;
	parameter [3:0] BPZ = 4'b1101;
	parameter [3:0] NOP = 4'b1010;
	parameter [3:0] STOP = 4'b0001;
	
	// ALU operation constants
	parameter [2:0] A_ADD = 0;
	parameter [2:0] A_SUB = 1;
	parameter [2:0] A_ORI = 2;
	parameter [2:0] A_NAND = 3;
	parameter [2:0] A_SHIFT = 4;
	parameter [2:0] A_RESET = 5;
	
	// determines whether to keep the processor running; supports asynchronous reset
	always @(posedge clock or posedge reset)
	begin
		if (reset) begin 
			state = run_s;
			cycles <= 16'b0;
			BRCTR <= 0;
		end
		
		else begin
			case(state)
				run_s:	begin
					if( instrRF[3:0] != STOP & instrEX[3:0] != STOP & instrWB[3:0] != STOP )
						cycles = cycles + 1;
					
					if( instrWB[3:0] == STOP )
						state = stop_s;
					else
						state = run_s;
					
					if( instrEX[3:0] == BPZ & ~N ) BRCTR = 3;
					else if( instrEX[3:0] == BZ & Z ) BRCTR = 3;
					else if( instrEX[3:0] == BNZ & ~Z ) BRCTR = 3;
					else if( BRCTR != 0 ) BRCTR = BRCTR -1;
				end
				stop_s:	state = stop_s;
			endcase
		end
	end

	// sets the control sequences based upon the current state and instruction
	always @(*)
	begin
		case (state)
			run_s: begin
				// Fetch stage
				MemRead = 1; 	// always read from memory
				RFLoad = 1;		// always load instruction to RF stage
				
				
				// DEC/RF stage
				//if (BRCTR == 0 | BRCTR == 1 ) EXLoad = 1;
				//else EXLoad = 0;
				EXLoad = 1;
				// TODO try this: RFin1Sel = (instrRF[2:0] == ORI);
				if (instrRF[2:0] == ORI)	RFin1Sel = 1; // select 2'b1
				else 						RFin1Sel = 0; // select IRRF[7:6]
				
				if ( instrRF[2:0] == ORI ) begin
					if ((instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */))
						& BRCTR == 0 ) begin
						if ( 2'b01 == instrWB[7:6] ) begin
							R1inSel = 0; // load from WBRegOut
							R2inSel = 1;
						end else begin
							R1inSel = 1;
							R2inSel = 1;
						end
					end else if ( instrWB[2:0] == ORI & BRCTR == 0 ) begin
						R1inSel = 0; // load from WBRegOut
						R2inSel = 1;
					end else begin 
						R1inSel = 1;
						R2inSel = 1;
					end
				end else begin
					if ( (instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT | 
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */))
						& BRCTR == 0 ) begin
						if ( instrRF[7:6] == instrWB[7:6] & instrRF[5:4] == instrWB[7:6] ) begin
							R1inSel = 0; // load from WBRegOut
							R2inSel = 0; // load from WBRegOut
						end else if ( instrRF[7:6] == instrWB[7:6] ) begin
							R1inSel = 0; // load from WBRegOut
							R2inSel = 1;
						end else if ( instrRF[5:4] == instrWB[7:6] ) begin
							R1inSel = 1;
							R2inSel = 0; // load from WBRegOut
						end else begin
							R1inSel = 1;
							R2inSel = 1;
						end
					end else if ( instrWB[2:0] == ORI & BRCTR == 0 ) begin
						if ( instrRF[7:6] == 2'b01 & instrRF[5:4] == 2'b01 ) begin
							R1inSel = 0; // load from WBRegOut
							R2inSel = 0; // load from WBRegOut
						end else if ( instrRF[7:6] == 2'b01 ) begin
							R1inSel = 0; // load from WBRegOut
							R2inSel = 1;
						end else if ( instrRF[5:4] == 2'b01 ) begin
							R1inSel = 1;
							R2inSel = 0; // load from WBRegOut
						end else begin
							R1inSel = 1;
							R2inSel = 1;
						end
					end else begin 
						R1inSel = 1;
						R2inSel = 1;
					end
				end
				
				// EX stage
				/*if (BRCTR == 0 | BRCTR == 3)*/ WBLoad = 1;
				//else WBLoad = 0;
				PCwrite = 1;	// always update PC
								
				if (instrEX[3:0] == ADD) begin
					PCSel = 0;
					MemWrite = 0;
					if ( (instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */))
						& BRCTR == 0 ) begin
						if ( instrEX[7:6] == instrWB[7:6] & instrEX[5:4] == instrWB[7:6]) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == instrWB[7:6] ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == instrWB[7:6] ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else if ( instrWB[2:0] == ORI & BRCTR == 0 ) begin
						if ( instrEX[7:6] == 2'b01 & instrEX[5:4] == 2'b01) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == 2'b01 ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == 2'b01 ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else begin
						ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
						ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
					end
					ALUop = A_ADD;
					ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 1;
					if (BRCTR == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end	
				else if (instrEX[3:0] == SUB) begin
					PCSel = 0;
					MemWrite = 0;
					if ( (instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */))
						& BRCTR == 0 ) begin
						if ( instrEX[7:6] == instrWB[7:6] & instrEX[5:4] == instrWB[7:6]) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == instrWB[7:6] ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == instrWB[7:6] ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else if ( instrWB[2:0] == ORI & BRCTR == 0 ) begin
						if ( instrEX[7:6] == 2'b01 & instrEX[5:4] == 2'b01) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == 2'b01 ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == 2'b01 ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else begin
						ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
						ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
					end
					ALUop = A_SUB;
					ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 1;
					if (BRCTR == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX[3:0] == NAND) begin
					PCSel = 0;
					MemWrite = 0;
					if ( (instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */))
						& BRCTR == 0 ) begin
						if ( instrEX[7:6] == instrWB[7:6] & instrEX[5:4] == instrWB[7:6]) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == instrWB[7:6] ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == instrWB[7:6] ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else if ( instrWB[2:0] == ORI & BRCTR == 0 ) begin
						if ( instrEX[7:6] == 2'b01 & instrEX[5:4] == 2'b01) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == 2'b01 ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == 2'b01 ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else begin
						ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
						ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
					end
					ALUop = A_NAND;
					ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 1;
					if (BRCTR == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX[2:0] == SHIFT) begin
					PCSel = 0;
					MemWrite = 0;
					if ( instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */)) begin
						if ( instrEX[7:6] == instrWB[7:6] ) ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
						else ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
					end else if ( instrWB[2:0] == ORI ) begin
						if ( instrEX[7:6] == 2'b01 ) ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
						else ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
					end else ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
					ALU2Sel = 3'b100;
					ALUop = A_SHIFT;
					ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 1;
					if (BRCTR == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX[2:0] == ORI) begin	// ORI
					PCSel = 0;
					MemWrite = 0;
					if ( instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */)) begin
						if ( 2'b01 == instrWB[7:6] ) ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
						else ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
					end else if ( instrWB[2:0] == ORI ) ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
					else ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
					ALU2Sel = 3'b011;
					ALUop = A_ORI;
					ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 1;
					if (BRCTR == 0) FlagWrite = 1;
					else FlagWrite = 0;
				end
				else if (instrEX[3:0] == STORE) begin	// STORE
					PCSel = 0;
					MemWrite = 1;
					
					if ( (instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */))
						& BRCTR == 0 ) begin
						if ( instrEX[7:6] == instrWB[7:6] & instrEX[5:4] == instrWB[7:6]) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == instrWB[7:6] ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == instrWB[7:6] ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else if ( instrWB[2:0] == ORI & BRCTR == 0 ) begin
						if ( instrEX[7:6] == 2'b01 & instrEX[5:4] == 2'b01) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else if ( instrEX[7:6] == 2'b01 ) begin
							ALU1Sel = 2'b10; 	// choose WBRegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end else if ( instrEX[5:4] == 2'b01 ) begin
							ALU1Sel = 2'b01; 	// choose R1RegOut as ALU1
							ALU2Sel = 3'b001;	// choose WBRegOut as ALU2
						end else begin
							ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
							ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
						end
					end else begin
						ALU1Sel = 2'b01;	// choose R1RegOut as ALU1
						ALU2Sel = 3'b000;	// choose R2RegOut as ALU2
					end
					
					
					//ALU1Sel = 0;
					//ALU2Sel = 3'b000;
					ALUop = 3'b000;
					ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 0;
					FlagWrite = 0;
				end
				else if (instrEX[3:0] == LOAD & cycles > 2 ) begin	// LOAD
					PCSel = 0;
					MemWrite = 0;
					ALU1Sel = 0;
					if ( instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[3:0] == NAND | instrWB[2:0] == SHIFT |
						(instrWB[3:0] == LOAD & cycles > 3 /* check this number */)) begin
						if ( instrEX[5:4] == instrWB[7:6] ) ALU2Sel = 3'b001;
						else ALU2Sel = 3'b000;
					end else if ( instrWB[2:0] == ORI ) begin
						if ( instrEX[5:4] == 2'b01 ) ALU2Sel = 3'b001;
						else ALU2Sel = 3'b000;
					end else ALU2Sel = 3'b000;
					//ALU2Sel = 3'b000;
					ALUop = 3'b000;
					ALUPCOp = 3'b000;
					WBRegSel = 1;
					WBRegWrite = 1;
					FlagWrite = 0;
				end
				else if (instrEX[3:0] == BPZ) begin	// BPZ
					PCSel = ~N;
					MemWrite = 0;
					ALU1Sel = 0;
					ALU2Sel = 3'b010;
					ALUop = 3'b000;
					if (~N)	ALUPCOp = 3'b001;
					else ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 0;
					FlagWrite = 0;
				end
				else if (instrEX[3:0] == BZ) begin	// BZ
					PCSel = Z;
					MemWrite = 0;
					ALU1Sel = 0;
					ALU2Sel = 3'b010;
					ALUop = 3'b000;
					if (Z)	ALUPCOp = 3'b001;
					else ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 0;
					FlagWrite = 0;
				end
				else if (instrEX[3:0] == BNZ) begin	// BNZ
					PCSel = ~Z;
					MemWrite = 0;
					ALU1Sel = 0;
					ALU2Sel = 3'b010;
					ALUop = 3'b000;
					if (~Z)	ALUPCOp = 3'b001;
					else ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 0;
					FlagWrite = 0;
				end
				else begin							// default
					PCSel = 0;
					MemWrite = 0;
					ALU1Sel = 2'b00;
					ALU2Sel = 3'b000;
					ALUop = 3'b000;
					ALUPCOp = 3'b000;
					WBRegSel = 0;
					WBRegWrite = 0;
					FlagWrite = 0;
				end
				
				// WB stage
				if ( BRCTR == 1 | BRCTR == 2 ) begin
					RWSel = 0;
					RFWrite = 0;
					end
				else if (instrWB[3:0] == ADD | instrWB[3:0] == SUB | 
						instrWB[2:0] == SHIFT | instrWB[3:0] == NAND) begin
					RWSel = 0;
					RFWrite = 1;
				end
				else if (instrWB[2:0] == ORI) begin
					RWSel = 1;
					RFWrite = 1;
				end
				else if (instrWB[3:0] == LOAD & cycles > 3) begin
					RWSel = 0;
					RFWrite = 1;
				end
				else begin
					RWSel = 0;
					RFWrite = 0;
				end

			end					
			default: begin
				PCwrite = 0;
				MemRead = 0;
				MemWrite = 0;
				RFLoad = 0;
				EXLoad = 0;
				WBLoad = 0;
				RFin1Sel = 0;
				RWSel = 0;
				PCSel = 0;
				ALU1Sel = 2'b00;
				ALU2Sel = 3'b000;
				ALUop = 3'b000;
				ALUPCOp = 3'b000;
				WBRegSel = 0;
				WBRegWrite = 0;
				RFWrite = 0;
				FlagWrite = 0;
				R1inSel = 0;
				R2inSel = 0;
			end
		endcase
	end
	
endmodule

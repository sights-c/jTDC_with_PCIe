`default_nettype none
//---------------------------------------------------------------------
//--                                                                 --
//-- Company:  University of Bonn                                    --
//-- Engineer: John Bieling                                          --
//--                                                                 --
//---------------------------------------------------------------------
//--                                                                 --
//-- Copyright (C) 2015 John Bieling                                 --
//--                                                                 --
//-- This program is free software; you can redistribute it and/or   --
//-- modify it under the terms of the GNU General Public License as  --
//-- published by the Free Software Foundation; either version 3 of  --
//-- the License, or (at your option) any later version.             --
//--                                                                 --
//-- This program is distributed in the hope that it will be useful, --
//-- but WITHOUT ANY WARRANTY; without even the implied warranty of  --
//-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the    --
//-- GNU General Public License for more details.                    --
//--                                                                 --
//-- You should have received a copy of the GNU General Public       --
//-- License along with this program; if not, see                    --
//-- <http://www.gnu.org/licenses>.                                  --
//--                                                                 --
//---------------------------------------------------------------------


//-- The module can be configured with these parameters (defaults given in braces):
//--
//-- clip_count(1) : sets if the count signal should be clipped.
//-- clip_reset(1) : sets if the reset signal should be clipped.


module dsp_multioption_counter #(
	parameter clip_count = 1,
	parameter clip_reset = 1
	)(
	input	wire		countClock,
	input	wire		count,
	input	wire		reset,
	output	wire [31:0]	countout
	);
   
	wire [47:0] DSPOUT;
	wire CARRYOUT;
	assign CARRYOUT = DSPOUT[47]; // CARRYOUT signals of DSP48E1 are not valid for two-input accumulator(A:B+C+P)

	wire [1:0] OPMODE_X = 2'b11; // send {D,A,B} to postadder
	wire [1:0] OPMODE_Z = 2'b10; // send P to postadder


	wire final_count;
	wire final_reset;


	//same clip stage as with slimfast_counter
	generate

		if (clip_count == 0) assign final_count = count; else
		if (clip_count == 1)
		begin
			wire clipped_count;
			signal_clipper countclip (	.sig(count),	.CLK(countClock),	.clipped_sig(clipped_count));
			assign final_count = clipped_count;
		end else	begin // I added this, so that one could switch from "clipped" to "not clipped" without changing the number of flip flop stages
			reg piped_count;
			always@(posedge countClock) 
			begin
				piped_count <= count;
			end
			assign final_count = piped_count;
		end

		if (clip_reset == 0) assign final_reset = reset; else
		begin
			wire clipped_reset;
			signal_clipper resetclip (	.sig(reset),	.CLK(countClock),	.clipped_sig(clipped_reset));
			assign final_reset = clipped_reset;
		end

	endgenerate


	
	DSP48E1 #(
		// Feature Control Attributes: Data Path Selection
		.A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
		.B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
		.USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
		.USE_MULT("NONE"),            	  // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
		.USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
		// Pattern Detector Attributes: Pattern Detection Configuration
		.AUTORESET_PATDET("NO_RESET"), // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
		.MASK(48'h3fffffffffff),          // 48-bit mask value for pattern detect (1=ignore)
		.PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
		.SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
		.SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
		.USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
		// Register Control Attributes: Pipeline Register Configuration
		.ACASCREG(0),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
		.ADREG(0),                        // Number of pipeline stages for pre-adder (0 or 1)
		.ALUMODEREG(0),                   // Number of pipeline stages for ALUMODE (0 or 1)
		.AREG(0),                         // Number of pipeline stages for A (0, 1 or 2)
		.BCASCREG(0),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
		.BREG(0),                         // Number of pipeline stages for B (0, 1 or 2)
		.CARRYINREG(0),                   // Number of pipeline stages for CARRYIN (0 or 1)
		.CARRYINSELREG(0),                // Number of pipeline stages for CARRYINSEL (0 or 1)
		.CREG(0),                         // Number of pipeline stages for C (0 or 1)
		.DREG(0),                         // Number of pipeline stages for D (0 or 1)
		.INMODEREG(0),                    // Number of pipeline stages for INMODE (0 or 1)
		.MREG(0),                         // Number of multiplier pipeline stages (0 or 1)
		.OPMODEREG(0),                    // Number of pipeline stages for OPMODE (0 or 1)
		.PREG(1)                          // Number of pipeline stages for P (0 or 1)
	 )
	 DSP48E1_inst (
		// Cascade: 30-bit (each) output: Cascade Ports
		.ACOUT(),                        // 30-bit output: A port cascade output
		.BCOUT(),                   	 // 18-bit output: B port cascade output
		.CARRYCASCOUT(),     			 // 1-bit output: Cascade carry output
		.MULTSIGNOUT(),       			 // 1-bit output: Multiplier sign cascade output
		.PCOUT(),                   	 // 48-bit output: Cascade output
		// Control: 1-bit (each) output: Control Inputs/Status Bits
		.OVERFLOW(),             		 // 1-bit output: Overflow in add/acc output
		.PATTERNBDETECT(), 				 // 1-bit output: Pattern bar detect output
		.PATTERNDETECT(),   			 // 1-bit output: Pattern detect output
		.UNDERFLOW(),           		 // 1-bit output: Underflow in add/acc output
		// Data: 4-bit (each) output: Data Ports
		.CARRYOUT(),    				 // 4-bit output: Carry output
		.P(DSPOUT),                	 	 // 48-bit output: Primary data output
		// Cascade: 30-bit (each) input: Cascade Ports
		.ACIN(),                     	 // 30-bit input: A cascade data input
		.BCIN(),                     	 // 18-bit input: B cascade input
		.CARRYCASCIN(),       			 // 1-bit input: Cascade carry input
		.MULTSIGNIN(),         			 // 1-bit input: Multiplier sign input
		.PCIN(),                     	 // 48-bit input: P cascade input
		// Control: 4-bit (each) input: Control Inputs/Status Bits
		.ALUMODE(4'b0000),               // 4-bit input: ALU control input
		.CARRYINSEL(3'b00),         	 // 3-bit input: Carry select input
		.CLK(countClock),              	 // 1-bit input: Clock input
		.INMODE(),                 		 // 5-bit input: INMODE control input
		.OPMODE({1'b0,OPMODE_Z,2'b00,OPMODE_X}),	// 7-bit input: Operation mode input
		// Data: 30-bit (each) input: Data Ports
		.A(30'b0),                    	 // 30-bit input: A data input
		.B(18'b01_00000000_00000000),    // 18-bit input: B data input
		.C(48'b0),                       // 48-bit input: C data input
		.CARRYIN(1'b0),               	 // 1-bit input: Carry input signal
		.D(25'b0),                       // 25-bit input: D data input
		// Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
		.CEA1(),                     	 // 1-bit input: Clock enable input for 1st stage AREG
		.CEA2(),                     	 // 1-bit input: Clock enable input for 2nd stage AREG
		.CEAD(),                     	 // 1-bit input: Clock enable input for ADREG
		.CEALUMODE(),           		 // 1-bit input: Clock enable input for ALUMODE
		.CEB1(),                     	 // 1-bit input: Clock enable input for 1st stage BREG
		.CEB2(),                     	 // 1-bit input: Clock enable input for 2nd stage BREG
		.CEC(),                       	 // 1-bit input: Clock enable input for CREG
		.CECARRYIN(),           		 // 1-bit input: Clock enable input for CARRYINREG
		.CECTRL(),                 		 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
		.CED(),                       	 // 1-bit input: Clock enable input for DREG
		.CEINMODE(),             		 // 1-bit input: Clock enable input for INMODEREG
		.CEM(),                       	 // 1-bit input: Clock enable input for MREG
		.CEP(final_count),           	 // 1-bit input: Clock enable input for PREG
		.RSTA(),                     	 // 1-bit input: Reset input for AREG
		.RSTALLCARRYIN(),   			 // 1-bit input: Reset input for CARRYINREG
		.RSTALUMODE(),         			 // 1-bit input: Reset input for ALUMODEREG
		.RSTB(),                     	 // 1-bit input: Reset input for BREG
		.RSTC(),                     	 // 1-bit input: Reset input for CREG
		.RSTCTRL(),               		 // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
		.RSTD(),                     	 // 1-bit input: Reset input for DREG and ADREG
		.RSTINMODE(),           		 // 1-bit input: Reset input for INMODEREG
		.RSTM(),                     	 // 1-bit input: Reset input for MREG
		.RSTP(final_reset)            	 // 1-bit input: Reset input for PREG
	);



	//overflow is in phase with DSPOUT (DSPOUT has an internal REG)
	reg overflow;
	always@(posedge countClock) 
	begin

		if (final_reset == 1'b1) overflow <= 0;
		else overflow <= overflow || CARRYOUT;

	end			

	assign countout[30:0] = DSPOUT[46:16];
   	assign countout[31] = overflow;

endmodule
`timescale 1ps/1ps
//----------------------------------------------------------------------------
// "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
// "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
//----------------------------------------------------------------------------
// CLK_OUT1___100.000______0.000______50.0______?____?
// CLK_OUT2___200.000______0.000______50.0______?____?
// CLK_OUT3___400.000______0.000______50.0______?____?
//
//----------------------------------------------------------------------------
// "Input Clock   Freq (MHz)    Input Jitter (UI)"
//----------------------------------------------------------------------------
// __primary_________200.000___________0.001
//----------------------------------------------------------------------------

module pll_vfb6_400 ( CLK_IN_P,
                      CLK_IN_N,
                      CLK1,
                      CLK2,
                      CLK4 );

	input wire CLK_IN_P;
  input wire CLK_IN_N;
	output wire CLK1;
	output wire CLK2;
	output wire CLK4;
	
	wire clkin1;
	wire clkout0;
	wire clkout1;
	wire clkout2;
	
	
  // input buffering
  //------------------------------------
  IBUFDS sys_clk_ibufgds
    (
    .O (clkin1),
    .I (CLK_IN_P),
    .IB (CLK_IN_N)
    );

  wire        locked;
  wire        clkfbout;
  wire        clkfbout_buf;

// PLLE2_BASE  : In order to incorporate this function into the design,
//   Verilog   : the following instance declaration needs to be placed
//  instance   : in the body of the design code.  The instance name
// declaration : (PLLE2_BASE_inst) and/or the port declarations within the
//    code     : parenthesis may be changed to properly reference and
//             : connect this function to the design.  All inputs
//             : and outputs must be connected.
// 
// PLLE2 is a mixed signal block designed to support frequency synthesis, clock network deskew,
//   and jitter reduction. The clock outputs can each have an individual divide (1 to 128), phase shift,
//   and duty cycle based on the same VCO frequency. Output clocks are phase aligned to each
//   other (unless phase shifted) and aligned to the input clock with a proper feedback configuration.
//   PLLE2 complements the MMCM element by supporting higher speed clocking while MMCM
//   has more features to handle most general clocking needs. PLLE2_BASE is intended for most
//   uses of this PLL component while PLLE2_ADV is intended for use when clock switch-over or
//   dynamic reconfiguration is required.

// PLLE2_BASE: Base Phase Locked Loop (PLL)
//             Artix-7
// Xilinx HDL Language Template, version 2023.1

PLLE2_BASE #(
  .BANDWIDTH("HIGH"),  // OPTIMIZED, HIGH, LOW
  .CLKFBOUT_MULT(4),        // Multiply value for all CLKOUT, (2-64)
  .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
  .CLKIN1_PERIOD(5.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

  // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
  .CLKOUT0_DIVIDE(8),
  .CLKOUT1_DIVIDE(4),
  .CLKOUT2_DIVIDE(2),

  // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
  .CLKOUT0_DUTY_CYCLE(0.5),
  .CLKOUT1_DUTY_CYCLE(0.5),
  .CLKOUT2_DUTY_CYCLE(0.5),

  // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
  .CLKOUT0_PHASE(0.0),
  .CLKOUT1_PHASE(0.0),
  .CLKOUT2_PHASE(0.0),

  .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
  .REF_JITTER1(0.001),        // Reference input jitter in UI, (0.000-0.999).
  .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
)
PLLE2_BASE_inst (
  // Clock Outputs: 1-bit (each) output: User configurable clock outputs
  .CLKOUT0(clkout0),   // 1-bit output: CLKOUT0
  .CLKOUT1(clkout1),   // 1-bit output: CLKOUT1
  .CLKOUT2(clkout2),   // 1-bit output: CLKOUT2

  // Feedback Clocks: 1-bit (each) output: Clock feedback ports
  .CLKFBOUT(clkfbout), // 1-bit output: Feedback clock
  .LOCKED(locked),     // 1-bit output: LOCK
  .CLKIN1(clkin1),     // 1-bit input: Input clock

  // Control Ports: 1-bit (each) input: PLL control ports
  // .PWRDWN(),     // 1-bit input: Power-down
  // .RST(),           // 1-bit input: Reset

  // Feedback Clocks: 1-bit (each) input: Clock feedback ports
  .CLKFBIN(clkfbout_buf)    // 1-bit input: Feedback clock
);

// End of PLLE2_BASE_inst instantiation


// output buffering
//-----------------------------------
BUFG clkf_buf (
  .O (clkfbout_buf),
  .I (clkfbout));

BUFG CLKOUT1_buf (
  .O   (CLK1),
  .I   (clkout0));


BUFG CLKOUT2_buf (
  .O   (CLK2),
  .I   (clkout1));

BUFG clkout3_buf (
  .O   (CLK4),
  .I   (clkout2));

endmodule
`timescale 1ps/1ps
//----------------------------------------------------------------------------
// "Output    Output      Phase     Duty      Pk-to-Pk        Phase"
// "Clock    Freq (MHz) (degrees) Cycle (%) Jitter (ps)  Error (ps)"
//----------------------------------------------------------------------------
// CLK_OUT1___200.000______0.000______50.0______183.967____177.296
// CLK_OUT2___400.000______0.000______50.0______161.043____177.296
//
//----------------------------------------------------------------------------
// "Input Clock   Freq (MHz)    Input Jitter (UI)"
//----------------------------------------------------------------------------
// __primary_________200.000___________0.0005
//----------------------------------------------------------------------------

module pll_ax7203_400 ( 
    input   wire CLKIN,
    output  wire CLK200,
    output  wire CLK400
);

wire locked;
wire clkfbout;
wire clkfbout_buf;
wire clkout0;
wire clkout1;

PLLE2_BASE #(
    .BANDWIDTH("HIGH"),  // OPTIMIZED, HIGH, LOW
    .CLKFBOUT_MULT(4),        // Multiply value for all CLKOUT, (2-64)
    .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
    .CLKIN1_PERIOD(5.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).

    // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
    .CLKOUT0_DIVIDE(4),
    .CLKOUT1_DIVIDE(2),

    // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
    .CLKOUT0_DUTY_CYCLE(0.5),
    .CLKOUT1_DUTY_CYCLE(0.5),

    // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
    .CLKOUT0_PHASE(0.0),
    .CLKOUT1_PHASE(0.0),

    .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
    .REF_JITTER1(0.001),        // Reference input jitter in UI, (0.000-0.999).
    .STARTUP_WAIT("FALSE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
) PLLE2_BASE_inst (
    // Clock Outputs: 1-bit (each) output: User configurable clock outputs
    .CLKOUT0(clkout0),   // 1-bit output: CLKOUT0
    .CLKOUT1(clkout1),   // 1-bit output: CLKOUT1

    // Feedback Clocks: 1-bit (each) output: Clock feedback ports
    .CLKFBOUT(clkfbout), // 1-bit output: Feedback clock
    .LOCKED(locked),     // 1-bit output: LOCK
    .CLKIN1(CLKIN),     // 1-bit input: Input clock

    // Control Ports: 1-bit (each) input: PLL control ports
    // .PWRDWN(),     // 1-bit input: Power-down
    // .RST(),           // 1-bit input: Reset

    // Feedback Clocks: 1-bit (each) input: Clock feedback ports
    .CLKFBIN(clkfbout_buf)    // 1-bit input: Feedback clock
);


// ---------- output buffer ----------------------------------------
BUFG clkf_buf (
.O (clkfbout_buf),
.I (clkfbout));

BUFG CLKOUT0_buf (
.O (CLK200),
.I (clkout0));

BUFG CLKOUT1_buf (
.O (CLK400),
.I (clkout1));

endmodule

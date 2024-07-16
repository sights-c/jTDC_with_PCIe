module signal_clipper (
    input   logic   sig,
    input   logic   CLK,
    output  logic   clipped_sig
);
    logic   q1  =   '0;
    logic   q2  =   '0;

    always_ff @( posedge CLK ) begin
        q1  <=  sig;
        q2  <=  q1;
        clipped_sig <= q1 & (~q2);
    end
endmodule
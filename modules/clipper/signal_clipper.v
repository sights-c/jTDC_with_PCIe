module signal_clipper (
    input   wire   sig,
    input   wire   CLK,
    output  reg    clipped_sig
);
    reg   q1  =   1'b0;
    reg   q2  =   1'b0;

    always @( posedge CLK ) begin
        q1  <=  sig;
        q2  <=  q1;
        clipped_sig <= q1 & (~q2);
    end
endmodule
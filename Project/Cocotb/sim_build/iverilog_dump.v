module iverilog_dump();
initial begin
    $dumpfile("viterbi_top.fst");
    $dumpvars(0, viterbi_top);
end
endmodule

`timescale 1ns/1ps

module tb_top;
    // --- Supply & Threshold Parameters ---
    localparam real VDD = 0.8;

    // --- Signals ---
    logic clk = 0;
    logic rst_n;
    wire  done;           // High when offset search finishes
    wire  prbs_err;       // High if data mismatch occurs
    wire  setup_viol;     // High if setup < 300ps
    wire  hold_viol;      // High if hold < 5ps
    
    // Analog/Real Wires for AMS Interconnect
    wire real stim_p, stim_n;   // From Search Engine
    wire real prbs_stream;      // From PRBS Gen
    wire real out_p, out_n;     // From DUT
    wire real ck_rise_ns;       // 20/80 measurement

    // 1. Clock Generation (500MHz)
    always #1000ps clk = ~clk;

    // 2. [vams] PRBS7 Generator
    // Based on tutorial_prbs7; enabled only after DC search is done
    prbs7_gen i_gen (
        .clk(clk),
        .en(done),        
        .out(prbs_stream)
    );

    // 3. [va] Offset Search & Timing Characterizer (The "Smart" Monitor)
    // This is the module that calculates the 20/80 rise and checks violations
    comp_characterizer i_monitor (
        .ck(clk), ._ck(!clk),
        .op(out_p), .on(out_n),
        .p(stim_p), .n(stim_n),
        .done(done),
        .ck_rise_ns(ck_rise_ns),
        .setup_err(setup_viol),
        .hold_err(hold_viol)
    );

    // 4. [vams] PRBS7 Checker
    // Self-syncing checker monitoring the DUT output
    prbs7_check8b i_check (
        .clk(clk),
        .in(out_p),
        .en(done),
        .err(prbs_err)
    );

    // 5. [va] Behavioral DUT (The Comparator)
    // Acts as your hardware until you have the schematic
    comparator_08v i_dut (
        .clk(clk), .clk_n(!clk),
        .inp(stim_p + prbs_stream), // Inject data on top of DC offset
        .inn(stim_n),
        .outp(out_p), .outn(out_n)
    );

    // --- Testbench Control Logic ---
    initial begin
        rst_n = 0; #5ns; rst_n = 1;
        
        $display("--------------------------------------------------");
        $display("TIME: %t | PHASE 1: Starting Comparator Offset Search", $realtime);
        
        // Wait for Analog Search to converge
        wait(done == 1'b1);
        
        $display("TIME: %t | PHASE 2: Offset Found! Starting PRBS Test", $realtime);
        $display("MEASURED CLOCK RISE (20/80): %f ns", ck_rise_ns);
        
        // Run for a window to check for stability and timing
        #500ns;
        
        $display("--------------------------------------------------");
        if (prbs_err)   $display("RESULT: FAILED - PRBS Bit Errors Detected!");
        if (setup_viol) $display("RESULT: FAILED - Setup Violation (<300ps) Detected!");
        if (hold_viol)  $display("RESULT: FAILED - Hold Violation (<5ps) Detected!");
        
        if (!prbs_err && !setup_viol && !hold_viol)
            $display("RESULT: ALL TESTS PASSED (Offset, Timing, and Data)");
        $display("--------------------------------------------------");
        
        $finish;
    end
endmodule

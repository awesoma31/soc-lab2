`timescale 1ns / 1ps

module monitor #(
    parameter integer N          = 10,
    parameter integer C_BITS     = 20,
    parameter real    CLK_PERIOD = 10.0,
    parameter integer IDLE_LIMIT = 1_000_000
) (
    input            clk,
    input            rst,
    input            data_in,
    input            strb_in,
    input            ack_out,
    input            data_out,
    input            strb_out,
    input     [31:0] seed,
    output reg       ack_in = 1'b0
);

    localparam integer N_IN  = 2 * N * N;
    localparam integer N_OUT = N * N;

    localparam integer V_SUMMARY = 0;
    localparam integer V_REPORT  = 1;
    localparam integer V_TRANS   = 2;
    localparam integer V_BITS    = 3;

    localparam integer LOW_MIN = 25,  LOW_MAX = 70;
    localparam integer HI_MIN  = 150, HI_MAX  = 200;

    integer num_tests = 2;
    integer verbose   = V_REPORT;
    integer fd_full   = 0;
    integer fd_sum    = 0;

    reg [7:0]  A     [0:N-1][0:N-1];
    reg [7:0]  B     [0:N-1][0:N-1];
    reg [31:0] C_dut [0:N-1][0:N-1];
    reg [31:0] C_ref [0:N-1][0:N-1];

    integer  test      = 1;
    integer  n_in      = 0,  in_bit  = 0;
    integer  n_out     = 0,  out_bit = 0;
    reg [7:0]  in_byte  = 0;
    reg [31:0] out_word = 0;
    bit      started   = 0;
    bit      test_end  = 0;
    integer  in_low = 0, in_high = 0;
    integer  in_min = 255, in_max = 0;
    integer  proto_errors = 0;
    realtime t_in_first  = 0, t_in_last  = 0;
    realtime t_out_first = 0, t_out_last = 0;

    integer  passed = 0, failed = 0;
    integer  tot_low = 0, tot_high = 0;
    integer  tot_min = 255, tot_max = 0;
    integer  calc_min = 0, calc_max = 0;
    real     calc_sum = 0;
    integer  idle = 0;

    reg ack_out_d = 1'b0, strb_out_d = 1'b0, data_out_d = 1'b0;

    task automatic log(input integer level, input string s);
        if (level <= verbose) $display("%s", s);
        if (fd_full && level <= ((verbose > V_REPORT) ? verbose : V_REPORT))
                                          $fdisplay(fd_full, "%s", s);
        if (fd_sum && level == V_SUMMARY) $fdisplay(fd_sum,  "%s", s);
    endtask

    task automatic dut_error(input string s);
        proto_errors++;
        log(V_SUMMARY, $sformatf("[%0t ns] TEST %0d DUT PROTOCOL ERROR: %s", $time, test, s));
    endtask

    initial begin
        $timeformat(-9, 0, "", 0);
        if (!$value$plusargs("tests=%d", num_tests))   num_tests = 2;
        if (!$value$plusargs("verbose=%d", verbose))   verbose   = V_REPORT;
        if (num_tests < 1) num_tests = 1;
        @(negedge rst);
        fd_full = $fopen($sformatf("monitor_%0d_full.txt", seed), "w");
        fd_sum  = $fopen($sformatf("monitor_%0d_summary.txt", seed), "w");
        log(V_SUMMARY, $sformatf("lab2 variant 3 monitor: seed = %0d, tests = %0d, verbose = %0d",
                                 seed, num_tests, verbose));
    end

    always @(posedge clk) begin
        ack_out_d  <= ack_out;
        strb_out_d <= strb_out;
        data_out_d <= data_out;

        if (rst) begin
            ack_in <= 1'b0;
        end else begin
            idle++;

            if (!started && strb_in) begin
                started    = 1;
                t_in_first = $realtime;
                log(V_TRANS, $sformatf("[%0t ns] ---- TEST %0d/%0d start ----", $time, test, num_tests));
            end

            if (ack_out && !ack_out_d) begin
                idle = 0;
                if (!strb_in)
                    dut_error("ack_out rose while strb_in = 0");
                in_byte[in_bit] = data_in;
                log(V_BITS, $sformatf("[%0t ns] IN  bit %0d = %0d", $time, in_bit, data_in));
                in_bit++;
                t_in_last = $realtime;
                if (in_bit == 8) begin
                    in_bit = 0;
                    if (n_in < N_IN) begin
                        if (n_in < N * N) A[n_in / N][n_in % N] = in_byte;
                        else              B[(n_in - N * N) / N][(n_in - N * N) % N] = in_byte;
                        if (in_byte < in_min) in_min = in_byte;
                        if (in_byte > in_max) in_max = in_byte;
                        if (in_byte >= LOW_MIN && in_byte <= LOW_MAX) in_low++;
                        if (in_byte >= HI_MIN  && in_byte <= HI_MAX)  in_high++;
                        log(V_TRANS, $sformatf("[%0t ns] IN  #%0d %s[%0d][%0d] = %0d", $time, n_in,
                                               (n_in < N * N) ? "A" : "B",
                                               (n_in % (N * N)) / N, n_in % N, in_byte));
                    end else
                        dut_error($sformatf("extra input byte %0d accepted", in_byte));
                    n_in++;
                end
            end

            if (strb_out && strb_out_d && data_out !== data_out_d)
                dut_error("data_out changed while strb_out = 1");

            if (strb_out && !strb_out_d && ack_in)
                dut_error("strb_out rose before ack_in went low");

            if (strb_out && !ack_in) begin
                idle = 0;
                if (n_out == 0 && out_bit == 0) t_out_first = $realtime;
                out_word[out_bit] = data_out;
                log(V_BITS, $sformatf("[%0t ns] OUT bit %0d = %0d", $time, out_bit, data_out));
                out_bit++;
                if (out_bit == C_BITS) begin
                    out_bit = 0;
                    if (n_out < N_OUT) begin
                        C_dut[n_out / N][n_out % N] = out_word & ((32'd1 << C_BITS) - 1);
                        log(V_TRANS, $sformatf("[%0t ns] OUT #%0d C[%0d][%0d] = %0d", $time, n_out,
                                               n_out / N, n_out % N, C_dut[n_out / N][n_out % N]));
                    end else
                        dut_error($sformatf("extra output word %0d", out_word));
                    out_word = 0;
                    n_out++;
                end
                ack_in <= 1'b1;
            end else if (!strb_out && ack_in) begin
                ack_in <= 1'b0;
                t_out_last = $realtime;
                if (n_out == N_OUT && out_bit == 0)
                    test_end = 1;
            end

            if (test_end) begin
                test_end = 0;
                test_report();
                if (test == num_tests) begin
                    run_summary();
                    $finish;
                end
                test++;
                next_test();
            end

            if (idle > IDLE_LIMIT) begin
                log(V_SUMMARY, $sformatf("[%0t ns] TIMEOUT in test %0d: no activity for %0d cycles",
                                         $time, test, IDLE_LIMIT));
                test_report();
                run_summary();
                $finish;
            end
        end
    end

    task automatic next_test();
        n_in = 0;  in_bit = 0;  n_out = 0;  out_bit = 0;  out_word = 0;  started = 0;
        in_low = 0;  in_high = 0;  proto_errors = 0;
        in_min = 255;  in_max = 0;
        t_in_first = 0;  t_in_last = 0;
        t_out_first = 0;  t_out_last = 0;
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                A[i][j] = 'x;  B[i][j] = 'x;  C_dut[i][j] = 'x;
            end
    endtask

    task automatic print_matrix8(input string name, input bit is_a);
        string line;
        log(V_REPORT, $sformatf("%s =", name));
        for (int i = 0; i < N; i++) begin
            line = "  ";
            for (int j = 0; j < N; j++)
                line = {line, $sformatf("%4d", is_a ? A[i][j] : B[i][j])};
            log(V_REPORT, line);
        end
    endtask

    task automatic print_c_dut();
        string line;
        log(V_REPORT, "C =");
        for (int i = 0; i < N; i++) begin
            line = "  ";
            for (int j = 0; j < N; j++)
                line = {line, $sformatf("%8d%s", C_dut[i][j], (C_dut[i][j] !== C_ref[i][j]) ? "*" : " ")};
            log(V_REPORT, line);
        end
    endtask

    function automatic integer cycles(input realtime t);
        return $rtoi(t / CLK_PERIOD);
    endfunction

    task automatic test_report();
        integer errors, mism, calc;
        realtime t_calc, t_total;

        errors = proto_errors;
        mism   = 0;
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                C_ref[i][j] = B[i][j];
                for (int k = 0; k < N; k++)
                    C_ref[i][j] += A[i][k] * A[k][j];
            end

        t_calc  = t_out_first - t_in_last;
        t_total = t_out_last - t_in_first;
        calc    = cycles(t_calc);

        log(V_REPORT, "");
        log(V_REPORT, $sformatf("==================== TEST %0d/%0d REPORT ====================",
                                test, num_tests));
        log(V_REPORT, "--- Input signals (DUT data_in) ---");
        print_matrix8("A", 1);
        print_matrix8("B", 0);
        log(V_REPORT, $sformatf("Input values: [%0d:%0d] = %0d, [%0d:%0d] = %0d, min %0d, max %0d",
                                LOW_MIN, LOW_MAX, in_low, HI_MIN, HI_MAX, in_high, in_min, in_max));
        log(V_REPORT, "");
        log(V_REPORT, "--- Output signals (DUT data_out), * = differs from reference A*A + B ---");
        print_c_dut();
        log(V_REPORT, "");
        log(V_REPORT, "--- Comparison ---");

        if (n_in != N_IN || n_out != N_OUT || in_bit != 0 || out_bit != 0) begin
            errors++;
            log(V_SUMMARY, $sformatf("TEST %0d DUT ERROR: incomplete transfer (in %0d/%0d bytes + %0d bits, out %0d/%0d elements + %0d bits)",
                                     test, n_in, N_IN, in_bit, n_out, N_OUT, out_bit));
        end
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                if (C_dut[i][j] !== C_ref[i][j]) begin
                    mism++;
                    log(V_SUMMARY, $sformatf("TEST %0d MISMATCH C[%0d][%0d]: DUT = %0d, expected = %0d",
                                             test, i, j, C_dut[i][j], C_ref[i][j]));
                end
        errors += mism;
        if (mism == 0)
            log(V_REPORT, $sformatf("All %0d elements match the reference", N * N));

        log(V_REPORT, "");
        log(V_REPORT, "--- Timing (cycles of 100 MHz) ---");
        log(V_REPORT, $sformatf("Algorithm: %0d (%0.2f ms), last input bit -> first output bit", calc, t_calc / 1.0e6));
        log(V_REPORT, $sformatf("Transfer : input %0d, output %0d, whole test %0d (%0.2f ms)",
                                cycles(t_in_last - t_in_first), cycles(t_out_last - t_out_first),
                                cycles(t_total), t_total / 1.0e6));
        log(V_REPORT, "");

        log(V_SUMMARY, $sformatf("TEST %0d/%0d: %s%s  algorithm %0d cycles, whole test %0d cycles",
                                 test, num_tests, (errors == 0) ? "PASS" : "FAIL",
                                 errors ? $sformatf(" (%0d DUT errors)", errors) : "",
                                 calc, cycles(t_total)));
        log(V_REPORT, "==========================================================");

        if (errors == 0) passed++; else failed++;
        tot_low += in_low;  tot_high += in_high;
        if (in_min < tot_min) tot_min = in_min;
        if (in_max > tot_max) tot_max = in_max;
        if (passed + failed == 1 || calc < calc_min) calc_min = calc;
        if (passed + failed == 1 || calc > calc_max) calc_max = calc;
        calc_sum += calc;
    endtask

    task automatic run_summary();
        integer runs;
        runs = passed + failed;
        log(V_SUMMARY, "");
        log(V_SUMMARY, "======================== RUN SUMMARY ========================");
        log(V_SUMMARY, $sformatf("Seed %0d: %0d of %0d tests run, %0d passed, %0d failed",
                                 seed, runs, num_tests, passed, failed));
        log(V_SUMMARY, $sformatf("Input values: [%0d:%0d] = %0d, [%0d:%0d] = %0d, min %0d, max %0d",
                                 LOW_MIN, LOW_MAX, tot_low, HI_MIN, HI_MAX, tot_high, tot_min, tot_max));
        if (runs > 0)
            log(V_SUMMARY, $sformatf("Algorithm: min %0d, avg %0.0f, max %0d cycles",
                                     calc_min, calc_sum / runs, calc_max));
        log(V_SUMMARY, $sformatf("RESULT: %s",
                                 (failed == 0 && runs == num_tests) ? "PASS" : "FAIL"));
        log(V_SUMMARY, "=============================================================");
        if (fd_full) $fclose(fd_full);
        if (fd_sum)  $fclose(fd_sum);
        fd_full = 0;  fd_sum = 0;
    endtask

endmodule

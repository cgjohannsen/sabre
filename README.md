# About

The Stream Analyzer via Bitwise Reasoning (SABRe) is a runtime monitor for Mission-time Linear
Temporal Logic. It uses a modified version of the Configuration Compiler for Property Organization
(C2PO) to generate C code from an MLTL formula. The generated C code then takes as input a stream of
data and outputs whether the MLTL formula is satisfied at each point of the input stream.

To cite, please use our [2025 FMCAD
Paper](https://doi.org/10.34727/2025/isbn.978-3-85448-084-6_9).
See [CITATION.bib](CITATION.bib).

## Example

First, generate the SABRe monitor using the provided `compile.sh` script:

    $ sh compile.sh example/spec.mltl monitor

Then execute the monitor over the example trace:
    
    $ ./monitor < example/trace.csv

The output is in raw bytes where each bit denotes whether the formula was true at that bit's index
of the trace:

    ff
    c0

Interpreting these as raw bytes this is the same as:

    1111 1111 [ff]
    1100 0000 [c0]

Which means that the formula was true from times 0 through 7 (first line) and again from 8 through 9
and false from 10 to 15 (second line).

## Options

The `compile.sh` script has a number of options, including setting the underlying word size and
manually overriding the number of signals in the input trace. Run with `-h`/`--help` for the full
set of options.

## Specification Format

The input format is the same as for C2PO. SABRe target single-formula specifications in either
[C2PO's default input](https://r2u2.github.io/r2u2/_collections/c2po_docs/user/language.html) or the
simpler [MLTL Standard
format](https://r2u2.github.io/r2u2/_collections/c2po_docs/user/mltl_std.html). Only Boolean signals are allowed in SABRe.
 
## Trace Formats

SABRe accepts two trace formats as input: an ASCII CSV file format and raw bytes input.

### CSV Format

By default, SABRe accepts a CSV file with each line describing the value of each proposition at a
given timestep. The following is a trace of length 3 with 2 propositions (`a0` and `a1`) where `a0`
holds at times 0 and 1 but not at time 2, and `a1` holds only at time 1:

    1,0
    1,1
    0,0

### Raw Bytes Format

SABRe also accepts a "raw bytes" input format for higher performance where trace is a stream of
bytes, with each signal providing one word at a time. For example, if there are 3 signals and the
word size is 8, the trace could be a stream of words like:

    0xC6 0x3C 0x0F

The first byte `0xC6` describes the first 8 values of `a0`, `0x3C` for `a1`, and `0x0F` for `a2`.
More completely, the value of each proposition across time for this trace is:

    T=0: a0 = 1, a1 = 0, a2 = 0
    T=1: a0 = 1, a1 = 0, a2 = 0
    T=2: a0 = 0, a1 = 1, a2 = 0
    T=3: a0 = 0, a1 = 1, a2 = 0
    T=4: a0 = 1, a1 = 1, a2 = 1
    T=5: a0 = 1, a1 = 1, a2 = 1
    T=6: a0 = 0, a1 = 1, a2 = 1
    T=7: a0 = 0, a1 = 1, a2 = 1
    
So the trace is a stream of bytes, with each signal providing one word at a time. We offer the
utility program `csv2raw.c` for converting from the CSV format to this raw bytes format.

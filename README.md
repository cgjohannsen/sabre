# About

The Stream Analyzer via Bitwise Reasoning (SABRe) is a runtime monitor for Mission-time Linear
Temporal Logic. It uses a modified version of the Configuration Compiler for Property Organization
(C2PO) to generate C code from an MLTL formula. The generated C code then takes as input a stream of
data and outputs whether MLTL formula is satisfied at each point of the input stream.

## Example

First, generate the SABRe monitor using the provided `compile.sh` script:

    $ bash compile.sh example/spec.mltl sabre

Then execute the monitor over the example trace:
    
    $ ./sabre < example/trace.csv

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

## Input Format

The input format for the monitor generator is a simple format for the description of sets of MLTL
formulas. The file must contain a single MLTL formula terminated by a newline. The standard uses
atomic propositions of the form `a<NUMBER>` (for example, `a0`, `a1`, `a32`, etc.) and infix
operators to describe MLTL formulas. For example:

    G[0,5] a0 & (a1 U[5,10] a4)

SABRe takes as input a vector of signals at each execution step. The number in each atomic
proposition symbol defines which index to read from that input vector to SABRe, e.g., the symbol
`a3` represents the value at index 3 of the input. 

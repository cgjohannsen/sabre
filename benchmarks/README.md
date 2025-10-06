# Benchmarking

The `run.py` script can run a series of benchmarks, comparing SABRe to R2U2 C/Rust and Hydra. Run
`python3 run.py --help` for all possible benchmarks to run.

To analyze the results, run the `analyze.sh` script. This will produce information on average
runtimes and plots for both the future and pattern benchmarks.

The results from the FMCAD 2025 paper are located in `paper-results` -- the corresponding data can
be analyzed with `analyze_paper.sh`.
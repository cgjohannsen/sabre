import random
import os
import argparse
import struct

def r2u2_trace(trace: list[list[bool]]) -> str: 
    rows = [
        ",".join(["1" if tr[i] else "0" for tr in trace])
        for i in range(len(trace[0]))
    ]
    return "\n".join(rows)


def hydra_trace(trace: list[list[bool]]) -> str: 
    rows = [
        f"@{i} {' '.join([f'a{j}' for j in range(len(trace)) if trace[j][i]])}"
        for i in range(len(trace[0]))
    ]
    return "\n".join(rows)

def raw_sabre_trace(trace: list[list[bool]], word_size: int) -> bytes:
    """
    In raw bytes mode, the trace is a stream of bytes, with each signal providing one word at a time. 
    For example, if there are 3 signals and the word size is 8, the trace would be a stream of words like:
        0xC6 0x3C 0x0F
        11001100 00111100 (in binary)
    This would be interpreted as:
        T=0: a0 = 1, a1 = 0, a2 = 0
        T=1: a0 = 1, a1 = 0, a2 = 0
        T=2: a0 = 0, a1 = 1, a2 = 0
        T=3: a0 = 0, a1 = 1, a2 = 0
        T=4: a0 = 1, a1 = 1, a2 = 1
        T=5: a0 = 1, a1 = 1, a2 = 1
        T=6: a0 = 0, a1 = 1, a2 = 1
        T=7: a0 = 0, a1 = 1, a2 = 1
    
    So the trace is a stream of bytes, with each signal providing one word at a time.

    For every signal, we take every 8 values and convert them to a single byte, then concatenate them.
    """
    output = b""
    for i in range(0, len(trace[0]), word_size): # i is index of trace
        for j in range(len(trace)): # j is index of signal
            val = 0
            for k in range(word_size):
                if i+k >= len(trace[j]):
                    break
                val |= (trace[j][i+k] << (word_size - 1 - k))
            if word_size == 64:
                output += struct.pack("@Q", val)
            elif word_size == 32:
                output += struct.pack("@L", val)
            elif word_size == 16:
                output += struct.pack("@H", val)
            elif word_size == 8:
                output += struct.pack("@B", val)
            else:
                raise ValueError(f"Invalid word size: {word_size}")
    return output

parser = argparse.ArgumentParser()
parser.add_argument("len", type=int, help="length of generated trace")
parser.add_argument("nsigs", type=int, help="number of signals for eah timestamp")
parser.add_argument("density", type=float, help="relative proportion of trues to falses for each signal")
parser.add_argument("word_size", type=int, help="word size for sabre")
parser.add_argument("output", help="directory to output traces")
args = parser.parse_args()

trace_len: int = args.len
num_sigs: int = args.nsigs
density: float = args.density 
dir: str = args.output
trace = [random.choices([True, False], weights=[density,1], k=trace_len) for _ in range(num_sigs)]
word_size: int = args.word_size

r2u2_tr = r2u2_trace(trace)
hydra_tr = hydra_trace(trace)
raw_sabre_tr = raw_sabre_trace(trace, word_size)

try:
    os.mkdir(dir)
except FileExistsError:
    pass

with open(f"{dir}/r2u2.csv", "w") as f:
    f.write(r2u2_tr)
with open(f"{dir}/hydra.log", "w") as f:
    f.write(hydra_tr)
with open(f"{dir}/raw_sabre.txt", "wb") as f:
    f.write(raw_sabre_tr)

#!/bin/bash

# C2PO Wrapper Script
# Usage: ./compile.sh <spec_file> <output_executable> [--nsigs <num_signals>] [--word-size <bits>] [--decompose] [--raw-bytes] [--cc <compiler>] [--keep-c] [-h|--help]

set -e

# Function to display usage
usage() {
    echo "Usage: $0 <spec_file> <output_executable> [--nsigs <num_signals>] [--word-size <bits>] [--decompose] [--raw-bytes] [--cc <compiler>] [--keep-c]"
    echo ""
    echo "Arguments:"
    echo "  spec_file        Specification file (either .c2po or .mltl)"
    echo "  output_executable Output executable binary file"
    echo ""
    echo "Optional flags:"
    echo "  -h, --help       Show this help message and exit"
    echo "  --nsigs <n>      Manually-specified number of signals (optional) (default: inferred from spec)"
    echo "  --word-size <b>  Word size (8, 16, 32, or 64) (optional) (default: 8)"
    echo "  --decompose      Decompose temporal operators into power-of-two-sized intervals"
    echo "  --raw-bytes      Enable sabre raw bytes input mode"
    echo "  --cc <compiler>  C compiler to use (default: gcc)"
    echo "  --keep-c         Keep the temporary C file (named as output with .c extension)"
    echo ""
    echo "Examples:"
    echo "  $0 spec.mltl monitor"
    echo "  $0 spec.mltl monitor --nsigs 10"
    echo "  $0 spec.mltl monitor --nsigs 10 --word-size 32"
    echo "  $0 spec.c2po monitor --nsigs 5 --word-size 16 --decompose"
    echo "  $0 spec.mltl monitor --nsigs 8 --word-size 64 --decompose --raw-bytes"
    echo "  $0 spec.mltl monitor --cc clang"
    echo "  $0 spec.mltl monitor --keep-c"
    exit 1
}

# Check for help flags first
if [ $# -eq 1 ] && [[ "$1" =~ ^(-h|--help)$ ]]; then
    usage
fi

# Check minimum number of arguments
if [ $# -lt 2 ]; then
    echo "Error: Missing required arguments"
    echo ""
    usage
fi

# Parse arguments
SPEC_FILE="$1"
OUTPUT_EXECUTABLE="$2"
NUM_SIGNALS=""
WORD_SIZE=""
DECOMPOSE=false
RAW_BYTES=false
KEEP_C=false
CC="gcc"

# Shift to get remaining arguments
shift 2

# Parse positional arguments and flags
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        --nsigs)
            if [ $# -lt 2 ]; then
                echo "Error: --nsigs requires a numeric argument"
                echo ""
                usage
            fi
            NUM_SIGNALS="$2"
            shift 2
            ;;
        --word-size)
            if [ $# -lt 2 ]; then
                echo "Error: --word-size requires a numeric argument"
                echo ""
                usage
            fi
            WORD_SIZE="$2"
            shift 2
            ;;
        --decompose)
            DECOMPOSE=true
            shift
            ;;
        --raw-bytes)
            RAW_BYTES=true
            shift
            ;;
        --keep-c)
            KEEP_C=true
            shift
            ;;
        --cc)
            if [ $# -lt 2 ]; then
                echo "Error: --cc requires a compiler argument"
                echo ""
                usage
            fi
            CC="$2"
            shift 2
            ;;
        *)
            # Check if it's a number (could be num_signals or word_size)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                if [ -z "$NUM_SIGNALS" ]; then
                    NUM_SIGNALS="$1"
                elif [ -z "$WORD_SIZE" ]; then
                    WORD_SIZE="$1"
                else
                    echo "Error: Too many numeric arguments"
                    echo ""
                    usage
                fi
            else
                echo "Error: Unknown option '$1'"
                echo ""
                usage
            fi
            shift
            ;;
    esac
done

# Validate word size (only if provided)
if [ -n "$WORD_SIZE" ] && [[ ! "$WORD_SIZE" =~ ^(8|16|32|64)$ ]]; then
    echo "Error: Word size must be 8, 16, 32, or 64"
    exit 1
fi

# Validate that spec file exists
if [ ! -f "$SPEC_FILE" ]; then
    echo "Error: Specification file '$SPEC_FILE' does not exist"
    exit 1
fi

# Get the directory of this script to find c2po.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
C2PO_PATH="$SCRIPT_DIR/compiler/c2po.py"

# Check if c2po.py exists
if [ ! -f "$C2PO_PATH" ]; then
    echo "Error: c2po.py not found at $C2PO_PATH"
    exit 1
fi

# Build the command
COMMAND=(
    "python3"
    "$C2PO_PATH"
    "-c"
    "--extops"
    "--sabre"
)

# Add sabre-nsigs if num_signals is provided
if [ -n "$NUM_SIGNALS" ]; then
    COMMAND+=("--sabre-nsigs" "$NUM_SIGNALS")
fi

# Add sabre-word-size if word_size is provided
if [ -n "$WORD_SIZE" ]; then
    COMMAND+=("--sabre-word-size" "$WORD_SIZE")
fi

# Add optional flags
if [ "$DECOMPOSE" = true ]; then
    COMMAND+=("--sabre-decompose")
fi

if [ "$RAW_BYTES" = true ]; then
    COMMAND+=("--sabre-raw-bytes")
fi

# Add the specification file
COMMAND+=("$SPEC_FILE")

# Create a temporary file to store the C output
if [ "$KEEP_C" = true ]; then
    # Use the output executable name with .c extension
    TEMP_C_FILE="${OUTPUT_EXECUTABLE}.c"
else
    # Use a temporary file
    TEMP_C_FILE=$(mktemp).c
fi
C2PO_ERRORS=$(mktemp)

if ! "${COMMAND[@]}" > "$TEMP_C_FILE" 2> "$C2PO_ERRORS"; then
    cat "$C2PO_ERRORS"
    exit 1
fi

# Check if there were any warnings or errors in stderr
if [ -s "$C2PO_ERRORS" ]; then
    echo "Warning: c2po.py reported the following:"
    cat "$C2PO_ERRORS"
    echo ""
fi

# Compile the C program
$CC -O3 -o "$OUTPUT_EXECUTABLE" "$TEMP_C_FILE"
CC_EXIT_CODE=$?

if [ $CC_EXIT_CODE -ne 0 ]; then
    echo "Error: Compilation failed with exit code $CC_EXIT_CODE"
    exit 1
fi

# Clean up temporary files
rm -f "$C2PO_ERRORS"
if [ "$KEEP_C" = false ]; then
    rm -f "$TEMP_C_FILE"
fi

# **SUDOKU PROJECT WITH SCALING AND VECTORIZED IMPLEMENTATION**
Sudoku project with scaling and vectorized implementation in RISC-V assembly language on a 64x64 board  
‎ 
## **FEATURES**

### Sudoku Implementation
- Support for a 64x64 Sudoku grid, significantly larger than standard.
- Assembly-based logic for efficient computation.

### Scaling and Vectorized Approaches
- Two distinct implementations:
  - **Scaler Implementation**: Focused on resource-efficient processing.
  - **Vectorized Implementation**: Optimized for speed and parallelization.
- Outputs include hex files, disassembly, and logs for debugging and performance analysis.

### Log-to-Memory Conversion
- Converts output logs from the Sudoku computation into memory-friendly formats.
- Tools for preloaded and transposed data representation.  
‎ 
## **TECHNICAL DETAILS**

### Assembly Files
- `SudokoScaler.s` and `SudokoVector.s`: Core logic implemented in RISC-V assembly.
- Customized for high efficiency and compatibility with hardware-level operations.

### Supporting Scripts
- `convert.py`: Python script to convert logs into CSV and text files for further analysis.

### Data Handling
- CSV and text files such as `scaler64x64output.csv` and `64x64_preloadedTransposedOutput.csv` provide clear representations of output data.
- Preloaded transposed files for improved memory access patterns.  
‎ 
## **STRUCTURE**

### Top-Level Files
- `InstructionToRunTheCode.txt`: Step-by-step guide to execute the project.
- `TheReport.pdf`: Comprehensive documentation of the project, including objectives, methodology, and results.

### Directories
1. **`vectorizedCode`**
   - Contains:
     - `simple.s`, `link.ld`, and `Makefile`: For building and configuring the vectorized implementation.
     - `TEST.exe`, `program.hex`, `TEST.dis`: Executable and debug files.
     - `log.txt`: Runtime logs.

2. **`scalerCode`**
   - Similar to `vectorizedCode`, focusing on the scaled implementation.

3. **`Sudoku-Veer-ISS-Log-to-Memory-Converter`**
   - Includes:
     - `convert.py`: Python script for log processing.
     - Data files: `scaler64x64output.csv`, `64x64_preloadedTransposedOutput.csv`, and others.
     - `.git` directory: Version control history and configurations.  
‎ 
## **HOW TO RUN**
1. Refer to `InstructionToRunTheCode.txt` for detailed steps.
2. Use the provided Makefiles in the `vectorizedCode` and `scalerCode` directories to compile the assembly files.
3. Execute `TEST.exe` or analyze outputs such as `program.hex` or `TEST.dis`.
4. Run `convert.py` for log-to-memory conversion as needed.  
‎ 
## **NOTES**
- Ensure the necessary tools and dependencies for RISC-V assembly and Python are installed.
- For detailed explanations of the methodology and results, refer to `TheReport.pdf`.

---
This project showcases advanced Sudoku implementations leveraging both scaling and vectorization for efficiency and performance.


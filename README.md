# RML IO - Konverter Frontend

This is a RML IO frontend for the konverter relational algebra executor. The frontend parses valid RML IO formatted mapping files and executes them.

## Prerequisites

- **C++ Compiler:** Install a C++ compiler (e.g., using `sudo apt install build-essential`).
- **Konverter Backend:** Download and build the konverter backend and place the required shared libraries in the `backend/` directory.

## Usage

### Direct Usage

1. **Prepare the Backend:**
   - Download and build the konverter backend.
   - Place the required files (e.g., `libexecutor.so`, `librapartitioner.so`, `libthreadexecutor.so`) in the `backend/` directory.

2. **Build the Standalone C++ Files:**
   - Run the `build_standalone.sh` script to compile the generated C++ files.

3. **Run the Pipeline:**
   - Execute the complete end-to-end pipeline with:
     ```bash
     python3 rml_frontend.py -m path/to/mapping.ttl
     ```

### Compilation into a Standalone Executable

1. **Prepare the Backend:**
   - Download and build the konverter backend.
   - Place the required files in the `backend/` directory.

2. **Build the C++ Files:**
   - Run the `build.sh` script to compile the generated C++ files.

3. **Bundle with Nuitka:**
   - The build process will bundle everything into a standalone executable (e.g., `rml_frontend.bin`).

4. **Run the Executable:**
   - Execute the standalone executable using:
     ```bash
     ./rml_frontend.bin -m path/to/mapping.ttl
     ```

## Notes

- **Shared Libraries:** Ensure that the shared libraries from the backend are correctly located.
- **Build Scripts:** The provided `build_standalone.sh` and `build.sh` scripts are required for compiling and packaging the frontend.

## Contributing

Feel free to open issues or submit pull requests if you encounter any problems or have suggestions for improvements.

## License
The code uses the serd library for RDF parsing, which is licensed under the ISC License and is downloaded during the build process.

Our code is licensed under the GNU Affero General Public License version 3.
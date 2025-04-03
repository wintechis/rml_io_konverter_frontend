import ctypes
import os
import argparse
import sys
import time

from backend.konverter import run_converter

class Configuration:
    def __init__(self):
        self.mapping_path_file = ""
        self.output_file_path = "./res.nq"
        self.base_uri = "http://example.com/base/"
        self.continue_on_error = "false"
        self.threading_enabled = "true"
        self.materialize_constants = "true"
        self.heuristic_ordering = "true"
        self.bn_number = 58932
        self.lib_rml_parser = self.load_rml_parser()
        self.lib_rml_io_normalizer = self.load_rml_io_normalizer()
        self.lib_ra_converter = self.load_ra_converter()

    def load_rml_parser(self):
        base_path = sys._MEIPASS if getattr(sys, 'frozen', False) else os.path.dirname(__file__)
        lib_path = os.path.join(base_path, "librdfparser.so")

        try:
            lib = ctypes.CDLL(lib_path)
            lib.parse_rdf.argtypes = [ctypes.c_char_p]
            lib.parse_rdf.restype = ctypes.c_char_p
            return lib
        except OSError as e:
            print(f"Error loading 'librdfparser.so': {e}")
            sys.exit(1)

    def load_rml_io_normalizer(self):
        base_path = sys._MEIPASS if getattr(sys, 'frozen', False) else os.path.dirname(__file__)
        lib_path = os.path.join(base_path, "libnormalizer.so")

        try:
            lib = ctypes.CDLL(lib_path)
            lib.normalize_rml_mapping.argtypes = [ctypes.c_char_p, ctypes.c_int]
            lib.normalize_rml_mapping.restype = ctypes.c_char_p
            return lib
        except OSError as e:
            print(f"Error loading 'libnormalizer.so': {e}")
            sys.exit(1)

    def load_ra_converter(self):
        base_path = sys._MEIPASS if getattr(sys, 'frozen', False) else os.path.dirname(__file__)
        lib_path = os.path.join(base_path, "libraconverter.so")

        try:
            lib = ctypes.CDLL(lib_path)
            lib.create_relational_algebra.argtypes = [ctypes.c_char_p]
            lib.create_relational_algebra.restype = ctypes.c_char_p
            return lib
        except OSError as e:
            print(f"Error loading 'libraconverter.so': {e}")
            sys.exit(1)

####################################################################################################################

def load_rml(file_path, config):
    try:
        file_path = file_path.encode()
        lib = config.lib_rml_parser

        result = lib.parse_rdf(file_path)

        if result is None:
            print("RDF parser function returned NULL or encountered an error")
            sys.exit(1)

        result_str = result.decode()
        if result_str.startswith("Error:"):
            print(result_str)
            sys.exit(1)

        return result_str
    except OSError as e:
        print(f"Failed to load library: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)

def normalize_mapping(rml_str, config):
    rml_str = rml_str.encode()

    lib = config.lib_rml_io_normalizer
    result = lib.normalize_rml_mapping(rml_str, config.bn_number)

    if not result:
        print("Error: Function returned NULL")
        sys.exit(1)

    normalized_result = result.decode()

    # Separate graphs
    normalized_graphs = []
    for sub_graph in normalized_result.split("===="):
        sub_graph = sub_graph.strip()
        if sub_graph == "":
            continue
        normalized_graphs.append(sub_graph)

    return normalized_graphs

def convert_to_ra(normalized_graphs_arr, config):
    ra_expressions = []
    for normalized_graph in normalized_graphs_arr:
        normalized_graph = normalized_graph.encode()

        lib = config.lib_ra_converter
        results = lib.create_relational_algebra(normalized_graph)

        results = results.decode()

        results_split = results.strip().split("\n")
        results_split = [item for item in results_split if item] # Remove empty strings ""

        for result in results_split:
            ra_expressions.append(result)

    return ra_expressions

####################################################################################################################

def handle_cli(config):
    parser = argparse.ArgumentParser(description="konverter: A simple and fast RML interpreter.")
    parser.add_argument("-m", "--mapping", type=str, required=True, help="The path to the RML mapping file")
    parser.add_argument("-o", "--output", type=str, required=False, help="The path where the output RDF graph is stored.")
    parser.add_argument("-b", "--base", type=str, required=False, help="The base URI used to generate RDF terms.")
    parser.add_argument("--continue-on-error", action='store_true', help="Continues on error if the flag is set.")
    parser.add_argument("--no-threading", action='store_false', help="Disables multithreading during execution.")
    parser.add_argument("--no-const-folding", action='store_false', help="Disables constant folding optimization.")
    parser.add_argument("--no-ordering", action='store_false', help="Disables heuristic ordering optimization.")


    args = parser.parse_args()
    config.mapping_file_path = args.mapping

    if args.output:
        config.output_file_path = args.output

    if args.base:
        config.base_uri = args.base

    if args.continue_on_error:
        config.continue_on_error = str(args.continue_on_error).lower()

    if args.no_threading == False:
        config.threading_enabled = str(args.no_threading).lower()
    
    if args.no_const_folding == False:
        config.materialize_constants = str(args.no_const_folding).lower()

    if args.no_ordering == False:
        config.heuristic_ordering = str(args.no_const_folding).lower()


####################################################################################################################

def to_ra_string(ra_expressions):
    res = ""
    for ra_expression in ra_expressions:
        res += ra_expression + "\n"

    res.strip()
    return res

def main():
    start_time = time.time()

    ### Handle CLI input ###
    config = Configuration()
    handle_cli(config)

    ### STEP 1: Parse & Validate ###
    rml_str = load_rml(config.mapping_file_path, config)
    
    ### STEP 2: Rewrite & Normalize ###
    normalized_graphs_arr = normalize_mapping(rml_str, config)
    normalized_graphs_arr.sort()
    
    ### STEP 3: Logical plan generation
    ra_expressions = convert_to_ra(normalized_graphs_arr, config)

    ra_str = to_ra_string(ra_expressions)

    print("Frontend took:", time.time()-start_time)

    run_converter(ra_str)

if __name__ == "__main__":
    main()
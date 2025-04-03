#include "rdf_parser.h"
#include <cstring>
#include "definitions.h"
#include <fstream>

// used to store string result
static std::string g_result_str;

std::string readFile(const std::string &file_path)
{
    std::ifstream file(file_path, std::ios::in | std::ios::binary);
    if (!file)
    {
        throw std::runtime_error("Could not open file: " + file_path);
    }
    return std::string((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
}

extern "C"
{

    // Function to process the RDF string and return the result
    const char *parse_rdf(const char *file_path)
    {
        try
        {
            std::string rdf_mapping = readFile(file_path);
            // Parse the input RDF rule
            RDFParser parser;
            std::vector<NTriple> rml_triple = parser.parse(rdf_mapping);

            // Clear the global result string
            g_result_str.clear();

            // Build a single string from the parsed triples
            for (const auto &el : rml_triple)
            {
                g_result_str += el.subject + "|||" + el.predicate + "|||" + el.object + "\n";
            }

            // Return result as a C-string
            return g_result_str.c_str();
        }
        catch (const std::runtime_error &e)
        {
            // Return the error message as a string
            static std::string error_msg = "Error: " + std::string(e.what());
            return error_msg.c_str();
        }
        catch (...)
        {
            static std::string error_msg = "Error: Unknown error occurred.";
            return error_msg.c_str();
        }
    }
}
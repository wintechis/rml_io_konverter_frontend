#include "rdf_parser.h"

#include <algorithm>
#include <sstream>

RDFParser::RDFParser()
    : env(serd_env_new(NULL)) {}

RDFParser::~RDFParser() {
  serd_env_free(env);
}

std::vector<NTriple> RDFParser::parse(const std::string& rml_rule) {
  handle_rdf_parsing(rml_rule);

  return rml_triples;
}

SerdStatus RDFParser::static_handle_error(void* handle, const SerdError* error) {
  return ((RDFParser*)handle)->handle_error(handle, error);
}

SerdStatus RDFParser::static_capture_prefix(void* handle, const SerdNode* name, const SerdNode* uri) {
  return ((RDFParser*)handle)->capture_prefix(name, uri);
}

SerdStatus RDFParser::static_handle_triple(void* handle, unsigned int flags, const SerdNode* graph, const SerdNode* subject, const SerdNode* predicate, const SerdNode* object, const SerdNode* datatype, const SerdNode* lang) {
  return ((RDFParser*)handle)->handle_triple(handle, flags, graph, subject, predicate, object, datatype, lang);
}

std::string RDFParser::extract_base_URI(const std::string& str) {
  std::istringstream stream(str);  // Convert the string to a stream for line-by-line processing
  std::string line;

  while (std::getline(stream, line)) {
    // Remove leading and trailing whitespace
    size_t start = line.find_first_not_of(" \t");
    size_t end = line.find_last_not_of(" \t");

    if (start != std::string::npos) {
      line = line.substr(start, end - start + 1);
    } else {
      line = "";
    }

    // Check if line starts with @base
    if (line.find("@base") == 0) {
      size_t begin = line.find('<');
      size_t finish = line.find('>');

      if (begin != std::string::npos && finish != std::string::npos) {
        return line.substr(begin + 1, finish - begin - 1);
      }
    }
  }
  return "";  // Return empty string if @base not found
}

// Error handling function for Serd
SerdStatus RDFParser::handle_error(void* handle, const SerdError* error) {
  (void)handle;

  std::string error_message = "Runtime error occurred. " + error->status;
  throw std::runtime_error(error_message);

  return SERD_FAILURE;
}

// Function to add prefix to envionment
SerdStatus RDFParser::capture_prefix(const SerdNode* name, const SerdNode* uri) {
  // Set the prefix in the environment
  return serd_env_set_prefix(env, name, uri);
}

// Function to expand a serd curie to an uri
SerdNode RDFParser::expand_node(const SerdNode* node) {
  SerdNode expanded = serd_env_expand_node(env, node);
  if (expanded.buf) {
    return expanded;
  }
  return *node;
}

SerdStatus RDFParser::handle_triple(
    void* handle,
    unsigned int flags,
    const SerdNode* graph,
    const SerdNode* subject,
    const SerdNode* predicate,
    const SerdNode* object,
    const SerdNode* datatype,
    const SerdNode* lang) {
  // Unused parameters
  (void)handle;
  (void)flags;
  (void)graph;
  (void)datatype;
  (void)lang;

  // Create a NTriple struct instance
  NTriple triple;

  // Expand nodes and directly store in quad
  SerdNode expanded_subject = expand_node(subject);
  triple.subject = (const char*)expanded_subject.buf;

  SerdNode expanded_predicate = expand_node(predicate);
  triple.predicate = (const char*)expanded_predicate.buf;

  SerdNode expanded_object = expand_node(object);
  triple.object = (const char*)expanded_object.buf;

  rml_triples.push_back(triple);

  return SERD_SUCCESS;
}

void RDFParser::handle_rdf_parsing(const std::string& rdf_data) {
  std::vector<NTriple> rml_triples;

  std::string base_uri = extract_base_URI(rdf_data);

  // Create a SerdNode for the base_uri string
  SerdNode baseNode = serd_node_new_uri_from_string((const uint8_t*)base_uri.c_str(), NULL, NULL);

  // Set the base URI for the environment
  serd_env_set_base_uri(env, &baseNode);

  //// Setup serd reader ////
  SerdReader* reader = serd_reader_new(
      SERD_TURTLE,            // Reading Turtle RDF
      this,                   // Handle for your user data
      nullptr,                // Free function for user data
      nullptr,                // Base sink
      static_capture_prefix,  // Prefix sink
      static_handle_triple,   // Statement sink
      nullptr);               // End sink

  // Set the error handling function for the reader
  serd_reader_set_error_sink(reader, static_handle_error, this);

  // Parse the data
  SerdStatus status = serd_reader_read_string(reader, (const uint8_t*)rdf_data.c_str());
  if (status) {
    throw std::runtime_error("Runtime error occurred reading RML rule.");
  }

  // Free memory from Serd
  serd_reader_free(reader);
}
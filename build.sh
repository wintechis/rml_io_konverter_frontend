#!/bin/bash

download_if_not_exists() {
    local filepath=$1
    local url=$2

    if [ ! -f "$filepath" ]; then
        echo "Downloading $filepath..."
        wget -O "$filepath" "$url"
    fi
}

check_if_exists() {
    local filepath=$1
    if [ ! -f "$filepath" ]; then
        echo "Build failed: $filepath not found."
        exit 1
    else 
        echo "Success."
    fi
}

echo "Preparing files ..."
# Download RDF parser code (serd)
download_if_not_exists ./rdf_parser/serd_lib/serd/serd.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/include/serd/serd.h
download_if_not_exists ./rdf_parser/serd_lib/attributes.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/attributes.h
download_if_not_exists ./rdf_parser/serd_lib/base64.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/base64.c
download_if_not_exists ./rdf_parser/serd_lib/base64.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/base64.h
download_if_not_exists ./rdf_parser/serd_lib/byte_sink.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/byte_sink.h
download_if_not_exists ./rdf_parser/serd_lib/byte_source.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/byte_source.c
download_if_not_exists ./rdf_parser/serd_lib/byte_source.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/byte_source.h
download_if_not_exists ./rdf_parser/serd_lib/env.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/env.c
download_if_not_exists ./rdf_parser/serd_lib/n3.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/n3.c
download_if_not_exists ./rdf_parser/serd_lib/node.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/node.c
download_if_not_exists ./rdf_parser/serd_lib/node.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/node.h
download_if_not_exists ./rdf_parser/serd_lib/reader.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/reader.c
download_if_not_exists ./rdf_parser/serd_lib/reader.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/reader.h
download_if_not_exists ./rdf_parser/serd_lib/serd_config.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/serd_config.h
download_if_not_exists ./rdf_parser/serd_lib/serd_internal.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/serd_internal.h
download_if_not_exists ./rdf_parser/serd_lib/stack.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/stack.h
download_if_not_exists ./rdf_parser/serd_lib/string.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/string.c
download_if_not_exists ./rdf_parser/serd_lib/string_utils.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/string_utils.h
download_if_not_exists ./rdf_parser/serd_lib/system.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/system.c
download_if_not_exists ./rdf_parser/serd_lib/system.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/system.h
download_if_not_exists ./rdf_parser/serd_lib/try.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/try.h
download_if_not_exists ./rdf_parser/serd_lib/uri.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/uri.c
download_if_not_exists ./rdf_parser/serd_lib/uri_utils.h https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/uri_utils.h
download_if_not_exists ./rdf_parser/serd_lib/writer.c https://raw.githubusercontent.com/drobilla/serd/abfdac2085cba93bae76d3352f2ff7e40fdf1612/src/writer.c

echo "All files required files are present."
echo ""

echo "Cleaning up old shared object files..."
rm libnormalizer.so libraconverter.so librdfparser.so
echo ""


echo "Building rml parser ..."
g++ -std=c++20 -shared -fPIC -Irdf_parser/serd_lib -o ./librdfparser.so ./rdf_parser/rdf_parser_lib.cpp ./rdf_parser/rdf_parser.cpp ./rdf_parser/serd_lib/*.c -O3
check_if_exists ./librdfparser.so
echo ""

echo "Building rml normalizer ..."
g++ -std=c++20 -shared -fPIC -o ./libnormalizer.so ./rml_normalizer/rml_io_normalizer.cpp -O3
check_if_exists ./libnormalizer.so
echo ""

echo "Building relational algebra converter ..."
g++ -std=c++20 -shared -fPIC -o ./libraconverter.so ./ra_converter/ra_converter_rml_io.cpp -O3
check_if_exists ./libnormalizer.so
echo ""

# Build executable
nuitka --onefile --follow-imports --include-data-files=librdfparser.so=./ --include-data-files=libnormalizer.so=./ --include-data-files=libraconverter.so=./ --include-data-files=./backend/libexecutor.so=./backend/ --include-data-files=./backend/librapartitioner.so=./backend/ --include-data-files=./backend/libthreadexecutor.so=./backend/ --no-deployment-flag=self-execution rml_frontend.py 
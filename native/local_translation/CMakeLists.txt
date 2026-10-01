cmake_minimum_required(VERSION 3.15)
project(ja_translation LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
get_filename_component(TOOLS "${CMAKE_CURRENT_LIST_DIR}/../../.local_ai_tools" ABSOLUTE)
add_library(ct2 SHARED IMPORTED)
set_target_properties(ct2 PROPERTIES
  IMPORTED_IMPLIB "${TOOLS}/ct2-build/Release/ctranslate2.lib"
  IMPORTED_LOCATION "${TOOLS}/ct2-build/Release/ctranslate2.dll"
  INTERFACE_INCLUDE_DIRECTORIES "${TOOLS}/CTranslate2/include")
add_library(spm STATIC IMPORTED)
set_target_properties(spm PROPERTIES
  IMPORTED_LOCATION "${TOOLS}/spm-build/src/Release/sentencepiece.lib"
  INTERFACE_INCLUDE_DIRECTORIES "${TOOLS}/sentencepiece/src")
add_library(ja_translation SHARED bridge.cpp)
target_compile_options(ja_translation PRIVATE /utf-8 /EHsc)
target_link_libraries(ja_translation PRIVATE ct2 spm)

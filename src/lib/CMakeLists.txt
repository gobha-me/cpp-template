# ── Library target ──────────────────────────────────────────────────────────
# The template's opinionated answer to "how do I structure a library":
# a compiled static lib by default, with the header-only (INTERFACE) variant
# shown as a commented alternative below. Disable entirely with:
#   cmake -B build -D<PROJECT>_BUILD_LIB=OFF
# (consumers that only want the bin, or none of the lib, can opt out.)

option(${PROJECT_NAME}_BUILD_LIB "Build the compiled library target" ON)

if (${PROJECT_NAME}_BUILD_LIB)
  # Default: a compiled static library from src/lib/*.cpp, public headers in
  # include/. Add sources here as the project grows.
  add_library(${PROJECT_NAME}_lib STATIC
    lib.cpp
  )

  target_include_directories(${PROJECT_NAME}_lib
    PUBLIC ${CMAKE_SOURCE_DIR}/include
  )

  # Compiled libs get the project's include dir PUBLIC so consumers (bin,
  # tests, downstream) inherit it transitively.
  add_library(${PROJECT_NAME}::lib ALIAS ${PROJECT_NAME}_lib)
endif ()

# ── Alternative: header-only (INTERFACE) library ────────────────────────────
# For header-only projects (e.g. a single-include API client), drop the
# compiled target above and use an INTERFACE library instead — no .cpp, no
# archive, just include dirs (+ any usage requirements) propagated to
# consumers. Uncomment to use:
#
# add_library(${PROJECT_NAME}_lib INTERFACE)
# target_include_directories(${PROJECT_NAME}_lib
#   INTERFACE ${CMAKE_SOURCE_DIR}/include
# )
# add_library(${PROJECT_NAME}::lib ALIAS ${PROJECT_NAME}_lib)

find_package(fmt QUIET)

if (fmt_FOUND)
else ()
    if (NOT FMT_URI)
        set(FMT_URI https://github.com/fmtlib/fmt) 
    endif()

    if (NOT FMT_TAG)
        set(FMT_TAG 11.1.4)
    endif()

    # Don't let a fetched dependency install itself into our prefix. fmt's
    # FMT_INSTALL defaults ON even as a subproject, so without this line
    # `cmake --install` on this project also deposits libfmt.a, include/fmt/ and
    # fmt's whole cmake package into the user's prefix — a vendored copy that
    # shadows theirs. Catch2 and argparse gate their own install rules on being
    # the top-level project and need no equivalent.
    #
    # Relies on CMP0077 (NEW here, via cmake_minimum_required 3.28): a normal
    # variable set before the subproject's option() call wins.
    set(FMT_INSTALL OFF)

    include(FetchContent)
    FetchContent_Declare(
        fmt
        GIT_REPOSITORY ${FMT_URI}
        GIT_TAG ${FMT_TAG}
    )

    FetchContent_MakeAvailable(fmt)
endif()


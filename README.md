# CPP CMake Template Project

[![CI](https://github.com/gobha-me/cpp-template/actions/workflows/ci.yml/badge.svg)](https://github.com/gobha-me/cpp-template/actions/workflows/ci.yml)

The basic idea is to have an easy-button copy/paste starter for new CPP projects.
I tend to "play" around with some ideas and new features of the language
outside of "work". CMake is the "standard" project management tool used at work,
so creating this helps me learn more about it. At the same time I'm trying not
to repeat myself as new project ideas come up.

The minimum is **CMake 3.28** (current LTS distros ship it), and projects default
to the **C++23** standard.

Some features baked in, and the assumptions behind them:

* **Auto naming** — the default project name is pulled from the parent dir of the
  root `CMakeLists.txt`.
  * There was a note that this is a bad idea, but it didn't really explain the
    details of why.
  * This is an easy-button starter that "should" just work out of the box — just
    update the `project()` portion of the file.
* **Version comes from git tags** — `cmake/version.cmake` parses
  `git describe --tags --dirty` into `MAJOR.MINOR.PATCH`, plus a `VERSION_TWEAK`
  (commits since the tag) and `VERSION_DIRTY` flag exposed in the generated
  `include/version.hpp`. No tags/git falls back to `0.0.0` with a reason. The
  pure parser lives in `cmake/version_parse.cmake` and is self-tested via
  `cmake -P cmake/version_selftest.cmake` (also a ctest: `version-parse-selftest`).
* **C++23 by default** (GCC 13+ / Clang 19+). Note: the `std::expected` example
  in `test/20failure-testing` needs a C++23 standard library that provides
  `<expected>` — GCC 13+'s libstdc++, Clang 19+ with libstdc++, or any Clang with
  libc++. Clang 18 + libstdc++ (the Ubuntu 24.04 stock pairing) can't build it, so
  CI pins its Clang jobs to Clang 20.
* **Compiler respects the environment** — the default toolchain
  (`cmake/toolchain/default.cmake`) takes the compiler from `CXX` / the platform
  default rather than forcing one. Prefer clang? Opt in via a toolchain file:
  ```bash
  cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain/clang.cmake
  ```
* **Library pattern** in `src/lib/` — an opinionated but toggleable default:
  a compiled `STATIC` library out of the box (disable with
  `-D<PROJECT>_BUILD_LIB=OFF`), with the header-only (`INTERFACE`) variant shown
  as a commented alternative for header-only projects.
* **Tests**
  * Catch2 (v3) for writing tests.
    * Empty fixture scripts for starting/stopping any services required for
      tests, baked into `test/main.cpp` and other parts of the tree.
    * If you want a different framework, replacing it is left as an exercise.
  * Tests live in `test/`.
    * `test/CMakeLists.txt` loops over the dirs in this path.
    * To force test ordering, prefix names with `##` — see the example names.
    * Can be as simple as `test/<test_name>/test.cpp`.
      * This strategy makes adding tests really simple — just focus on the test
        code.
      * On the other hand, if the code is already built, `cmake -B` has to be
        run again to pick up a new test dir.
      * If you need more control over a test's build, add a `CMakeLists.txt` in
        that dir.
* **Toolchains** live in `cmake/toolchain/`; the default is `default.cmake`.
  * Default build type is Debug.
  * Separate opt-in files enable clang or the sanitizers:
    * `clang.cmake`
    * `address.cmake`
    * `thread.cmake`
    * `undefined.cmake`
* **Dependency management**
  * Not using a dedicated dependency manager such as conan.io.
    * Not using one at work at the moment.
    * Not seeing clear, concise examples of CMake integration that fit my model
      above.
    * Trying, for the moment, to stay 100% CMake.
  * Using a combination of `find_package` and `FetchContent` for managing
    dependencies.
    * Over time, as I build new files, I'll most likely add them here.
  * **Opt-in, not glob-everything** — each dependency is a recipe file in
    `cmake/deps/<name>.cmake`, but a recipe is only fetched when its name is
    listed in `<PROJECT>_DEPS` in the root `CMakeLists.txt`. That list is the
    single prune point for a new project: drop a name to stop fetching that dep;
    add a recipe file *and* its name to add one.
* **Export of the compile database** (`compile_commands.json`) is enabled by
  default.

## Usage

```bash
# configure (optionally pick a toolchain, e.g. clang or a sanitizer)
cmake -B <build-dir> [-DCMAKE_TOOLCHAIN_FILE=<toolchain file>]

# build
cmake --build <build-dir> --parallel 4

# test
ctest --test-dir <build-dir> -V
```

## Continuous integration

`.github/workflows/ci.yml` builds and tests on every push to `main` and every
pull request, enforcing the "both compilers, always" rule:

* **GCC and Clang** ×
* the **default** toolchain plus every sanitizer (**address**, **thread**,
  **undefined**) — 8 build/test jobs in all,
* plus a fast, dependency-free `version-parse-selftest` job.

A change that only builds on one compiler turns that compiler's jobs red, so a
one-sided break is visible on the PR.

**Copying this into a new project:** the workflow hardcodes nothing
project-specific — the project name is derived from the checkout directory, so
copy `.github/workflows/ci.yml` verbatim. The only edit is the badge URL above:
replace `gobha-me/cpp-template` with your `owner/repo`.

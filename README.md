# CPP CMake Template Project

[![CI](https://github.com/gobha-me/cpp-template/actions/workflows/ci.yml/badge.svg)](https://github.com/gobha-me/cpp-template/actions/workflows/ci.yml)

> **Starting a new project from this?** Follow **[NEW_PROJECT.md](NEW_PROJECT.md)** —
> an ordered checklist from "copied the tree" to "clean project," with the traps
> called out. Everything below describes the template as it stands.

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
  * Its public API lives in `include/lib.hpp`, and auto-discovered tests link it
    for you.
  * `-D<PROJECT>_BUILD_LIB=OFF` removes the target entirely, so nothing can link
    it — pair it with `-D<PROJECT>_TESTS=OFF` unless your tests avoid the
    library.
* **Tests**
  * Catch2 (v3) for writing tests. If you want a different framework, replacing
    it is left as an exercise.
  * Tests live in `test/`, one directory per test.
    * `test/CMakeLists.txt` globs the dirs in this path at configure time.
    * Can be as simple as `test/<test_name>/test.cpp`. `test/main.cpp` supplies
      `main()`, and the target links Catch2 **and** `<PROJECT>::lib` when the
      library target exists — so a test can include a public header from
      `include/` and call into `src/lib/` with no build wiring of its own.
      * This strategy makes adding tests really simple — just focus on the test
        code.
      * On the other hand, if the code is already built, `cmake -B` has to be
        run again to pick up a new test dir.
      * If you need more control over a test's build, add a `CMakeLists.txt` in
        that dir — it then owns all of its own wiring, the library link
        included.
    * The numeric prefixes (`01example`, `20failure-testing`) sort that glob, so
      they set the order tests are *registered* — the order `ctest -N` lists
      them. They are not an execution guarantee: even a serial run reorders
      around fixtures, and `ctest -j` ignores them outright. When one test
      genuinely must run after another, say so with fixtures or `DEPENDS`, not
      with names.
    * `cmake/startup.sh` and `cmake/shutdown.sh` are the hooks for services the
      suite depends on. They are wired in `test/CMakeLists.txt` as the `runners`
      fixture (`FIXTURES_SETUP` / `FIXTURES_CLEANUP`), run once per `ctest`
      invocation, and ship as no-ops — fill them in if your tests need something
      running.
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

## Cheat sheet

**Configure, build, test — and picking a toolchain**

```bash
cmake -B build                                                            # $CXX, C++23, Debug
cmake -B build-clang -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain/clang.cmake   # clang
CXX=clang++ cmake -B build-asan -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain/address.cmake

cmake --build build --parallel
ctest --test-dir build --output-on-failure
```

Run these from the repo root — the toolchain paths are relative. You cannot pass
two toolchain files, so a sanitizer composes with clang via `CXX=`, as above.

**Add a dependency**

```bash
cp cmake/deps/catch2.cmake cmake/deps/<name>.cmake   # catch2.cmake is the annotated recipe template
$EDITOR cmake/deps/<name>.cmake                      # find_package first, FetchContent fallback
$EDITOR CMakeLists.txt                               # add <name> to <PROJECT>_DEPS
cmake -B build
```

The recipe file alone does nothing — the list is the switch. A name on the list
with no recipe is a hard configure error; a recipe not on the list is inert. To
remove a dependency, delete its name from the list; the file can stay.

**Add a test**

```bash
mkdir test/40myfeature
$EDITOR test/40myfeature/test.cpp    # TEST_CASEs only — test/main.cpp provides main()
cmake -B build && cmake --build build --parallel && ctest --test-dir build
```

It becomes the target and ctest name `40myfeature-test`. **Re-run `cmake -B`
after adding a directory** — discovery is a configure-time glob. The numeric
prefix only sorts that glob; it does not order the run (see the Tests bullet
above). The target links Catch2 and, when the library target exists,
`<PROJECT>::lib` — so `#include <lib.hpp>` and call into `src/lib/` directly,
with nothing to wire up. If a test needs custom build control, give it its own
`test/<dir>/CMakeLists.txt`: it inherits `TEST_NAME` and `SRCS` from the parent
scope, must define a target named exactly `${TEST_NAME}`, and must do its own
linking — the discovery loop's link lines do not reach it (see
`test/02example/`).

**Run one test**

```bash
ctest --test-dir build -N                                              # list them
ctest --test-dir build -R 20failure-testing-test --output-on-failure   # one, plus its fixtures
ctest --test-dir build -R 20failure-testing-test -FS . -FC .           # one, fixtures skipped

./build/test/20failure-testing-test --list-tests                       # Catch2 cases within it
./build/test/20failure-testing-test "[failure]"                        # one case, or a tag
./build/test/20failure-testing-test -s                                 # show successful assertions too
```

`-R` is a regex match on the test name. Every discovered test carries
`FIXTURES_REQUIRED runners`, so ctest re-adds `startup` and `shutdown` even when
you filter — `-R` alone reports **three** tests, not one. `-FS . -FC .` excludes
the fixtures. Tests with their own `CMakeLists.txt` build into
`build/test/<dir>/`; the rest land in `build/test/`.

**Cut a release tag**

```bash
git tag -a v1.2.3 -m "v1.2.3"
git push origin v1.2.3
cmake -B build          # the version is read at CONFIGURE time — re-configure or it is stale
cmake --build build --parallel
```

The format is enforced: optionally `v`- or `r`-prefixed, then exactly three
numeric components. `v1.2`, `v1.2.3.4` and `v1.2.3-rc1` are rejected by design
and fall back to `0.0.0` with a `STATUS` line naming the reason. Between tags,
`VERSION_TWEAK` counts commits since the tag and `VERSION_DIRTY` flags an unclean
tree; both land in `include/version.hpp`.

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
copy `.github/workflows/ci.yml` verbatim, and keep `fetch-depth: 0` or
`git describe` stops finding tags. The one edit a fork owes CI is the badge URL
above; that step and everything else a new project must change live in
[NEW_PROJECT.md](NEW_PROJECT.md).

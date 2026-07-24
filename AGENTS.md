# AGENTS.md — conventions for AI agents working in this repo

If you're an LLM (or an LLM-driven editor) about to make changes here, read
this first. This is a **C++ project template** — a copy/paste starter. Changes
here should keep it generic, buildable, and useful as a teaching scaffold for
the projects that get bootstrapped from it.

## What this repo is

A CMake-based C++ starter kit. Its job is to give a *new* C++ project a working
build, test harness, toolchain options, and dependency pattern out of the box —
with opinionated-but-swap-able defaults, not a finished application. When you
edit it, optimize for "does this help the next project start faster and
correctly," not for any one downstream project.

## Current baseline (keep these in sync if you change them)

- **CMake ≥ 3.28**, **C++23** (GCC 13+ / Clang 17+).
- **Compiler respects the environment** by default. Do **not** re-introduce a
  forced compiler in `cmake/toolchain/default.cmake`. Prefer clang? That's what
  `cmake/toolchain/clang.cmake` is for (opt-in, like the sanitizer toolchains).
- **Catch2 v3** for tests, fetched via `FetchContent` (see `cmake/deps/`).
- Dependencies: `find_package` first, `FetchContent` fallback, **100% CMake**
  (no conan/vcpkg). Keep it that way unless the maintainer asks.
- **Deps are opt-in via a list, not the filesystem.** A recipe in `cmake/deps/`
  is fetched only if its name is in `${PROJECT_NAME}_DEPS` in the root
  `CMakeLists.txt`. Dropping a file in `cmake/deps/` does **not** activate it;
  adding a dep means a recipe file **and** a line in that list.

## Conventions that matter here

- **Toolchains are opt-in files** in `cmake/toolchain/`: `default.cmake`
  (respects env), `clang.cmake`, `address.cmake`, `thread.cmake`,
  `undefined.cmake`. To add a configuration, add a file that `include()`s
  `default.cmake` and layers its flags — don't edit `default.cmake` to force a
  specific setup.
- **Library pattern** in `src/lib/`: a compiled `STATIC` lib by default
  (toggle `${PROJECT_NAME}_BUILD_LIB`), with the header-only (`INTERFACE`)
  variant shown commented. Keep both patterns present and buildable — the
  template teaches by having both.
- **Tests are auto-discovered**: `test/CMakeLists.txt` loops over `test/*/`.
  A new test is just `test/<name>/test.cpp` (no CMakeLists needed); add a
  `CMakeLists.txt` in the dir only if the test needs custom build control.
  Prefix with `##` to influence ordering. After adding a test dir, re-run
  `cmake -B`.

## Testing philosophy (the important one)

**Test how code fails, not just that it produces the right output.** A
happy-path assertion (`REQUIRE(fun(10 / 5) == 2)`) only proves the code returns
what you already knew it returned, on input chosen because it works. The
valuable tests are the adversarial ones — bad input, boundaries, overflow,
malformed external data, error paths. Write the **failure matrix first**; the
happy-path check is the last, least-interesting test (a smoke check that the
harness runs). See `test/20failure-testing/` for the canonical example — follow
it, not the factorial examples (which exist to show Catch2 mechanics).

## How to verify a change (do this before opening a PR)

```bash
cmake -B build && cmake --build build && ctest --test-dir build --output-on-failure
# and cross-compiler, since the template supports both:
cmake -B build-clang -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain/clang.cmake \
  && cmake --build build-clang && ctest --test-dir build-clang
```

Both must build clean and pass all tests. A change that only builds on one
compiler is not done. (This is how the fmt-under-clang-20 breakage was caught —
build on both, always.)

## Attribution

Follow the convention used across this org's repos: agent-authored commits
carry a trailer naming the model, e.g.

```
Co-authored-by: Kimi K3 (vcoder via Venice) <noreply@venice.ai>
Agent: vcoder / Kimi K3
```

and PRs note what was actually run to verify (per "How to verify" above).

## Notes for agents

- `include/version.hpp.in.cmake` is configured into `include/version.hpp` at
  build time; edit the `.in.cmake` source, not the generated file. If you touch
  it, keep the `#include <cstdint>` (std::uint32_t needs it).
- Build dirs (`build*/`) are gitignored — don't commit them.
- The dep pins in `cmake/deps/` are only audited when something breaks on a
  supported compiler; bump deliberately and say why in the commit.

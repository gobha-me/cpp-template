# Starting a new project from this template

A one-time checklist. Work top to bottom — the order matters in the three places
marked ⚠. Every `- [ ]` is something to do; everything else is why.

When you reach the end you delete this file. That is also what switches
`cmake/check_artifacts.cmake` from "am I still the template?" to "is this project
clean?", so a finished project keeps checking itself with nothing to wire up.

> **Scope:** the first commit only. Keeping a project *in sync* with the template
> afterwards is a different problem — see issue CT-10 (#11), not this file.
>
> **If you are editing the template itself:** this file gives instructions to the
> *fork*. Where it says "pick one," `AGENTS.md`'s "keep both patterns present"
> still governs this repo.

---

## Step 0 — Get the tree ⚠ before any `cmake -B`

- [ ] `git clone <this repo> myproject` (preferred) or `cp -r`
- [ ] `cd myproject && rm -rf .git && git init && git add -A && git commit -m "Initial commit from cpp-template"`
- [ ] `rm -f include/version.hpp`
- [ ] `rm -rf build*/`

> Two traps here, both silent.
>
> `include/version.hpp` is **generated and gitignored**. A `git clone` never
> carries it, but a `cp -r` does — and then you are building against the
> template's stale version numbers until the first configure overwrites them.
>
> `cmake/version.cmake` runs `git describe` from inside `cmake/`. If you copied
> this tree into a subdirectory of some *other* git repo and skipped `git init`,
> git walks up and answers with the **enclosing** repo's tags. Your project
> silently takes someone else's version number and nothing warns you.

---

## Step 1 — Make it yours

What to do with each file:

| Replace wholesale | Keep the shared sections, replace the intro | Copy verbatim |
| --- | --- | --- |
| `LICENSE.md` | `README.md` | `.github/workflows/ci.yml` |
| `src/bin/main.cpp` | `AGENTS.md` | `.clangd`, `.gitignore` |
| `src/lib/lib.cpp` | | `cmake/toolchain/*`, `cmake/version*.cmake` |

- [ ] **Project name.** The default is the **directory name** (`CMakeLists.txt:10-13`).
      Either name the directory what you want the project called, or replace
      `${ProjectId}` with a literal in `project()`.

  > The name is load-bearing beyond the binary. It becomes the executable target,
  > the library target `<name>_lib` / `<name>::lib`, **and the option names**
  > `<name>_TESTS` and `<name>_BUILD_LIB`, plus the deps variable `<name>_DEPS`.
  > So every `-D` flag you copy out of the README changes with it:
  > `-Dcpp-template_TESTS=OFF` becomes `-Dmyproject_TESTS=OFF`.
  >
  > Make the directory name match the GitHub repo name. CI derives the project
  > name from the checkout directory, so if they differ, CI builds under a
  > different name than you do locally.

- [ ] **`LICENSE.md` — replace it.** It is not a license. It is a four-line note
      explaining why the template deliberately ships without one, so that you can
      choose. Choosing is this step.
- [ ] **`README.md`** — replace the title, the badge, the first-person preamble
      and the feature bullets. Keep `## Cheat sheet` and `## Continuous integration`.
- [ ] **`README.md` badge** — replace `gobha-me/cpp-template` in the CI badge URL
      with your own `owner/repo`. This is the only edit CI needs.
- [ ] **`AGENTS.md`** — replace the preamble and `## What this repo is` with what
      *your* project is. Keep `## Conventions that matter here`,
      `## Testing philosophy` and `## How to verify a change` — those are the
      conventions you are inheriting on purpose.
- [ ] **`.github/workflows/ci.yml` — copy verbatim, zero edits.** It hardcodes
      nothing project-specific; the project name comes from the checkout
      directory. Leave `fetch-depth: 0` alone or `git describe` stops finding
      tags and every build reports `0.0.0`.

---

## Step 2 — Gut the demo code ⚠ before Step 3

- [ ] **`src/bin/main.cpp`** — 100% demo. Replace it.

  > It uses `std::cerr` **without** `#include <iostream>`; today it compiles only
  > because argparse and fmt drag `<iostream>` in transitively. Remove those two
  > includes without adding `<iostream>` and the error reads like a broken
  > toolchain rather than a missing include.

- [ ] **`src/bin/CMakeLists.txt`** — drop the `PRIVATE argparse` /
      `PRIVATE fmt::fmt-header-only` lines for whatever you stopped using.
      (The fmt target is `fmt::fmt-header-only`, not `fmt::fmt`.)
- [ ] **`src/lib/lib.cpp`** — replace it, and rename `namespace template_lib`.
- [ ] **`src/lib/CMakeLists.txt` — pick one.** Keep the compiled `STATIC` target,
      or delete it and uncomment the header-only `INTERFACE` variant below it.
      Delete the one you did not pick.

  > The template ships both on purpose, as a worked example of each. Your project
  > should ship the one it uses.

- [ ] **Link the library.** Nothing currently links `${PROJECT_NAME}::lib` — not
      the binary, not the tests. Add `PRIVATE ${PROJECT_NAME}::lib` to
      `src/bin/CMakeLists.txt` and to any test that needs it, or the code you put
      in `src/lib/` will not be reachable from `main()`.

  > Being fixed upstream in CT-09 (#10). Until that lands it is yours to wire.

---

## Step 3 — Prune the dependencies

- [ ] Edit the **contents** of the `${PROJECT_NAME}_DEPS` list at `CMakeLists.txt:34-38`.

  > `${PROJECT_NAME}_DEPS` looks like a placeholder you are supposed to fill in.
  > It is not — `${PROJECT_NAME}` expands on its own. Change the names *inside*
  > the list; leave the variable name exactly as it is.

- [ ] Remove `fmtlib` and `argparse` if you dropped them — **after** Step 2, or
      the build breaks on the demo's includes.
- [ ] Remove `catch2` only if you also delete `test/` or configure with
      `-D<name>_TESTS=OFF`.

> The list is the switch, not the filesystem. A recipe in `cmake/deps/` that is
> not on the list is inert, so deleting recipe files is optional tidying. The
> reverse is fatal: a name on the list with no recipe file stops configuration
> with a `FATAL_ERROR`.

---

## Step 4 — Prune the tests

- [ ] Delete `test/01example/`, `test/02example/`, `test/10example/`.

  > `01example` and `10example` are byte-identical factorial demos. `02example`
  > is the only worked example of a test that brings its own `CMakeLists.txt` —
  > read it before you delete it if you will ever need custom build control.

- [ ] **Keep `test/main.cpp`.** It provides `main()` for every test directory
      that does not bring its own `CMakeLists.txt`.
- [ ] **Keep `test/20failure-testing/`** until you have written your own
      failure-matrix test to replace it.

  > It is doing two jobs: it is the canonical example for this repo's testing
  > philosophy, and it is the `std::expected` canary — the reason CI pins Clang
  > 20. Delete it and CI's `Install Clang` step becomes droppable, along with the
  > guarantee it was buying.

- [ ] **Keep `test/30sanitizer-smoke/`.** It is the proof that the sanitizer
      toolchains are actually engaged rather than silently no-ops.

  > ⚠ `test/CMakeLists.txt` names this directory inside `if (TARGET
  > 30sanitizer-smoke-test)`. Rename or delete the directory and that guard goes
  > inert **silently** — tests stay green and the sanitizer proof is simply gone.
  > If you rename it, update that line too. `check_artifacts.cmake` rule B4
  > catches this one for you.

- [ ] If you rename `TEMPLATE_UBSAN`, rename it in **both**
      `cmake/toolchain/undefined.cmake` and `test/30sanitizer-smoke/test.cpp` —
      or in neither.

  > A one-sided rename compiles the UBSan case out on GCC ≤ 13, and the binary
  > still exits 0. Rule B3 catches this one.

---

## Step 5 — First build, both compilers

```bash
cmake -B build && cmake --build build --parallel && ctest --test-dir build --output-on-failure

cmake -B build-clang -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain/clang.cmake \
  && cmake --build build-clang --parallel && ctest --test-dir build-clang --output-on-failure
```

- [ ] Both green.

> Run these from the repo root — the toolchain paths are relative. "Builds on
> both compilers" is the convention you are inheriting (`AGENTS.md`, "How to
> verify a change"); CI enforces it, so it is cheaper to find out now.
>
> Needs GCC 13+, or Clang 19+ with libstdc++ (any Clang with libc++). Stock
> Clang 18 on Ubuntu 24.04 cannot compile `test/20failure-testing`.

---

## Step 6 — First tag ⚠ tag, then re-configure

- [ ] `git tag -a v0.1.0 -m "v0.1.0"`
- [ ] `git push origin v0.1.0`
- [ ] `cmake -B build` again
- [ ] Confirm the configure banner reads `myproject:0.1.0 (tweak=0 dirty=0)`

> The version is read at **configure** time. Tagging does not change an existing
> build tree until you re-run `cmake -B`.
>
> The tag must look like `v1.2.3` — optionally `r`-prefixed or bare, but exactly
> three numeric components. `v1.2`, `v1.2.3.4` and `v1.2.3-rc1` are rejected **by
> design**; you get `0.0.0` and a `STATUS` line saying which rule you broke.
> Until you tag anything, `0.0.0` with "no git tags reachable" is the expected,
> correct output.

---

## Step 7 — Prove it is clean

- [ ] `cmake -P cmake/check_artifacts.cmake` → prints `CLEAN`

  > It reads; it never edits. Every `FAIL` line names a file and line and maps
  > back to a step above.

- [ ] Push and confirm CI is green: 8 build/test jobs plus `version-parse-selftest`.
- [ ] `git rm NEW_PROJECT.md && git commit -m "Bootstrap complete"`

  > Last step on purpose. Deleting this file flips `check_artifacts.cmake` out of
  > template mode, and from the next configure your test suite gains an
  > `artifact-check` test that fails if any template leftover ever reappears.

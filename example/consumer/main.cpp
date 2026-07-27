// A downstream project, in miniature. Its whole job is to prove that this
// template's library can be *consumed* — the same way a real project would use
// it, and identically across all three acquisition modes (see verify.sh).
//
// It prints the project name so the caller can check it, which is what makes
// this a link test rather than a compile test: version_string() is declared in
// the public header and defined in the library's translation unit, so a build
// that gets the include directory but not the archive fails at link. That
// distinction is the reason include/lib.hpp exists at all — a header of pure
// constexpr would compile and "pass" while linking nothing.

#include <lib.hpp>

#include <cstdio>

// The library advertises cxx_std_23 as a PUBLIC usage requirement, so a
// consumer inherits it even though it never set CMAKE_CXX_STANDARD and never
// used this project's toolchain files. Delete that line from
// src/lib/CMakeLists.txt and this is what goes red.
static_assert(__cplusplus >= 202302L,
              "the library's cxx_std_23 usage requirement did not reach the consumer");

auto main() -> int {
  std::printf("%s\n", template_lib::version_string());

  // A second call, through the other half of the public API, so the check is
  // not one symbol wide.
  return template_lib::version_at_least(0, 0, 0) ? 0 : 1;
}

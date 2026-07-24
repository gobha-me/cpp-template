add_test(NAME startup COMMAND ${CMAKE_CURRENT_LIST_DIR}/../cmake/startup.sh)
add_test(NAME shutdown COMMAND ${CMAKE_CURRENT_LIST_DIR}/../cmake/shutdown.sh)

# Pure cmake -P unit test for the git-describe version parser (cmake/version_parse.cmake).
# Registered standalone — it is a script, not a `<dir>-test` executable, so it must
# not go through the auto-discovery foreach below. No fixtures: it has no runtime deps.
add_test(
  NAME version-parse-selftest
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/cmake/version_selftest.cmake
)

# Leftover-template-artifact check (cmake/check_artifacts.cmake), also standalone.
# The mode is keyed on NEW_PROJECT.md, whose last checklist step is "delete this
# file": while it exists we are the template, so the Class-A rules are inverted
# and assert each still MATCHES something (a rule that matches nothing has rotted
# and would wave every fork through). Once a bootstrapped project deletes it, the
# same script becomes a plain enforcement check with nothing to wire up.
if (EXISTS ${CMAKE_SOURCE_DIR}/NEW_PROJECT.md)
  add_test(
    NAME artifact-check-selftest
    COMMAND ${CMAKE_COMMAND} -DMODE=selftest -P ${CMAKE_SOURCE_DIR}/cmake/check_artifacts.cmake
  )
else ()
  add_test(
    NAME artifact-check
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/cmake/check_artifacts.cmake
  )
endif ()

file(GLOB TEST_DIRS ${CMAKE_CURRENT_LIST_DIR}/*)

foreach(TEST_DIR ${TEST_DIRS})
  cmake_path(GET TEST_DIR FILENAME TEST_NAME_PATH)
  set(TEST_NAME ${TEST_NAME_PATH}-test)

  # Recompute the source list for THIS dir every iteration, before the branch
  # below. Both branches consume SRCS — the custom-CMakeLists branch inherits it
  # via add_subdirectory() — so setting it only inside the elseif would leak the
  # previous iteration's sources into a custom-CMakeLists test dir.
  file(GLOB SRCS ${TEST_DIR}/*.cpp)

  if(EXISTS ${TEST_DIR}/CMakeLists.txt)
    add_subdirectory(${TEST_DIR})
  elseif (EXISTS ${TEST_DIR}/test.cpp)
    message(STATUS "Configuring test setup ${TEST_NAME}")

    add_executable(${TEST_NAME}
      main.cpp
      ${SRCS}
    )

    target_include_directories(${TEST_NAME}
      PUBLIC ${CMAKE_SOURCE_DIR}/include
      PUBLIC ${CMAKE_CURRENT_LIST_DIR}/include
    )

    target_link_libraries(${TEST_NAME}
      PRIVATE Catch2::Catch2
    )
  else()
    continue()
  endif()

  add_test(
    NAME ${TEST_NAME}
    COMMAND ${TEST_NAME} -s
  )

  set_tests_properties(${TEST_NAME} PROPERTIES FIXTURES_REQUIRED runners)
endforeach()

# SET FIXTURE DEPENDENCIES
set_tests_properties(startup PROPERTIES FIXTURES_SETUP runners)
set_tests_properties(shutdown PROPERTIES FIXTURES_CLEANUP runners)

# The sanitizer smoke test (test/30sanitizer-smoke) deliberately trips the active
# sanitizer to prove it is actually engaged (CT-03 — the whole point is to catch a
# silently no-op sanitizer toolchain). ASan/TSan abort the process on the injected
# bug, i.e. a NONZERO exit, which ctest would otherwise read as failure. So when
# such a sanitizer is active we assert on its diagnostic instead: the test passes
# iff the sanitizer's own report appears in the output. This turns "sanitizer
# engaged" into a green, enforceable signal — and if the sanitizer were ever
# silenced, the report vanishes and this test goes red. UBSan is recoverable
# (exits 0) and the default build never runs the bug, so neither needs this.
if (TARGET 30sanitizer-smoke-test)
  if (CMAKE_CXX_FLAGS MATCHES "-fsanitize=address")
    set_tests_properties(30sanitizer-smoke-test PROPERTIES PASS_REGULAR_EXPRESSION "AddressSanitizer")
  elseif (CMAKE_CXX_FLAGS MATCHES "-fsanitize=thread")
    set_tests_properties(30sanitizer-smoke-test PROPERTIES PASS_REGULAR_EXPRESSION "ThreadSanitizer")
  endif ()
endif ()

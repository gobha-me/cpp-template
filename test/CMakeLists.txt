add_test(NAME startup COMMAND ${CMAKE_CURRENT_LIST_DIR}/../cmake/startup.sh)
add_test(NAME shutdown COMMAND ${CMAKE_CURRENT_LIST_DIR}/../cmake/shutdown.sh)

# Pure cmake -P unit test for the git-describe version parser (cmake/version_parse.cmake).
# Registered standalone — it is a script, not a `<dir>-test` executable, so it must
# not go through the auto-discovery foreach below. No fixtures: it has no runtime deps.
add_test(
  NAME version-parse-selftest
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_SOURCE_DIR}/cmake/version_selftest.cmake
)

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

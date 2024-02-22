add_test(NAME startup COMMAND ${CMAKE_CURRENT_LIST_DIR}/../cmake/startup.sh)
add_test(NAME shutdown COMMAND ${CMAKE_CURRENT_LIST_DIR}/../cmake/shutdown.sh)

file(GLOB TEST_DIRS ${CMAKE_CURRENT_LIST_DIR}/*)

foreach(TEST_DIR ${TEST_DIRS})
  if (NOT EXISTS ${TEST_DIR}/test.cpp)
    continue()
  endif()

  cmake_path(GET TEST_DIR FILENAME TEST_NAME_PATH)
  set(TEST_NAME ${TEST_NAME_PATH}-test)

  message(STATUS "Configuring test setup ${TEST_NAME}")

  file(GLOB SRCS ${TEST_DIR}/*.cpp)

  add_executable(${TEST_NAME}
    main.cpp
    ${SRCS}
  )

  target_include_directories(${TEST_NAME}
    PUBLIC ${CMAKE_SOURCE_DIR}/include
    PUBLIC ${CMAKE_CURRENT_LIST_DIR}/include
  )

  add_test(
    NAME ${TEST_NAME}
    COMMAND ${TEST_NAME} -s
  )

  set_tests_properties(${TEST_NAME} PROPERTIES FIXTURES_REQUIRED runners)
endforeach()

# SET FIXTURE DEPENDENCIES
set_tests_properties(startup PROPERTIES FIXTURES_SETUP runners)
set_tests_properties(shutdown PROPERTIES FIXTURES_CLEANUP runners)

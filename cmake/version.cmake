find_package (Git)

# There are some potential business rules here
#  Ultimately the idea is to ease release and not need commits just to roll a version
# Also, when there is a version.hpp.in file, this need valid values for compile
#  which has an effect on dev build test cycle for a developer

if (GIT_FOUND)
  # Retrieve nearest tag
  execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --tags --dirty
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE GIT_RESULT
    OUTPUT_VARIABLE GIT_TAG_STR
  )

  if (GIT_RESULT AND NOT GIT_RESULT EQUAL 0)
    message(STATUS "No tags found")
  else()
    string(STRIP ${GIT_TAG_STR} GIT_TAG_STR)
    string(REGEX MATCH "^[rv]?([0-9]+(\.[0-9]+)+)(-.+)?$" CURRENT_VERSION "${GIT_TAG_STR}")

    if (CMAKE_MATCH_1)
      set(VERSION ${CMAKE_MATCH_1})
    endif()

    if (CMAKE_MATCH_3) # Use inplace of tweak?
      set(DIRTY_BRANCH ${CMAKE_MATCH_1})
    endif()
  endif()
endif (GIT_FOUND)

# I am no longer using subversion, having for a more than a few years now
#   for a while I prefered svn as a tool, the projects that I use for work
#   moved.  With that said, git is not the only tool for this.  Should I even bother
#   Supporting anything else?

if (NOT VERSION)
  set(VERSION 0.0.0.1)
endif()

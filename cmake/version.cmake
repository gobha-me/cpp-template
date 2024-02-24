find_package (Git)

# There are some potential business rules here
#  Ultimately the idea is to ease release and not need commits just to roll a version
# Also, when there is a version.hpp.in file, this need valid values for compile
#  which has an effect on dev build test cycle for a developer

if (GIT_FOUND)
  # Retrieve nearest tag
  execute_process(
    COMMAND ${GIT_EXECUTABLE} describe --tags
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE GIT_RESULT
    OUTPUT_VARIABLE GIT_TAG_STR
  )
  # AM I a tag
  #   Then what is my name and does it match expression \d+(\.\d+){0,3}
  #     Then VERSION = tag
  # else if am I a branch from a tag
  #   Then VERSION = tag.<build>
  # else if am I a branch from main/master
  #   Then VERSION = <next potential tag>? Should be a rule, bump to major, or minor
  #    May not matter as this branch is not a tagged release
endif (GIT_FOUND)

# I am no longer using subversion, having for a more than a few years now
#   for a while I prefered svn as a tool, the projects that I use for work
#   moved.  With that said, git is not the only tool for this.  Should I even bother
#   Supporting anything else?

set(VERSION 0.0.0.1)

# CPP CMake Template Project

The basic idea is have a easy button copy / paste starter for new CPP projects.
I tend to "play" around with some ideas and new features of the language
outside of "work". Cmake is the "standard" project management tool used at work,
so creating this helps for me to learn more about it. At the same time not
trying to repeat myself or needs as a new project idea comes up. I am making
this on PoPOS which has cmake 3.22 available, so that is why I choice that as
the minimum.

Some features I am baking in and assumptions that I am making.

* Auto naming, the default name is pulled directly from the parent dir of the root CMakeLists.txt file.
  * There was a note that this is a bad idea but didn't really example the details of why
  * This is an easy button starter, that "should" just work out the box, just update the project() portion of the file
* Version comes from git tags (WIP) - for some ideas see cmake/version.cmake
* Projects will default to c++20 standard, best supported ATM, this default will change
  * As a note I built clang++ 17.0.6 from source
* Tests
  * Catch2 will be used for writing tests
    * Empty fixture script for starting and stopping any services required for tests
    * this will be "baked" into the test/main.cpp and other parts of the tree
      * If anyone finds this useful, but wants to use another framework, I leave it as an exercise for them to replace
  * Tests in dir test/
    * CMakeLists loops over dirs in this path
    * to "force" order of tests prefix in ## - see example names
    * Can be as simple as test/<test_name>/test.cpp
      * This strategy makes adding tests really simple, just focus on the code of the test
      * On the other hand, if code is already built before doing so cmake -B will have to be run again
      * If need more control over the build process of a Test just add a CMakeLists.txt file in dir
* Toolchains exist in cmake/toolchain directory default is default.cmake
  * Default Build Type is Debug
  * provide seperate files to enable address or thread sanitizers
    * address.cmake
    * thread.cmake
* Dependecy Management
  * Not using a dedicating dependency manager such as conan.io
    * not using at work at the moment
    * not seeing clear and concise examples on cmake integration, so I can fit it my model above
    * trying for the moment to stay 100% cmake
  * Using combination of find_package and FetchContent for managing depenencies
    * Over time as I build new files I will most likely add them here
* Export of compile database is enabled by default

## Usage

```bash
$ cmake -B <path> [-DCMAKE_TOOLCHAIN_FILE=<toolchain file>]
...
$ cmake --build <path> --parallel 4
...
$ ctest --test-dir <path> -V
...
```

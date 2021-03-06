cmake_minimum_required(VERSION 3.10 FATAL_ERROR)

set(CMAKE_USER_MAKE_RULES_OVERRIDE ${CMAKE_SOURCE_DIR}/cmake/UserOverride.cmake)

file(STRINGS "version" LFORTRAN_VERSION)
if (LFORTRAN_VERSION MATCHES git)
    # CMake only allows integers in the version, so we use the version 0.1.1 to
    # mean an unreleased git commit
    set(LFORTRAN_VERSION "0.1.1")
endif ()

project(lfortran LANGUAGES C CXX VERSION ${LFORTRAN_VERSION})

set(CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake)

if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release
        CACHE STRING "Build type (Debug, Release)" FORCE)
endif ()
if (NOT (CMAKE_BUILD_TYPE STREQUAL "Debug" OR
        CMAKE_BUILD_TYPE STREQUAL "Release"))
    message("${CMAKE_BUILD_TYPE}")
    message(FATAL_ERROR "CMAKE_BUILD_TYPE must be one of: Debug, Release (current value: '${CMAKE_BUILD_TYPE}')")
endif ()

if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(LFORTRAN_CXX_NO_RTTI_FLAG "-fno-rtti")
elseif (CMAKE_CXX_COMPILER_ID MATCHES Clang)
    set(LFORTRAN_CXX_NO_RTTI_FLAG "-fno-rtti")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set(LFORTRAN_CXX_NO_RTTI_FLAG "/GR-")
endif ()

# build a CPack driven installer package
include(InstallRequiredSystemLibraries)
set(CPACK_GENERATOR "TBZ2")
set(CPACK_STRIP_FILES YES)
if (LFORTRAN_VERSION STREQUAL "0.1.1")
    set(CPACK_PACKAGE_FILE_NAME lfortran-git-${CMAKE_SYSTEM_NAME})
endif()
include(CPack)
# So that CPACK_PACKAGE_FILE_NAME prints the correct value below
if (LFORTRAN_VERSION STREQUAL "0.1.1")
    set(CPACK_PACKAGE_FILE_NAME lfortran-git-${CMAKE_SYSTEM_NAME})
endif()


if (NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 17
        CACHE STRING "C++ standard" FORCE)
endif ()

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    # In Debug mode we enable assertions
    set(WITH_LFORTRAN_ASSERT_DEFAULT yes)
else()
    set(WITH_LFORTRAN_ASSERT_DEFAULT no)
endif()


# LFORTRAN_ASSERT
set(WITH_LFORTRAN_ASSERT ${WITH_LFORTRAN_ASSERT_DEFAULT}
    CACHE BOOL "Enable LFORTRAN_ASSERT macro")

# LFORTRAN_STATIC_BIN
set(LFORTRAN_STATIC_BIN no CACHE BOOL "Build LFortran as a static binary")

# LLVM
set(WITH_LLVM no CACHE BOOL "Build with LLVM support")
if (WITH_LLVM)
    set(LFORTRAN_LLVM_COMPONENTS core support mcjit orcjit native asmparser asmprinter)
    find_package(LLVM REQUIRED)
    message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
    message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
    llvm_map_components_to_libnames(llvm_libs ${LFORTRAN_LLVM_COMPONENTS})
    unset(LFORTRAN_LLVM_COMPONENTS)

    add_library(p::llvm INTERFACE IMPORTED)
    set_property(TARGET p::llvm PROPERTY INTERFACE_INCLUDE_DIRECTORIES
        ${LLVM_INCLUDE_DIRS})
    #set_property(TARGET p::llvm PROPERTY INTERFACE_COMPILE_DEFINITIONS
    #    ${LLVM_DEFINITIONS})
    #set_property(TARGET p::llvm PROPERTY INTERFACE_COMPILE_OPTIONS
    #    ${LLVM_DEFINITIONS})
    set_property(TARGET p::llvm PROPERTY INTERFACE_COMPILE_OPTIONS
        $<$<COMPILE_LANGUAGE:CXX>:${LFORTRAN_CXX_NO_RTTI_FLAG}>)
    set_property(TARGET p::llvm PROPERTY INTERFACE_LINK_LIBRARIES
        ${llvm_libs})
    set(HAVE_LFORTRAN_LLVM yes)
endif()

# JSON
set(WITH_JSON no CACHE BOOL "Build with JSON support")
if (WITH_JSON)
    find_package(RapidJSON REQUIRED)
endif()

# Python
set(WITH_PYTHON no CACHE BOOL "Build with Python wrappers")
if (WITH_PYTHON)
    cmake_minimum_required(VERSION 3.12.4 FATAL_ERROR)
    find_package(Python REQUIRED COMPONENTS Interpreter Development)
endif()

enable_testing()

message("\n")
message("Configuration results")
message("---------------------")
message("CMAKE_PROJECT_VERSION: ${CMAKE_PROJECT_VERSION}")
message("CPACK_PACKAGE_FILE_NAME: ${CPACK_PACKAGE_FILE_NAME}")
message("C compiler      : ${CMAKE_C_COMPILER}")
message("C++ compiler    : ${CMAKE_CXX_COMPILER}")
message("Build type: ${CMAKE_BUILD_TYPE}")
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    message("C compiler flags      : ${CMAKE_C_FLAGS_DEBUG}")
    message("C++ compiler flags    : ${CMAKE_CXX_FLAGS_DEBUG}")
else ()
    message("C compiler flags      : ${CMAKE_C_FLAGS_RELEASE}")
    message("C++ compiler flags    : ${CMAKE_CXX_FLAGS_RELEASE}")
endif ()
message("Installation prefix: ${CMAKE_INSTALL_PREFIX}")
message("WITH_LFORTRAN_ASSERT: ${WITH_LFORTRAN_ASSERT}")
message("LFORTRAN_STATIC_BIN: ${LFORTRAN_STATIC_BIN}")
message("WITH_LLVM: ${WITH_LLVM}")
message("WITH_JSON: ${WITH_JSON}")
message("WITH_PYTHON: ${WITH_PYTHON}")


add_subdirectory(src)
if (WITH_PYTHON)
    add_subdirectory(lfortran/parser)
endif()

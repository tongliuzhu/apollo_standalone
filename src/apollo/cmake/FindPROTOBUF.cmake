#.rst:
# FindProtobuf
# ------------
#
# Locate and configure the Google Protocol Buffers library.
#
# The following variables can be set and are optional:
#
# ``PROTOBUF_SRC_ROOT_FOLDER``
#   When compiling with MSVC, if this cache variable is set
#   the protobuf-default VS project build locations
#   (vsprojects/Debug and vsprojects/Release
#   or vsprojects/x64/Debug and vsprojects/x64/Release)
#   will be searched for libraries and binaries.
# ``PROTOBUF_IMPORT_DIRS``
#   List of additional directories to be searched for
#   imported .proto files.
#
# Defines the following variables:
#
# ``PROTOBUF_FOUND``
#   Found the Google Protocol Buffers library
#   (libprotobuf & header files)
# ``PROTOBUF_INCLUDE_DIRS``
#   Include directories for Google Protocol Buffers
# ``PROTOBUF_LIBRARIES``
#   The protobuf libraries
# ``PROTOBUF_PROTOC_LIBRARIES``
#   The protoc libraries
# ``PROTOBUF_LITE_LIBRARIES``
#   The protobuf-lite libraries
#
# The following cache variables are also available to set or use:
#
# ``PROTOBUF_LIBRARY``
#   The protobuf library
# ``PROTOBUF_PROTOC_LIBRARY``
#   The protoc library
# ``PROTOBUF_INCLUDE_DIR``
#   The include directory for protocol buffers
# ``PROTOBUF_COMPILER``
#   The protoc compiler

#
# Example:
#
# .. code-block:: cmake
#
#   find_package(Protobuf REQUIRED)
#   include_directories(${PROTOBUF_INCLUDE_DIRS})
#   include_directories(${CMAKE_CURRENT_BINARY_DIR})
#   protobuf_generate_cpp(PROTO_SRCS PROTO_HDRS foo.proto)
#   add_executable(bar bar.cc PROTOSRCS{PROTO_HDRS})
#   target_link_libraries(bar ${PROTOBUF_LIBRARIES})
#
# .. note::
#   The ``protobuf_generate_cpp`` and ``protobuf_generate_python``
#   functions and :command:`add_executable` or :command:`add_library`
#   calls only work properly within the same directory.
#
# .. command:: protobuf_generate_cpp
#
#   Add custom commands to process ``.proto`` files to C++::
#
#     protobuf_generate_cpp (<SRCS> <HDRS> [<ARGN>...])
#
#   ``SRCS``
#     Variable to define with autogenerated source files
#   ``HDRS``
#     Variable to define with autogenerated header files
#   ``ARGN``
#     ``.proto`` files
#

################################################################################
########################## define functions ####################################
function(_find_protobuf_compiler)
  set(PROTOBUF_COMPILER_CANDIDATES "${PC_PROTOBUF_PREFIX}/bin/protoc")  # use protobuf.pc as hints, support local installed version only for now
  foreach(candidate ${PROTOBUF_COMPILER_CANDIDATES})
    if(EXISTS ${candidate})
      set(PROTOBUF_COMPILER ${candidate} PARENT_SCOPE)
      return()
    endif()
  endforeach()
  message(FATAL_ERROR "PROTOBUF_COMPILER_CANDIDATES:" ${PROTOBUF_COMPILER_CANDIDATES})
  message(FATAL_ERROR "Couldn't find protobuf compiler. Please ensure that protobuf(>=3.3.0 version) is properly installed to /usr/local from source. Checked the following paths: ${PROTOBUF_COMPILER_CANDIDATES}")
endfunction()



# ====================  PROTOBUF_GENERATE_CPP  ==========================
function(PROTOBUF_GENERATE_CPP SRCS HDRS)
  if(NOT ARGN)
    message(SEND_ERROR "Error: PROTOBUF_GENERATE_CPP() called without any proto files")
    return()
  endif()

  if(PROTOBUF_GENERATE_CPP_APPEND_PATH)
    # Create an include path for each file specified
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)
      list(FIND _protobuf_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
        list(APPEND _protobuf_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  else()
    # assume all .proto are in project_name/proto folder
    set(_protobuf_include_path -I ${CMAKE_CURRENT_SOURCE_DIR}/proto)
  endif()
  # create project folder devel/include/project_name/proto
  # Folder where the generated headers are installed to. This should resolve to
  # devel/include/project_name/proto

  list(APPEND _protobuf_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})


  set(${SRCS})
  set(${HDRS})
  _find_protobuf_compiler()
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)
    get_filename_component(RELT_DIR ${FIL} DIRECTORY)
    # generated the same directory structure for proto files
    #set(GENERATED_DIR "${COMPLIED_PROJ_DIR}/${RELT_DIR}")
    set(GENERATED_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

    #file(MAKE_DIRECTORY ${GENERATED_DIR})
    message(STATUS "GENERATED_DIR:" ${GENERATED_DIR})

    set(GENERATED_SRC "${GENERATED_DIR}/${FIL_WE}.pb.cc")
    set(GENERATED_HDR "${GENERATED_DIR}/${FIL_WE}.pb.h")
    message(STATUS "GENERATED_SRC:" ${GENERATED_SRC})
    message(STATUS "GENERATED_HDR:" ${GENERATED_HDR})

    list(APPEND ${SRCS} "${GENERATED_SRC}")
    list(APPEND ${HDRS} "${GENERATED_HDR}")
    set(PROTO_DIR ${CMAKE_SOURCE_DIR})
    # execute_process(
    #  COMMAND ${PROTOBUF_COMPILER} --proto_path=${PROTO_DIR} --cpp_out=${PROTO_DIR} ${ABS_FIL}
    # )
    add_custom_command(
      OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.cc"
             "${CMAKE_CURRENT_BINARY_DIR}/${FIL_WE}.pb.h"
      COMMAND  ${PROTOBUF_COMPILER}
      ARGS --cpp_out ${PROTO_DIR} ${ABS_FIL}
      DEPENDS ${ABS_FIL} ${PROTOBUF_COMPILER}
      COMMENT "Running C++ protocol buffer compiler on ${FIL}"
      VERBATIM)
  endforeach()
  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
  #install(DIRECTORY ${COMPLIED_PROJ_DIR}
  #        DESTINATION ${CATKIN_DEVEL_PREFIX}/include/
  #        FILES_MATCHING PATTERN "*.h"
  #        PATTERN ".svn" EXCLUDE
  #)
endfunction()



################################################################################
################################################################################


find_package(PkgConfig)
# use the protobuf.pc to find a suite of protobuf dirs and libs
pkg_check_modules(PC_PROTOBUF REQUIRED protobuf>=3.3.0)
# pkg_check_modules  provides variables below
# <XPREFIX>_FOUND          ... set to 1 if module(s) exist
# <XPREFIX>_LIBRARIES      ... only the libraries (w/o the '-l')
# <XPREFIX>_LIBRARY_DIRS   ... the paths of the libraries (w/o the '-L')
# <XPREFIX>_LDFLAGS        ... all required linker flags
# <XPREFIX>_LDFLAGS_OTHER  ... all other linker flags
# <XPREFIX>_INCLUDE_DIRS   ... the '-I' preprocessor flags (w/o the '-I')
# <XPREFIX>_CFLAGS         ... all required cflags
# <XPREFIX>_CFLAGS_OTHER   ... the other compiler flags

set(PROTOBUF_DEFINITIONS ${PC_PROTOBUF_CFLAGS_OTHER})
set(PROTOBUF_INCLUDE_DIRS ${PC_PROTOBUF_INCLUDE_DIRS})
set(PROTOBUF_VERSION ${PC_PROTOBUF_VERSION})
set(PROTOBUF_LIBRARIES "")
set(LIB_CANDIDATES
  "${PC_PROTOBUF_LIBRARY_DIRS}/${CMAKE_SHARED_LIBRARY_PREFIX}protobuf${CMAKE_SHARED_LIBRARY_SUFFIX}"
  "${PC_PROTOBUF_LIBRARY_DIRS}/${CMAKE_SHARED_LIBRARY_PREFIX}protoc${CMAKE_SHARED_LIBRARY_SUFFIX}"
  "${PC_PROTOBUF_LIBRARY_DIRS}/${CMAKE_SHARED_LIBRARY_PREFIX}protobuf-lite${CMAKE_SHARED_LIBRARY_SUFFIX}"
  )
foreach(LIB_CANDIDATE ${LIB_CANDIDATES})
  if(EXISTS "${LIB_CANDIDATE}")
    list(APPEND PROTOBUF_LIBRARIES ${LIB_CANDIDATE})
  endif()
endforeach()

include(FindPackageHandleStandardArgs)
# if all listed variables are TRUE
find_package_handle_standard_args(PROTOBUF DEFAULT_MSG
  PROTOBUF_LIBRARIES PROTOBUF_INCLUDE_DIRS)
mark_as_advanced(PROTOBUF_INCLUDE_DIRS PROTOBUF_LIBRARIES)

if(${PC_PROTOBUF_FOUND})
  message(STATUS "Found Protobuf Version: ${PC_PROTOBUF_VERSION} installed in" ${PC_PROTOBUF_PREFIX})
  _find_protobuf_compiler()
  message(STATUS "Found Protobuf Compiler: " ${PROTOBUF_COMPILER})
else()
  message(SEND_ERROR "Error: protobuf >= 3.3.0 not found")
endif()
set(PROTOBUF_GENERATE_CPP_APPEND_PATH true)




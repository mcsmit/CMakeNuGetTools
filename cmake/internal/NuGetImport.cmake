## Include implementation
include("${CMAKE_CURRENT_LIST_DIR}/NuGetImport.core.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/NuGetImport.single.cmake")

## Public interface. Needs to be called once before every other nuget_* command. Otherwise the
## result of those commands are all considered undefined, e.g. we might mistakenly detect the
## same nuget package registered twice but with different versions if you update the version of
## the given package in a nuget_dependencies() call.
function(nuget_init)
    _nuget_helper_get_internal_cache_variables_with_prefix(NUGET_DEPENDENCY_ NUGET_DEPENDENCY_VARIABLES)
    foreach(DEPENDENCY IN LISTS NUGET_DEPENDENCY_VARIABLES)
        unset("${DEPENDENCY}" CACHE)
    endforeach()
    set(NUGET_INITED TRUE CACHE INTERNAL "")
endfunction()

## Public interface. Needs to be macro for properly setting CMAKE_MODULE_PATH
## and CMAKE_PREFIX_PATH. It is assumed to be called from directory scope
## (or from another macro that is in dir. scope etc.).
macro(nuget_dependencies)
    # Sanity checks
    if("${NUGET_COMMAND}" STREQUAL "")
        message(WARNING "NuGetTools for CMake is disabled: doing nothing.")
        return()
    endif()
    if(NOT NUGET_INITED)
        message(FATAL_ERROR
            "NuGetTools for CMake has never been initialized before. "
            "Please call nuget_init() only once before any other nuget_*() calls."
        )
    endif()
    if("${ARGV}" STREQUAL "")
        message(FATAL_ERROR "No arguments provided.")
        return()
    endif()
    message("Importing NuGet package dependencies...")
    # Reset last registered packages list. This is about to be filled in with
    # packages registered via only this single nuget_dependencies() call.
    set(NUGET_LAST_DEPENDENCIES_REGISTERED "" CACHE INTERNAL "")
    # Process each PACKAGE argument pack one-by-one. This is a *function* call.
    _nuget_foreach_dependencies(${ARGV})
    # Foreach's loop_var should not introduce a new real variable: we are safe macro-wise.
    foreach(PACKAGE_ID IN LISTS NUGET_LAST_DEPENDENCIES_REGISTERED)
        # Set CMAKE_MODULE_PATH and CMAKE_PREFIX_PATH via a *macro* call. Since
        # nuget_dependencies() is a macro as well, no new scopes are introduced
        # between the call of nuget_dependencies() and setting those variables.
        # I.e. CMake's find_package() will respect those set variables within the
        # same scope (or below directory scopes for example).
        _nuget_core_import_cmake_exports_set_cmake_paths("${PACKAGE_ID}")
    endforeach()
    # NOTE: Make sure we did not introduce new normal variables here. Then we are safe macro-wise.
    # (NUGET_LAST_DEPENDENCIES_REGISTERED is an internal *cache* variable so that does not count.)
endmacro()

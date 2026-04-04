cmake_minimum_required(VERSION 3.16)

project(musil LANGUAGES CXX)

# ------------------------------------------------------------------------------
# Global compile definitions
# ------------------------------------------------------------------------------

add_compile_definitions(VERSION="0.51")
add_compile_definitions(COPYRIGHT="2026")

# ------------------------------------------------------------------------------
# Options
# ------------------------------------------------------------------------------

option(BUILD_MUSIL_IDE "Build Musil FLTK-based IDE" OFF)

# ------------------------------------------------------------------------------
# Subprojects
# ------------------------------------------------------------------------------

add_subdirectory(cli)

if(BUILD_MUSIL_IDE)
    add_subdirectory(ide)
endif()

# ------------------------------------------------------------------------------
# Uninstall target
#
# Important:
# - this uninstall target is intentionally standalone
# - it does NOT rely on any install_manifest.txt from FLTK or dependencies
# - it only runs our own uninstall script
# ------------------------------------------------------------------------------

configure_file(
    "${CMAKE_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
    @ONLY
)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
    COMMENT "Uninstall Musil"
)
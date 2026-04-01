# cli/CMakeLists.txt
#
# Command-line Moon interpreter.

add_executable(moon
    moon.cpp moon.h
)

# Include the core headers
target_include_directories(moon
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src
)

# C++ standard and warnings/optimizations (per-target, not global)
target_compile_features(moon PRIVATE cxx_std_17)

if (MSVC)
    target_compile_options(moon PRIVATE /W4)
else()
    target_compile_options(moon PRIVATE
        -Wall
        -g
        -O2
        -Wunused-function
        -Wno-return-type-c-linkage
    )
endif()

#
# Installation
#
# 1) Install the executable under "bin" in the install prefix.
# 2) Install .moon files into $HOME/.moon
#    and, on Unix, chown them back to the invoking user if run via sudo.
#

# Install CLI binary under ${CMAKE_INSTALL_PREFIX}/bin
install(TARGETS moon
    RUNTIME DESTINATION bin
)

# Install .scm files into ~/.moon
install(FILES
    ${CMAKE_SOURCE_DIR}/src/stdlib.moon
    DESTINATION $ENV{HOME}/.moon
)

# On Unix: if install is run with sudo, chown the .scm files to $SUDO_USER
# so the normal user can overwrite them later from the IDE.
install(CODE "
    if(NOT WIN32)
      # HOME at install time (under sudo this is usually the original user's HOME)
      set(MOON_HOME \"$ENV{HOME}\")

      # Determine the owner we want: prefer SUDO_USER if present
      if(DEFINED ENV{SUDO_USER} AND NOT \"\$ENV{SUDO_USER}\" STREQUAL \"\")
        set(MOON_OWNER \"\$ENV{SUDO_USER}\")
      else()
        execute_process(
          COMMAND whoami
          OUTPUT_VARIABLE MOON_OWNER
          OUTPUT_STRIP_TRAILING_WHITESPACE
        )
      endif()
        
      file(GLOB scm_files \"\${MOON_HOME}/.moon/*.moon\")
      foreach(f \${scm_files})
        execute_process(
          COMMAND chown \${MOON_OWNER} \"\${f}\"
        )
      endforeach()
    endif()
")

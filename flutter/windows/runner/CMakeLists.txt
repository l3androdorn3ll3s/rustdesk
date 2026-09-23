cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_desktop.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

function(remote_support_brand_define name fallback)
  if(DEFINED ENV{${name}} AND NOT "$ENV{${name}}" STREQUAL "")
    set(value "$ENV{${name}}")
  else()
    set(value "${fallback}")
  endif()
  string(REPLACE "\"" "\\\"" value "${value}")
  target_compile_definitions(${BINARY_NAME} PRIVATE "${name}=\\\"${value}\\\"")
endfunction()

remote_support_brand_define(REMOTE_SUPPORT_BRAND_COMPANY_NAME "IdealSecurity")
remote_support_brand_define(REMOTE_SUPPORT_BRAND_PRODUCT_NAME "IdealSecurity Remote Support")
remote_support_brand_define(REMOTE_SUPPORT_BRAND_FILE_DESCRIPTION "IdealSecurity Remote Support")
remote_support_brand_define(
  REMOTE_SUPPORT_BRAND_WINDOWS_ICON
  "resources/app_icon.ico"
)
# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

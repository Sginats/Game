cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

set(BINARY_NAME "ai_evolution")
set(APPLICATION_ID "com.aievolution.ai_evolution")

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

add_subdirectory(flutter)

add_subdirectory(runner)

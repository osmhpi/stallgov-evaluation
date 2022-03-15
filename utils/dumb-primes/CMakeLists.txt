# CMake version
cmake_minimum_required(VERSION 3.13.0 FATAL_ERROR)

# Declare project
project(dumb-primes C CXX)

set(CMAKE_DEBUG_POSTFIX "d")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Threads REQUIRED)

add_executable(${PROJECT_NAME} dumb-primes.cpp)
target_link_libraries(${PROJECT_NAME} Threads::Threads)

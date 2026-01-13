#=============================================================================
# AlgorithmLab CMake Configuration
#=============================================================================
cmake_minimum_required(VERSION 3.16)
project(AlgorithmLab LANGUAGES CXX)

#=============================================================================
# 基础编译配置
#=============================================================================
# 设置C++标准为20
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)  # 禁用编译器扩展，保持标准一致性

# 默认编译模式为Debug，除非手动指定
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type (Debug, Release)" FORCE)
    message(STATUS "Build type not specified, defaulting to Debug")
endif()

# 检查构建类型是否有效
set(VALID_BUILD_TYPES Debug Release)
list(FIND VALID_BUILD_TYPES ${CMAKE_BUILD_TYPE} BUILD_TYPE_INDEX)
if(BUILD_TYPE_INDEX EQUAL -1)
    message(FATAL_ERROR 
        "INVALID_BUILD_TYPE: '${CMAKE_BUILD_TYPE}' is not a valid build type.\n"
        "Valid options: ${VALID_BUILD_TYPES}"
    )
endif()

#=============================================================================
# 核心参数控制
#=============================================================================
# 必须通过 -DPROB=zoj_1001 传入当前题目名称
if(NOT PROB)
    message(FATAL_ERROR 
        "PROBLEM_NOT_SPECIFIED: You must specify a problem folder.\n"
        "Usage: cmake -S . -B /tmp/build -DPROB=<problem_name>\n"
        "Example: cmake -S . -B /tmp/build -DPROB=zoj_1001"
    )
endif()

# 验证题目目录是否存在
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${PROB}")
    message(FATAL_ERROR 
        "PROBLEM_DIR_NOT_FOUND: Problem directory '${PROB}' does not exist.\n"
        "Expected path: ${CMAKE_CURRENT_SOURCE_DIR}/${PROB}"
    )
endif()

#=============================================================================
# 路径定义
#=============================================================================
# 题目源文件目录
set(PROB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${PROB}")

# 公共算法库目录
set(COMMON_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/common")

#=============================================================================
# 依赖查找
#=============================================================================
# 自动查找Docker容器中预装的GoogleTest
find_package(GTest REQUIRED)
message(STATUS "GoogleTest: ${GTEST_FOUND}")

#=============================================================================
# 目标定义
#=============================================================================
# 扫描题目目录下的所有C++源文件
file(GLOB_RECURSE PROB_SOURCES 
    "${PROB_DIR}/*.cpp"
)

# 检查是否有源文件
list(LENGTH PROB_SOURCES NUM_SOURCES)
if(NUM_SOURCES EQUAL 0)
    message(FATAL_ERROR "No C++ source files found in ${PROB_DIR}")
endif()

message(STATUS "Source files found: ${NUM_SOURCES}")
foreach(src_file ${PROB_SOURCES})
    message(STATUS "  - ${src_file}")
endforeach()

# 创建可执行文件
add_executable(${PROB}_test ${PROB_SOURCES})
set_target_properties(${PROB}_test PROPERTIES 
    OUTPUT_NAME "solution_test"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)

#=============================================================================
# 包含路径配置
#=============================================================================
# 1. 当前题目目录
# 2. 公共算法库目录
target_include_directories(${PROB}_test PRIVATE 
    ${PROB_DIR}
    ${COMMON_LIB_DIR}
)

#=============================================================================
# 编译选项配置
#=============================================================================
# 通用警告选项（适用于所有构建类型）
set(COMMON_WARNING_FLAGS 
    "-Wall"
    "-Wextra"
    "-Wshadow"
    "-Wconversion"
    "-Wsign-conversion"
    "-Werror"  # 将警告视为错误
)

# 根据构建类型设置优化和调试选项
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    # Release模式：最大化性能
    target_compile_options(${PROB}_test PRIVATE 
        ${COMMON_WARNING_FLAGS}
        "-O3"               # 最高优化级别
        "-DNDEBUG"          # 禁用assert
        "-march=native"     # 针对当前CPU优化
    )
    
    # Release模式链接选项
    target_link_options(${PROB}_test PRIVATE 
        "-flto"             # 链接时优化
    )
    
    # 禁用调试符号以减小体积（可选）
    # set(CMAKE_BUILD_TYPE "Release" CACHE STRING "" FORCE)
    
else()  # Debug模式
    # Debug模式：最大化调试能力
    target_compile_options(${PROB}_test PRIVATE 
        ${COMMON_WARNING_FLAGS}
        "-O0"               # 禁用优化
        "-g"                # 生成调试信息
        "-ggdb"             # 生成GDB友好调试信息
        "-fno-omit-frame-pointer"  # 保留帧指针
    )
    
    # Debug模式链接选项
    target_link_options(${PROB}_test PRIVATE 
        # 可以添加调试专用的链接选项
    )
endif()

#=============================================================================
# Sanitizer配置（独立于构建类型）
#=============================================================================
# 定义三个独立的Sanitizer选项

# Sanitizer 模式选择
# 0: 关闭所有Sanitizer (默认)
# 1: 仅启用AddressSanitizer (ASan)
# 2: 仅启用UndefinedBehaviorSanitizer (UBSan)
# 3: 仅启用ThreadSanitizer (TSan)
# 4: 同时启用ASan和UBSan (推荐组合)
set(SANITIZER_MODE 0 CACHE STRING 
    "Sanitizer mode: 0=None, 1=ASan, 2=UBSan, 3=TSan, 4=ASan+UBSan"
)

option(ENABLE_ADDRESS_SANITIZER "Enable AddressSanitizer (ASan) for memory error detection" OFF)
option(ENABLE_UNDEFINED_SANITIZER "Enable UndefinedBehaviorSanitizer (UBSan) for undefined behavior detection" OFF)
option(ENABLE_THREAD_SANITIZER "Enable ThreadSanitizer (TSan) for data race detection" OFF)

if(SANITIZER_MODE EQUAL 1)        # ASan
    set(ENABLE_ADDRESS_SANITIZER ON)
elseif(SANITIZER_MODE EQUAL 2)    # UBSan
    set(ENABLE_UNDEFINED_SANITIZER ON)
elseif(SANITIZER_MODE EQUAL 3)    # TSan
    set(ENABLE_THREAD_SANITIZER ON)
elseif(SANITIZER_MODE EQUAL 4)    # ASan+UBSan
    set(ENABLE_ADDRESS_SANITIZER ON)
    set(ENABLE_UNDEFINED_SANITIZER ON)
endif()

# 检查Sanitizer兼容性
set(SANITIZER_FLAGS "")
set(SANITIZER_LINK_FLAGS "")

if(ENABLE_ADDRESS_SANITIZER)
    list(APPEND SANITIZER_FLAGS "-fsanitize=address")
    list(APPEND SANITIZER_LINK_FLAGS "-fsanitize=address")
    message(STATUS "AddressSanitizer (ASan): Enabled")
endif()

if(ENABLE_UNDEFINED_SANITIZER)
    list(APPEND SANITIZER_FLAGS "-fsanitize=undefined")
    list(APPEND SANITIZER_LINK_FLAGS "-fsanitize=undefined")
    message(STATUS "UndefinedBehaviorSanitizer (UBSan): Enabled")
endif()

if(ENABLE_THREAD_SANITIZER)
    list(APPEND SANITIZER_FLAGS "-fsanitize=thread")
    list(APPEND SANITIZER_LINK_FLAGS "-fsanitize=thread")
    message(STATUS "ThreadSanitizer (TSan): Enabled")
endif()

# 应用Sanitizer选项
if(SANITIZER_FLAGS)
    # 确保启用了帧指针（对某些Sanitizer是必须的）
    list(APPEND SANITIZER_FLAGS "-fno-omit-frame-pointer")
    
    # 添加编译选项
    target_compile_options(${PROB}_test PRIVATE ${SANITIZER_FLAGS})
    
    # 添加链接选项
    target_link_options(${PROB}_test PRIVATE ${SANITIZER_LINK_FLAGS})
    
    # 警告：在Release模式下使用Sanitizer会有性能开销
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        message(WARNING 
            "Sanitizers are enabled in Release mode.\n"
            "This will significantly impact performance. Consider using Debug mode for sanitizer testing."
        )
    endif()
endif()

#=============================================================================
# 链接库配置
#=============================================================================
# 链接GoogleTest框架
target_link_libraries(${PROB}_test PRIVATE 
    GTest::gtest
    GTest::gtest_main
    GTest::gmock  # 如果使用Google Mock
)

# 如果使用pthread，确保链接
find_package(Threads REQUIRED)
target_link_libraries(${PROB}_test PRIVATE Threads::Threads)

#=============================================================================
# 自动化安装与安全验证
#=============================================================================
# 确保目标目录存在
file(MAKE_DIRECTORY "${COMMON_LIB_DIR}")

# 安装脚本（用于CMake的install命令）
install(CODE "
    
    # 源文件和目标文件路径
    set(SRC_FILE \"${PROB_DIR}/solution.hpp\")
    set(DEST_FILE \"${COMMON_LIB_DIR}/${PROB}.hpp\")
    # 1. 检查源文件是否存在
    if(NOT EXISTS \"\${SRC_FILE}\")
        message(FATAL_ERROR \"FILE_NOT_FOUND: \${SRC_FILE} does not exist\")
    endif()
    
    file(MAKE_DIRECTORY \"${COMMON_LIB_DIR}\")
    
    # 5. 复制并重命名文件
    file(COPY \"\${SRC_FILE}\" DESTINATION \"${COMMON_LIB_DIR}\")
    file(RENAME \"${COMMON_LIB_DIR}/solution.hpp\" \"\${DEST_FILE}\")
    # 6. 验证复制结果
    if(EXISTS \"\${DEST_FILE}\")
        file(SIZE \"\${DEST_FILE}\" FILE_SIZE)
        message(STATUS \"Library installed: ${PROB}.hpp (${FILE_SIZE} bytes)\")
    else()
        message(WARNING \"File may not have been copied correctly: \${DEST_FILE}\")
    endif()
")
#=============================================================================
# 测试配置
#=============================================================================
# 启用测试功能
enable_testing()

# 添加测试用例
add_test(
    NAME ${PROB}_test
    COMMAND ${CMAKE_BINARY_DIR}/bin/solution_test
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)

# 设置测试属性
set_tests_properties(${PROB}_test PROPERTIES
    TIMEOUT 30  # 设置30秒超时
    LABELS "algorithm"  # 为测试添加标签
)

#=============================================================================
# 配置摘要输出
#=============================================================================
message(STATUS "")
message(STATUS "=" * 70)
message(STATUS "AlgorithmLab Configuration Summary")
message(STATUS "=" * 70)
message(STATUS "Project Name:          ${PROJECT_NAME}")
message(STATUS "C++ Standard:          ${CMAKE_CXX_STANDARD}")
message(STATUS "Target Problem:        ${PROB}")
message(STATUS "Problem Directory:     ${PROB_DIR}")
message(STATUS "Build Type:            ${CMAKE_BUILD_TYPE}")
message(STATUS "Common Library Dir:    ${COMMON_LIB_DIR}")
message(STATUS "Source Files:          ${NUM_SOURCES} file(s)")
message(STATUS "Output Directory:      ${CMAKE_BINARY_DIR}/bin")

# 显示编译器信息
message(STATUS "Compiler:              ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}")

# 显示优化级别
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    message(STATUS "Optimization Level:    O3 (Maximum)")
    message(STATUS "Debug Symbols:         Disabled")
else()
    message(STATUS "Optimization Level:    O0 (None)")
    message(STATUS "Debug Symbols:         Enabled")
endif()

# 显示Sanitizer状态
set(SANITIZER_MODE_NAME "None")
if(SANITIZER_MODE EQUAL 1)
    set(SANITIZER_MODE_NAME "ASan")
elseif(SANITIZER_MODE EQUAL 2)
    set(SANITIZER_MODE_NAME "UBSan")
elseif(SANITIZER_MODE EQUAL 3)
    set(SANITIZER_MODE_NAME "TSan")
elseif(SANITIZER_MODE EQUAL 4)
    set(SANITIZER_MODE_NAME "ASan+UBSan")
endif()

message(STATUS "Sanitizer Mode:       ${SANITIZER_MODE_NAME} (Mode ${SANITIZER_MODE})")

message(STATUS "GoogleTest:            Found")
message(STATUS "=" * 70)
message(STATUS "")

#=============================================================================
# 使用说明
#=============================================================================
message(STATUS "Build Commands:")
message(STATUS "  Build:                cmake --build ${CMAKE_BINARY_DIR}")
message(STATUS "  Run Tests:            ctest --test-dir ${CMAKE_BINARY_DIR}")
message(STATUS "  Run Executable:       ${CMAKE_BINARY_DIR}/bin/solution_test")
message(STATUS "")
message(STATUS "Clean Build:           rm -rf ${CMAKE_BINARY_DIR} && cmake -S . -B ${CMAKE_BINARY_DIR} -DPROB=${PROB}")

macro(__target_zig VAR TARGET)
    set(${VAR} zig-${TARGET})
endmacro()

macro(__target_zig_target VAR TARGET)
    set(${VAR} target-zig-${TARGET})
endmacro()

# this is 5Head trust me
# the 5Head zone
# -------------------------------------------------------------------------------------
function(__target_zig_build_arg_file VAR TARGET)
    __target_zig_target(ZIG_TARGET ${TARGET})
    set(${VAR} ${ZIG_TARGET}-build_runner.sh PARENT_SCOPE)
endfunction()

function(__target_zig_build_arg_init TARGET)
    __target_zig_target(ZIG_TARGET ${TARGET})
    add_custom_target(${ZIG_TARGET}_args)

    __target_zig_build_arg_file(ARGS_FILE ${TARGET})
    add_custom_command(TARGET ${ZIG_TARGET}_args PRE_BUILD
        # if you're using this, you are definitely linking to libc anyway.
        COMMAND ${CMAKE_COMMAND} -E echo_append "zig build-obj -lc " > ${ARGS_FILE}
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
        )
endfunction()

function(__target_zig_build_arg TARGET)
    __target_zig_target(ZIG_TARGET ${TARGET})
    if (NOT TARGET ${ZIG_TARGET}_args)
        message(FATAL_ERROR "${ZIG_TARGET}_args not defined!")
        return()
    endif()

    __target_zig_build_arg_file(ARGS_FILE ${TARGET})

    set(arg_list "${ARGN}")
    foreach(arg_i ${arg_list})
        string(APPEND ARGS " ${arg_i}")
    endforeach()

    add_custom_command(TARGET ${ZIG_TARGET}_args POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo_append ${ARGS} >> ${ARGS_FILE}
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
        )
endfunction()
# -------------------------------------------------------------------------------------

function(target_zig_source TARGET SOURCE_PATH)
    if(NOT SOURCE_PATH)
        message(FATAL_ERROR "No source zig file given!")
    endif()

    __target_zig(OUTPUT_NAME ${TARGET})
    set(OUTPUT_FILE ${PROJECT_BINARY_DIR}/${OUTPUT_NAME}.o)

    # tell cmake it's a generated C object
    set_source_files_properties(
        ${OUTPUT_FILE}
        PROPERTIES
        EXTERNAL_OBJECT true
        LANGUAGE C
        GENERATED true
        )

    # create argument collector target
    __target_zig_build_arg_init(${TARGET})
    __target_zig_build_arg_file(ARGS_FILE ${TARGET})
    __target_zig_build_arg(${TARGET} ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE_PATH})
    __target_zig_build_arg(${TARGET} --name ${OUTPUT_NAME})
    __target_zig_build_arg(${TARGET})

    # build command
    add_custom_command(
        OUTPUT ${PROJECT_BINARY_DIR}/${OUTPUT_NAME}.o
        COMMAND sh ${ARGS_FILE}
        DEPENDS ${SOURCE_PATH}
        COMMENT "Building Zig object '${OUTPUT_NAME}.o'"
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
        )

    # ensure command is called during compilation
    __target_zig_target(ZIG_TARGET ${TARGET})
    add_custom_target(${ZIG_TARGET}
        DEPENDS ${ZIG_TARGET}_args ${OUTPUT_FILE}
        )
    add_dependencies(${TARGET} ${ZIG_TARGET})
    target_sources(${TARGET}
        PRIVATE
        ${OUTPUT_FILE}
        )
endfunction()

function(target_zig_crosstarget TARGET ZIGTARGET ZIGMCPU)
    __target_zig_build_arg(${TARGET} -target ${ZIGTARGET})
    if (ZIGMCPU)
        __target_zig_build_arg(${TARGET} -mcpu=${ZIGMCPU})
    endif()
endfunction()

function(target_zig_add_module TARGET NAME ROOT_SRC)
    __target_zig_build_arg(${TARGET}
        --pkg-begin ${NAME} ${CMAKE_CURRENT_SOURCE_DIR}/${ROOT_SRC} --pkg-end
        )
endfunction()

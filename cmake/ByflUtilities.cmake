############################################################################
# This file defines some helper functions needed by the Byfl build process #
############################################################################

# =============================================================================
# Wrap execute_process with actions appropriate to the Byfl build process.
#
# Required keyword arguments: OUTPUT_VARIABLE MESSAGE COMMAND
# =============================================================================
function(set_var_to_process_output)
  # Parse the function options.
  set(oneValueArgs OUTPUT_VARIABLE MESSAGE)
  set(multiValueArgs COMMAND)
  cmake_parse_arguments(PARSE_ARGV 0 EXEC "" "${oneValueArgs}" "${multiValueArgs}")

  # Execute the command.
  message(STATUS ${EXEC_MESSAGE})
  execute_process(COMMAND ${EXEC_COMMAND}
    RESULT_VARIABLE _exec_result
    OUTPUT_VARIABLE _exec_output
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET)

  # Set the output variable only if the command succeeded.
  if (_exec_result EQUAL 0)
    message(STATUS "${EXEC_MESSAGE} - ${_exec_output}")
    set(${EXEC_OUTPUT_VARIABLE} ${_exec_output} PARENT_SCOPE)
  else (_exec_result EQUAL 0)
    message(STATUS "${EXEC_MESSAGE} - failed")
  endif (_exec_result EQUAL 0)
endfunction(set_var_to_process_output)

# =============================================================================
# Determine if the system can handle weak function aliases.  (At the
# time of this writing, OS X cannot.)  If so, define HAVE_WEAK_ALIASES.
# =============================================================================
function(check_weak_aliases)
  # Construct a test file.
  set(_msg "Detecting if weak function aliases are supported")
  message(STATUS ${_msg})
  file(WRITE
    ${CMAKE_BINARY_DIR}/CMakeTmp/testWeakAliases.c
    [=[
int my_function_impl (void)
{
  return 0;
}

int my_function (void) __attribute__((weak, alias("my_function_impl")));

int main (void)
{
  return my_function();
}
]=])

  # See if the test file compiles.
  try_compile(
    _weak_okay
    ${CMAKE_BINARY_DIR}
    ${CMAKE_BINARY_DIR}/CMakeTmp/testWeakAliases.c
    )
  if (_weak_okay)
    message(STATUS "${_msg} - yes")
    set(HAVE_WEAK_ALIASES 1 PARENT_SCOPE)
  else (_weak_okay)
    message(STATUS "${_msg} - no")
  endif (_weak_okay)
endfunction(check_weak_aliases)

# =============================================================================
# Tally the number of LLVM opcodes.  Define NUM_LLVM_OPCODES and
# NUM_LLVM_OPCODES_POW2.  For now, we hard-wire the C++ compiler with the "-E"
# option as the way to preprocess a C++ file.
# =============================================================================
function(tally_llvm_opcodes)
  # Tally the number of LLVM opcodes.
  set_var_to_process_output(
    OUTPUT_VARIABLE _llvm_opcodes
    MESSAGE "Tallying the number of LLVM opcodes"
    COMMAND ${PERL_EXECUTABLE} ${PROJECT_SOURCE_DIR}/gen_opcode2name "${CMAKE_CXX_COMPILER} ${CMAKE_CXX_FLAGS} -E" NUM
    )
    if (NOT _llvm_opcodes)
      message(FATAL_ERROR "Cannot continue without knowing the number of LLVM opcodes.")
    endif (NOT _llvm_opcodes)
    set(NUM_LLVM_OPCODES ${_llvm_opcodes} PARENT_SCOPE)

    # Round the number of LLVM opcodes up to a power of two.
  set_var_to_process_output(
    OUTPUT_VARIABLE _llvm_opcodes_2
    MESSAGE "Rounding up the number of LLVM opcodes to a power of two"
    COMMAND ${PERL_EXECUTABLE} ${PROJECT_SOURCE_DIR}/gen_opcode2name "${CMAKE_CXX_COMPILER} ${CMAKE_CXX_FLAGS} -E" NUM_POW2
    )
    if (NOT _llvm_opcodes_2)
      message(FATAL_ERROR "Cannot continue without knowing the number of LLVM opcodes.")
    endif (NOT _llvm_opcodes_2)
    set(NUM_LLVM_OPCODES_POW2 ${_llvm_opcodes_2} PARENT_SCOPE)
endfunction(tally_llvm_opcodes)

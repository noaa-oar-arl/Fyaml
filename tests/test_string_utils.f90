!> \file test_string_utils.f90
!! \brief Test string utility functions

program test_string_utils
    use fyaml
    use test_utils
    implicit none

    call print_test_header("String Utilities")

    call test_boolean_array_parsing()
    call test_string_array_parsing()
    call test_comment_trimming()
    call test_first_char_position()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_boolean_array_parsing()
        character(len=*), parameter :: bool_string = "true,false,T,F,.true.,.false."
        logical, allocatable :: bool_array(:)
        integer :: array_size, RC

        ! Test boolean array parsing
        call fyaml_string_to_boolean_arr(bool_string, bool_array, array_size, RC)
        call assert_equal_int(fyaml_Success, RC, "Boolean array parsing return code")
        call assert_equal_int(6, array_size, "Boolean array size")

        if (allocated(bool_array)) then
            call assert_true(bool_array(1), "First boolean (true)")
            call assert_false(bool_array(2), "Second boolean (false)")
            call assert_true(bool_array(3), "Third boolean (T)")
            call assert_false(bool_array(4), "Fourth boolean (F)")
            call assert_true(bool_array(5), "Fifth boolean (.true.)")
            call assert_false(bool_array(6), "Sixth boolean (.false.)")
            deallocate(bool_array)
        else
            call test_failed("Boolean array allocation", "Array not allocated")
        endif
    end subroutine test_boolean_array_parsing

    subroutine test_string_array_parsing()
        character(len=*), parameter :: str_string = "NO2,O3,CO,SO2,NH3"
        character(len=fyaml_NamLen), allocatable :: str_array(:)
        integer :: array_size, RC

        ! Test string array parsing
        call fyaml_string_to_string_arr(str_string, str_array, array_size, RC)
        call assert_equal_int(fyaml_Success, RC, "String array parsing return code")
        call assert_equal_int(5, array_size, "String array size")

        if (allocated(str_array)) then
            call assert_equal_string("NO2", str_array(1), "First string")
            call assert_equal_string("O3", str_array(2), "Second string")
            call assert_equal_string("CO", str_array(3), "Third string")
            call assert_equal_string("SO2", str_array(4), "Fourth string")
            call assert_equal_string("NH3", str_array(5), "Fifth string")
            deallocate(str_array)
        else
            call test_failed("String array allocation", "Array not allocated")
        endif
    end subroutine test_string_array_parsing

    subroutine test_comment_trimming()
        character(len=fyaml_StrLen) :: line

        ! Test comment trimming with #
        line = "key: value # this is a comment"
        call fyaml_trim_comment(line, "#")
        call assert_equal_string("key: value ", line, "Hash comment trimming")

        ! Test comment trimming with ;
        line = "key: value ; this is a comment"
        call fyaml_trim_comment(line, ";")
        call assert_equal_string("key: value ", line, "Semicolon comment trimming")

        ! Test multiple comment characters
        line = "key: value # comment ; more comment"
        call fyaml_trim_comment(line, "#;")
        call assert_equal_string("key: value ", line, "Multiple comment chars")

        ! Test line without comments
        line = "key: value"
        call fyaml_trim_comment(line, "#")
        call assert_equal_string("key: value", line, "No comment trimming")

        ! Test quoted strings with comment chars
        line = 'key: "value # not a comment"'
        call fyaml_trim_comment(line, "#")
        call assert_equal_string('key: "value # not a comment"', line, "Quoted string protection")
    end subroutine test_comment_trimming

    subroutine test_first_char_position()
        integer :: pos

        ! Test normal string
        pos = fyaml_first_char_pos("  hello world")
        call assert_equal_int(3, pos, "First char position with spaces")

        ! Test string with tabs
        pos = fyaml_first_char_pos(char(9)//"hello")
        call assert_equal_int(2, pos, "First char position with tab")

        ! Test string starting with non-whitespace
        pos = fyaml_first_char_pos("hello world")
        call assert_equal_int(1, pos, "First char position no leading space")

        ! Test empty string
        pos = fyaml_first_char_pos("")
        call assert_equal_int(1, pos, "First char position empty string")

        ! Test string with only whitespace
        pos = fyaml_first_char_pos("   ")
        call assert_equal_int(4, pos, "First char position only whitespace")
    end subroutine test_first_char_position

end program test_string_utils

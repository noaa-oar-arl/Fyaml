!> \file fyaml_string_utils.f90
!! \brief String manipulation utilities for FYAML
!!
!! This module provides string manipulation functions used throughout
!! the FYAML library for parsing and processing YAML content.
!!
!! \author FYAML Development Team
!! \date 2025
!! \version 1.0

module fyaml_string_utils
    use fyaml_precision, only: yp
    use fyaml_constants
    use fyaml_error, only: fyaml_handle_error
    implicit none
    private

    public :: fyaml_trim_comment, fyaml_get_fields_string, fyaml_first_char_pos
    public :: fyaml_string_to_real_arr, fyaml_string_to_integer_arr
    public :: fyaml_string_to_string_arr, fyaml_string_to_boolean_arr

contains

    !> \brief Remove comments from a line
    !!
    !! Removes everything after comment characters (# or ;) from a string
    !!
    !! \param[inout] line The string to process
    !! \param[in] comment_chars Characters that start comments
    subroutine fyaml_trim_comment(line, comment_chars)
        character(len=*), intent(inout) :: line
        character(len=*), intent(in)    :: comment_chars

        integer :: i, j, comment_pos
        logical :: in_quotes
        character(len=1) :: quote_char

        comment_pos = 0
        in_quotes = .false.
        quote_char = ' '

        ! Scan through the line character by character
        do i = 1, len_trim(line)
            ! Check if we're entering or leaving quotes
            if ((line(i:i) == '"' .or. line(i:i) == "'") .and. .not. in_quotes) then
                in_quotes = .true.
                quote_char = line(i:i)
            else if (line(i:i) == quote_char .and. in_quotes) then
                in_quotes = .false.
                quote_char = ' '
            else if (.not. in_quotes) then
                ! Check for comment characters only when not in quotes
                do j = 1, len(comment_chars)
                    if (line(i:i) == comment_chars(j:j)) then
                        comment_pos = i
                        exit
                    end if
                end do
                if (comment_pos > 0) exit
            end if
        end do

        ! Trim the comment if found
        if (comment_pos > 0) then
            line = line(1:comment_pos-1)
        end if
    end subroutine fyaml_trim_comment

    !> \brief Parse delimited fields from a string
    !!
    !! Finds the starting and ending indices of delimited fields in a string
    !!
    !! \param[in] line The input string to parse
    !! \param[in] delims Delimiter characters
    !! \param[in] brackets Bracket characters to remove
    !! \param[out] ixs_start Starting indices of fields
    !! \param[out] ixs_end Ending indices of fields
    !! \param[out] n_found Number of fields found
    !! \param[in] n_max Maximum number of fields to find
    subroutine fyaml_get_fields_string(line, delims, brackets, ixs_start, ixs_end, n_found, n_max)
        character(len=*), intent(in)    :: line
        character(len=*), intent(in)    :: delims
        character(len=*), intent(in)    :: brackets
        integer,          intent(out)   :: ixs_start(:)
        integer,          intent(out)   :: ixs_end(:)
        integer,          intent(out)   :: n_found
        integer,          intent(in)    :: n_max

        character(len=len(line)) :: line_work
        character(len=1) :: bkt
        integer :: B, ix, ix_prev

        ! Initialize
        line_work = line
        n_found = 0
        ix_prev = 0

        ! Strip out brackets from the line
        do B = 1, len(brackets)
            bkt = brackets(B:B)
            ix = index(line_work, bkt)
            if (ix > 0) line_work(ix:ix) = " "
        end do

        ! Parse the values
        ix = 0
        do while (n_found < n_max)
            ! Find the starting point of the next entry (a non-delimiter value)
            ix = verify(line_work(ix_prev+1:), delims)
            if (ix == 0) exit

            n_found = n_found + 1
            ixs_start(n_found) = ix_prev + ix ! the absolute position in line_work

            ! Get the end point of the current entry (next delimiter index minus one)
            ix = scan(line_work(ixs_start(n_found)+1:), delims) - 1

            if (ix == -1) then              ! If there is no last delimiter,
                ixs_end(n_found) = len_trim(line_work) ! then this is the last element
                exit
            else
                ixs_end(n_found) = ixs_start(n_found) + ix
            end if

            ix_prev = ixs_end(n_found)
        end do

    end subroutine fyaml_get_fields_string

    !> \brief Convert string to real array
    !!
    !! Parses a comma-delimited string into an array of real numbers
    !!
    !! \param[in] input_string Input comma-delimited string
    !! \param[out] real_arr Output real array
    !! \param[out] array_size Size of the output array
    !! \param[out] RC Return code
    !! \param[in] quiet_mode Optional flag to suppress error messages (default: true)
    subroutine fyaml_string_to_real_arr(input_string, real_arr, array_size, RC, quiet_mode)
        character(len=*), intent(in) :: input_string
        real(yp), allocatable, intent(inout) :: real_arr(:)
        integer, intent(out) :: array_size
        integer, intent(inout) :: RC
        logical, intent(in), optional :: quiet_mode

        character(len=:), allocatable :: temp_string
        character(len=1) :: delimiter
        integer :: i, start, end, count
        real(yp) :: temp_real
        character(len=fyaml_StrLen) :: errMsg, thisLoc
        logical :: is_quiet

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_string_to_real_arr (in module fyaml_string_utils.f90)'
        is_quiet = .true.  ! Default to quiet mode
        if (present(quiet_mode)) is_quiet = quiet_mode

        delimiter = ','
        count = 0
        start = 1
        temp_string = ''

        ! Count the number of commas to determine the size of the array
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter) then
                count = count + 1
            end if
        end do

        ! The number of elements is one more than the number of commas
        array_size = count + 1

        ! Deallocate if already allocated
        if (allocated(real_arr)) deallocate(real_arr)

        ! Allocate the array
        allocate(real_arr(array_size), stat=RC)
        if (RC /= fyaml_success) then
            errMsg = 'Error allocating real array'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        end if

        count = 0
        start = 1

        ! Extract each number and convert to real
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter .or. i == len_trim(input_string)) then
                if (i == len_trim(input_string)) then
                    end = i
                else
                    end = i - 1
                end if

                temp_string = input_string(start:end)
                read(temp_string, *, iostat=RC) temp_real
                if (RC /= 0) then
                    errMsg = 'Error converting string to real: ' // temp_string
                    if (.not. is_quiet) call fyaml_handle_error(errMsg, RC, thisLoc)
                    return
                end if

                real_arr(count + 1) = temp_real
                count = count + 1
                start = i + 1
            end if
        end do

    end subroutine fyaml_string_to_real_arr

    !> \brief Convert string to integer array
    !!
    !! Parses a comma-delimited string into an array of integers
    !!
    !! \param[in] input_string Input comma-delimited string
    !! \param[out] int_arr Output integer array
    !! \param[out] array_size Size of the output array
    !! \param[out] RC Return code
    !! \param[in] quiet_mode Optional flag to suppress error messages (default: true)
    subroutine fyaml_string_to_integer_arr(input_string, int_arr, array_size, RC, quiet_mode)
        character(len=*), intent(in) :: input_string
        integer, allocatable, intent(inout) :: int_arr(:)
        integer, intent(out) :: array_size
        integer, intent(inout) :: RC
        logical, intent(in), optional :: quiet_mode

        character(len=:), allocatable :: temp_string
        character(len=1) :: delimiter
        integer :: i, start, end, count
        integer :: temp_int
        character(len=fyaml_StrLen) :: errMsg, thisLoc
        logical :: is_quiet

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_string_to_integer_arr (in module fyaml_string_utils.f90)'
        is_quiet = .true.  ! Default to quiet mode
        if (present(quiet_mode)) is_quiet = quiet_mode

        delimiter = ','
        count = 0
        start = 1
        temp_string = ''

        ! Count the number of commas to determine the size of the array
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter) then
                count = count + 1
            end if
        end do

        ! The number of elements is one more than the number of commas
        array_size = count + 1

        ! Deallocate if already allocated
        if (allocated(int_arr)) deallocate(int_arr)

        ! Allocate the array
        allocate(int_arr(array_size), stat=RC)
        if (RC /= fyaml_success) then
            errMsg = 'Error allocating integer array'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        end if

        count = 0
        start = 1

        ! Extract each number and convert to integer
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter .or. i == len_trim(input_string)) then
                if (i == len_trim(input_string)) then
                    end = i
                else
                    end = i - 1
                end if

                temp_string = input_string(start:end)
                read(temp_string, *, iostat=RC) temp_int
                if (RC /= 0) then
                    errMsg = 'Error converting string to integer: ' // temp_string
                    if (.not. is_quiet) call fyaml_handle_error(errMsg, RC, thisLoc)
                    return
                end if

                int_arr(count + 1) = temp_int
                count = count + 1
                start = i + 1
            end if
        end do

    end subroutine fyaml_string_to_integer_arr

    !> \brief Convert string to string array
    !!
    !! Parses a comma-delimited string into an array of strings
    !!
    !! \param[in] input_string Input comma-delimited string
    !! \param[out] str_arr Output string array
    !! \param[out] array_size Size of the output array
    !! \param[out] RC Return code
    subroutine fyaml_string_to_string_arr(input_string, str_arr, array_size, RC)
        character(len=*), intent(in) :: input_string
        character(len=*), allocatable, intent(inout) :: str_arr(:)
        integer, intent(out) :: array_size
        integer, intent(inout) :: RC

        character(len=1) :: delimiter
        integer :: i, start, end, count, ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_string_to_string_arr (in module fyaml_string_utils.f90)'

        delimiter = ','
        count = 0
        start = 1

        ! Count the number of commas to determine the size of the array
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter) then
                count = count + 1
            end if
        end do

        ! The number of elements is one more than the number of commas
        array_size = count + 1

        ! Deallocate if already allocated
        if (allocated(str_arr)) deallocate(str_arr)

        ! Allocate the array
        allocate(str_arr(array_size), stat=RC)
        if (RC /= fyaml_success) then
            errMsg = 'Error allocating string array'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        end if

        count = 0
        start = 1

        ! Extract each string
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter .or. i == len_trim(input_string)) then
                if (i == len_trim(input_string)) then
                    end = i
                else
                    end = i - 1
                end if

                str_arr(count + 1) = trim(adjustl(input_string(start:end)))
                count = count + 1
                start = i + 1
            end if
        end do

        ! Remove leading and/or trailing quotation marks
        do i = 1, array_size
            ! Leading
            if (i > 1) then
                ix = scan(str_arr(i), '"'//"'")
                if (ix == 1) then
                    str_arr(i) = str_arr(i)(2:len(str_arr(i)))
                end if
            end if

            ! Trailing
            if (i < array_size) then
                ix = scan(str_arr(i), '"'//"'", back=.true.)
                if (ix > 0 .and. ix == len_trim(str_arr(i))) then
                    str_arr(i) = str_arr(i)(1:ix-1)
                end if
            end if
        end do

    end subroutine fyaml_string_to_string_arr

    !> \brief Convert string to boolean array
    !!
    !! Parses a comma-delimited string into an array of boolean values
    !!
    !! \param[in] input_string Input comma-delimited string
    !! \param[out] bool_arr Output boolean array
    !! \param[out] array_size Size of the output array
    !! \param[out] RC Return code
    !! \param[in] quiet_mode Optional flag to suppress error messages (default: true)
    subroutine fyaml_string_to_boolean_arr(input_string, bool_arr, array_size, RC, quiet_mode)
        character(len=*), intent(in) :: input_string
        logical, allocatable, intent(inout) :: bool_arr(:)
        integer, intent(out) :: array_size
        integer, intent(inout) :: RC
        logical, intent(in), optional :: quiet_mode

        character(len=1) :: delimiter
        integer :: i, start, end, count
        character(len=fyaml_StrLen) :: temp_string
        character(len=fyaml_StrLen) :: errMsg, thisLoc
        logical :: is_quiet

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_string_to_boolean_arr (in module fyaml_string_utils.f90)'
        is_quiet = .true.  ! Default to quiet mode
        if (present(quiet_mode)) is_quiet = quiet_mode

        delimiter = ','
        count = 0
        start = 1

        ! Count the number of commas to determine the size of the array
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter) then
                count = count + 1
            end if
        end do

        ! The number of elements is one more than the number of commas
        array_size = count + 1

        ! Deallocate if already allocated
        if (allocated(bool_arr)) deallocate(bool_arr)

        ! Allocate the array
        allocate(bool_arr(array_size), stat=RC)
        if (RC /= fyaml_success) then
            errMsg = 'Error allocating boolean array'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        end if

        count = 0
        start = 1

        ! Extract each value and convert to boolean
        do i = 1, len_trim(input_string)
            if (input_string(i:i) == delimiter .or. i == len_trim(input_string)) then
                if (i == len_trim(input_string)) then
                    end = i
                else
                    end = i - 1
                end if

                temp_string = trim(adjustl(input_string(start:end)))

                ! Convert string to boolean
                select case (trim(temp_string))
                case ('T', 't', 'true', 'True', 'TRUE', '.true.', '.T.')
                    bool_arr(count + 1) = .true.
                case ('F', 'f', 'false', 'False', 'FALSE', '.false.', '.F.')
                    bool_arr(count + 1) = .false.
                case default
                    ! Try to read as logical
                    read(temp_string, *, iostat=RC) bool_arr(count + 1)
                    if (RC /= 0) then
                        errMsg = 'Error converting string to boolean: ' // trim(temp_string)
                        if (.not. is_quiet) call fyaml_handle_error(errMsg, RC, thisLoc)
                        return
                    end if
                end select

                count = count + 1
                start = i + 1
            end if
        end do

    end subroutine fyaml_string_to_boolean_arr

    !> \brief Find position of first non-whitespace character
    !!
    !! \param[in] line Input line
    !! \return Position of first non-whitespace character
    function fyaml_first_char_pos(line) result(pos)
        character(len=*), intent(in) :: line
        integer :: pos

        pos = verify(line, ' '//tab_char)
        if (pos == 0) pos = len(line) + 1

    end function fyaml_first_char_pos

end module fyaml_string_utils

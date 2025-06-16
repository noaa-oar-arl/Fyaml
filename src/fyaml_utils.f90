!> \file fyaml_utils.f90
!! \brief Utility functions for parsing, searching, and management
!!
!! This module contains all utility functions for YAML processing including:
!! - File and line parsing
!! - Variable search and indexing
!! - Sorting algorithms
!! - Anchor handling
!! - Category management
!! - Cleanup operations
!!
!! \author FYAML Development Team
!! \date 2025
!! \version 1.0

module fyaml_utils
    use fyaml_precision, only: yp
    use fyaml_constants
    use fyaml_types
    use fyaml_error, only: fyaml_handle_error
    use fyaml_string_utils
    implicit none
    private

    ! Public interfaces
    public :: fyaml_parse_file, fyaml_parse_line
    public :: fyaml_get_var_index, fyaml_get_anchor_info
    public :: fyaml_sort_variables, fyaml_cleanup
    public :: fyaml_copy_anchor_variable
    public :: fyaml_binary_search_variable

    ! Internal module variables for parsing state
    integer,                     save :: cat_pos(fyaml_MaxStack) = 0
    integer,                     save :: cat_index = 0
    character(len=fyaml_NamLen), save :: cat_stack(fyaml_MaxStack) = ""

    ! These functions are now implemented directly in this module

contains

    !> \brief Parse a YAML file into configuration objects
    !!
    !! \param[in] fileName Name of the YAML file to parse
    !! \param[inout] yml Main configuration object
    !! \param[inout] yml_anchored Configuration object for anchored variables
    !! \param[out] RC Return code
    subroutine fyaml_parse_file(fileName, yml, yml_anchored, RC)
        character(len=*), intent(in)    :: fileName
        type(fyaml_t),   intent(inout) :: yml
        type(fyaml_t),   intent(inout) :: yml_anchored
        integer,          intent(out)   :: RC

        ! Local variables
        logical                      :: valid_syntax
        integer                      :: anchor_ix, begin_ix, end_ix
        integer                      :: I, io_state, N, line_number, my_unit
        character(len=fyaml_NamLen) :: line_fmt, category, anchor_cat
        character(len=fyaml_NamLen) :: anchor_ptr, anchor_tgt, var_pt_to_anchor
        character(len=fyaml_NamLen) :: var_w_anchor, var_name
        character(len=fyaml_StrLen) :: errMsg, line, thisLoc

        ! Initialize
        RC           = fyaml_Success
        anchor_ptr   = ""
        anchor_tgt   = ""
        category     = ""
        errMsg       = ""
        thisLoc      = " -> at fyaml_parse_file (in module fyaml_utils.f90)"
        line_number  = 0
        my_unit      = 777

        ! Open the file
        open(my_unit, file=trim(fileName), status="old", action="read", iostat=RC)
        if (RC /= fyaml_SUCCESS) then
            errMsg = 'Could not open file: ' // trim(fileName)
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        ! Create format line
        write(line_fmt, "(a,i0,a)") "(a", fyaml_StrLen, ")"

        ! Start looping through file
        do
            ! Read each line and increment the count
            read(my_unit, fmt=trim(line_fmt), err=998, end=999) line
            line_number = line_number + 1

            ! Parse each line for information
            call fyaml_parse_line(yml, yml_anchored, fyaml_set_by_file, line, &
                                 valid_syntax, category, anchor_tgt, anchor_ptr, RC)

            ! Trap potential errors
            if (.not. valid_syntax) then
                write(errMsg, *) "Cannot read line ", line_number, &
                     " from ", trim(fileName)
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        enddo

        ! Error handling
    998 write(errMsg, "(a,i0,a,i0)") " IOSTAT = ", io_state, &
             " while reading from " // trim(fileName) // " at line ", line_number
        call fyaml_handle_error(errMsg, RC, thisLoc)
        return

        ! Normal exit
    999 close(my_unit)

        ! Process anchors - YAML anchor expansion (second pass)
        do N = 1, yml_anchored%num_vars
            ! Get properties of each variable that points to an anchor
            anchor_ptr = yml_anchored%vars(N)%anchor_ptr
            category   = yml_anchored%vars(N)%category
            var_name   = yml_anchored%vars(N)%var_name

            ! Find all target variables with the given value of anchor_ptr
            call fyaml_get_anchor_info(yml, anchor_ptr, begin_ix, end_ix, anchor_cat)

            if (begin_ix > 0 .and. end_ix > 0) then
                ! Loop over all target variables containing the value of anchor_ptr
                do I = begin_ix, end_ix
                    var_w_anchor = yml%vars(I)%var_name

                    ! Variable that we want to point to the anchor
                    ! Extract the variable name part after the category separator
                    anchor_ix = index(var_w_anchor, fyaml_category_separator)
                    if (anchor_ix > 0) then
                        var_pt_to_anchor = trim(category) // fyaml_category_separator // &
                                          var_w_anchor(anchor_ix+1:)
                    else
                        var_pt_to_anchor = trim(category) // fyaml_category_separator // var_w_anchor
                    endif

                    call fyaml_copy_anchor_variable(yml, I, var_w_anchor, &
                                                   var_pt_to_anchor, RC)
                    if (RC /= fyaml_Success) then
                        errMsg = 'Error encountered in "fyaml_copy_anchor_variable"!'
                        call fyaml_handle_error(errMsg, RC, thisLoc)
                        return
                    endif
                enddo
            endif
        enddo

        ! Sort the variable names for faster search
        call fyaml_sort_variables(yml)

    end subroutine fyaml_parse_file

    !> \brief Parse a single line of YAML input
    !!
    !! \param[inout] yml Main configuration object
    !! \param[inout] yml_anchored Configuration object for anchored variables
    !! \param[in] set_by How the variable was set
    !! \param[in] line_arg Input line to parse
    !! \param[out] valid_syntax Whether the line has valid syntax
    !! \param[out] category Category name if found
    !! \param[out] anchor_ptr Anchor pointer if found
    !! \param[out] anchor_tgt Anchor target if found
    !! \param[out] RC Return code
    subroutine fyaml_parse_line(yml, yml_anchored, set_by, line_arg, valid_syntax, &
                               category, anchor_ptr, anchor_tgt, RC)
        type(fyaml_t),               intent(inout) :: yml
        type(fyaml_t),               intent(inout) :: yml_anchored
        integer,                      intent(in)    :: set_by
        character(len=*),             intent(in)    :: line_arg
        logical,                      intent(out)   :: valid_syntax
        character(len=fyaml_NamLen), intent(out)   :: category
        character(len=fyaml_NamLen), intent(out)   :: anchor_ptr
        character(len=fyaml_NamLen), intent(out)   :: anchor_tgt
        integer,                      intent(out)   :: RC

        ! Local variables
        logical                            :: append
        integer                            :: ix, ampsnd_ix, colon_ix, star_ix
        integer                            :: trim_len, pos
        character(len=fyaml_NamLen)       :: var_name
        character(len=fyaml_StrLen)       :: errMsg, line, thisLoc

        ! SAVE variables for list handling
        logical,                      save :: is_list_var = .false.
        integer,                      save :: last_pos = 0

        ! Initialize
        RC           = fyaml_Success
        colon_ix     = 0
        ampsnd_ix    = 0
        star_ix      = 0
        line         = line_arg
        valid_syntax = .true.
        errMsg       = ''
        thisLoc      = '-> at fyaml_parse_line (in module fyaml_utils.f90)'

        ! Strip all comments from the line
        call fyaml_trim_comment(line, '#;')

        ! Skip empty lines
        if (line == "" .or. line == "---") return

        ! Get the length of the line (excluding trailing whitespace)
        trim_len  = len_trim(line)

        ! Get the position of the first non-whitespace character in the line
        pos = fyaml_first_char_pos(line)

        ! Look for the positions of certain characters
        colon_ix  = index(line, ":")
        ampsnd_ix = index(line, "&")
        star_ix   = index(line, "*")

        ! Special handling for YAML sequences: Set is_list_var = F once we encounter
        ! a new category or variable
        if (is_list_var .and. line(pos:pos) /= "-") then
            is_list_var = .false.
            append = .false.
        endif

        ! If the text is flush with the first column and has a colon
        ! in the line, then it's a category or a YAML anchor
        if (line(pos:pos) /= "" .and. colon_ix > 0) then

            ! Categories: If there is nothing after the colon, then this indicates
            ! a category (without an anchor) rather than a variable
            if (colon_ix == trim_len) then
                ! Category handling logic
                call fyaml_handle_category(line, pos, colon_ix, last_pos, category, &
                                          anchor_tgt, cat_index, cat_pos, cat_stack)
                return

            ! YAML Anchors: If there is an ampersand following the colon
            ! then this denotes a YAML anchor
            else if (colon_ix > 0 .and. ampsnd_ix > 0) then
                ! Return anchor target and category name
                anchor_tgt   = line(ampsnd_ix+1:trim_len)
                category     = line(pos:colon_ix-1)
                cat_stack(1) = category
                if (category == "'NO'") category = "NO"   ! Avoid clash w/ FALSE
                last_pos     = pos
                return
            endif
        endif

        ! Variable handling
        append = .false.

        ! Special handling for YAML sequences (i.e. free lists where each element starts with -)
        if (line(pos:pos) == "-") then
            ! Set flag to denote that we are in a YAML sequence
            is_list_var = .true.

            ! Compute the variable name for the sequence
            call fyaml_get_sequence_varname(cat_index, cat_stack, category, var_name, append)

            ! Add the YAML sequence variable to the YML object
            call fyaml_add_variable_to_store(yml, append, set_by, trim(adjustl(line(pos+1:))), anchor_ptr, &
                                   anchor_tgt, category, var_name, RC)
            return
        endif

        ! Regular handling for all other variables
        append = .false.

        ! Get the variable name
        var_name = line(pos:colon_ix-1)

        ! Replace leading tabs by spaces
        ix = verify(var_name, char(9)) ! Find first non-tab character (tab = ASCII 9)
        if (ix > 1) var_name(1:ix-1) = ""

        ! Remove leading blanks
        var_name = adjustl(var_name)

        ! Determine category
        call fyaml_determine_category(pos, cat_index, cat_pos, cat_stack, category)

        ! Test if the variable is a YAML anchor
        if (var_name == "<<") then
            ! Variable points to a YAML anchor
            ! Get the name of the anchor we want to point to
            anchor_ptr = line(star_ix+1:)

            ! Create a unique variable name for this anchor reference
            ! Use the category and anchor name to make it unique
            if (category /= "") then
                var_name = trim(category) // fyaml_category_separator // "<<_" // trim(anchor_ptr)
            else
                var_name = "<<_" // trim(anchor_ptr)
            endif

            ! Add the variable to the anchored configuration object
            call fyaml_add_variable_to_store(yml_anchored, .false., set_by, line, anchor_ptr, &
                                   anchor_tgt, category, var_name, RC)

            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_add_variable_to_store" (points to anchor)!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif

        else
            ! Variable does NOT point to a YAML anchor
            if (category /= "") then
                var_name = trim(category) // fyaml_category_separator // var_name
            endif

            ! Set line to the values behind the ':' sign
            line = line(colon_ix+1:)

            ! Add the variable to the config object
            call fyaml_add_variable_to_store(yml, .false., set_by, line, anchor_ptr, &
                                   anchor_tgt, category, var_name, RC)

            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_add_variable_to_store"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        endif

    end subroutine fyaml_parse_line

    !> \brief Get the index of a variable by name
    !!
    !! \param[in] yml Configuration object
    !! \param[in] var_name Variable name to search for
    !! \param[out] ix Index of the variable (-1 if not found)
    subroutine fyaml_get_var_index(yml, var_name, ix)
        type(fyaml_t),   intent(in)  :: yml
        character(len=*), intent(in)  :: var_name
        integer,          intent(out) :: ix
        integer :: i

        ! Initialize
        ix = -1

        if (yml%sorted) then
            ! If the variable names have been sorted, use a binary search
            call fyaml_binary_search_variable(yml, var_name, ix)
        else
            ! Otherwise use a linear search
            do i = 1, yml%num_vars
                if (trim(yml%vars(i)%var_name) == trim(var_name)) then
                    ix = i
                    exit
                endif
            enddo
        endif

    end subroutine fyaml_get_var_index

    !> \brief Get information about a variable containing an anchor
    !!
    !! \param[in] yml Configuration object
    !! \param[in] anchor_ptr Name of the anchor
    !! \param[out] begin_ix Index of first variable with the anchor
    !! \param[out] end_ix Index of last variable with the anchor
    !! \param[out] anchor_cat Category of the anchor
    subroutine fyaml_get_anchor_info(yml, anchor_ptr, begin_ix, end_ix, anchor_cat)
        type(fyaml_t),               intent(in)  :: yml
        character(len=*),             intent(in)  :: anchor_ptr
        integer,                      intent(out) :: begin_ix
        integer,                      intent(out) :: end_ix
        character(len=fyaml_NamLen), intent(out) :: anchor_cat
        integer :: i

        ! Initialize
        begin_ix   = 0
        end_ix     = 0
        anchor_cat = "UNKNOWN"

        ! Linear search
        do i = 1, yml%num_vars
            if (trim(yml%vars(i)%anchor_tgt) == trim(anchor_ptr)) then
                if (begin_ix == 0) then
                    begin_ix = i
                    anchor_cat = yml%vars(i)%category
                endif
                end_ix = i
            endif
        enddo

    end subroutine fyaml_get_anchor_info

    !> \brief Sort variables for faster lookup
    !!
    !! \param[inout] yml Configuration object
    subroutine fyaml_sort_variables(yml)
        type(fyaml_t), intent(inout) :: yml

        if (yml%num_vars > 0) then
            ! Sort the list
            call fyaml_qsort(yml%vars(1:yml%num_vars))
            ! Indicate that we have sorted
            yml%sorted = .true.
        endif

    end subroutine fyaml_sort_variables

    !> \brief Clean up configuration object
    !!
    !! \param[inout] yml Configuration object to clean up
    subroutine fyaml_cleanup(yml)
        type(fyaml_t), intent(inout) :: yml
        integer :: i

        if (allocated(yml%vars)) then
            do i = 1, yml%num_vars
                if (allocated(yml%vars(i)%real_data)) deallocate(yml%vars(i)%real_data)
                if (allocated(yml%vars(i)%int_data)) deallocate(yml%vars(i)%int_data)
                if (allocated(yml%vars(i)%char_data)) deallocate(yml%vars(i)%char_data)
                if (allocated(yml%vars(i)%bool_data)) deallocate(yml%vars(i)%bool_data)
            enddo
            deallocate(yml%vars)
        endif
        yml%num_vars = 0
        yml%sorted = .false.

    end subroutine fyaml_cleanup

    !> \brief Copy a variable from anchor to new location
    !!
    !! \param[inout] yml Configuration object
    !! \param[in] anchor_ix Index of the anchor variable
    !! \param[in] var_w_anchor Variable name with anchor
    !! \param[in] var_pt_to_anchor Variable pointing to anchor
    !! \param[out] RC Return code
    subroutine fyaml_copy_anchor_variable(yml, anchor_ix, var_w_anchor, var_pt_to_anchor, RC)
        type(fyaml_t), intent(inout) :: yml
        integer, intent(in) :: anchor_ix
        character(len=*), intent(in) :: var_w_anchor, var_pt_to_anchor
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_copy_anchor_variable (in module fyaml_utils.f90)'

        ! Check if the target variable already exists
        call fyaml_get_var_index(yml, trim(var_pt_to_anchor), ix)
        if (ix /= -1) then
            ! Variable already exists, skip this copy
            return
        endif

        ! Prepare to store the data as a string
        call fyaml_prepare_store_var(yml, trim(var_pt_to_anchor), fyaml_unknown_type, &
                                    1, "Not yet created", ix, RC, .false.)

        if (RC /= fyaml_success) then
            errMsg = 'Error encountered at "fyaml_prepare_store_var"! ' // &
              '(key with anchor = "' // trim(var_w_anchor) // '")'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        ! Copy each field of the "anchor" variable to the new variable
        yml%vars(ix)%category    = yml%vars(anchor_ix)%category
        yml%vars(ix)%description = yml%vars(anchor_ix)%description
        yml%vars(ix)%var_type    = yml%vars(anchor_ix)%var_type
        yml%vars(ix)%var_size    = yml%vars(anchor_ix)%var_size
        yml%vars(ix)%set_by      = yml%vars(anchor_ix)%set_by
        yml%vars(ix)%stored_data = yml%vars(anchor_ix)%stored_data

        ! Copy anchor information
        yml%vars(ix)%anchor_ptr  = yml%vars(anchor_ix)%anchor_ptr
        yml%vars(ix)%anchor_tgt  = yml%vars(anchor_ix)%anchor_tgt

        ! Allocate and copy data arrays based on type
        select case (yml%vars(anchor_ix)%var_type)
        case (fyaml_real_type)
            if (allocated(yml%vars(anchor_ix)%real_data)) then
                allocate(yml%vars(ix)%real_data(yml%vars(anchor_ix)%var_size))
                yml%vars(ix)%real_data = yml%vars(anchor_ix)%real_data
            endif

        case (fyaml_integer_type)
            if (allocated(yml%vars(anchor_ix)%int_data)) then
                allocate(yml%vars(ix)%int_data(yml%vars(anchor_ix)%var_size))
                yml%vars(ix)%int_data = yml%vars(anchor_ix)%int_data
            endif

        case (fyaml_string_type)
            if (allocated(yml%vars(anchor_ix)%char_data)) then
                allocate(yml%vars(ix)%char_data(yml%vars(anchor_ix)%var_size))
                yml%vars(ix)%char_data = yml%vars(anchor_ix)%char_data
            endif

        case (fyaml_bool_type)
            if (allocated(yml%vars(anchor_ix)%bool_data)) then
                allocate(yml%vars(ix)%bool_data(yml%vars(anchor_ix)%var_size))
                yml%vars(ix)%bool_data = yml%vars(anchor_ix)%bool_data
            endif
        end select

    end subroutine fyaml_copy_anchor_variable

    ! ===== Private utility functions =====

    !> \brief Handle category parsing logic
    subroutine fyaml_handle_category(line, pos, colon_ix, last_pos, category, &
                                    anchor_tgt, cat_index, cat_pos, cat_stack)
        character(len=*), intent(in) :: line
        integer, intent(in) :: pos, colon_ix
        integer, intent(inout) :: last_pos, cat_index
        character(len=fyaml_NamLen), intent(out) :: category, anchor_tgt
        integer, intent(inout) :: cat_pos(:)
        character(len=fyaml_NamLen), intent(inout) :: cat_stack(:)
        integer :: indent_val

        ! If this category starts further along the line than the last
        ! category, then increment index and add its position to the stack.
        if (pos > last_pos) then
            indent_val = last_pos - pos
            cat_index = cat_index + 1
            cat_pos(cat_index) = pos
        endif

        ! If this category starts earlier along the line than the last
        ! category, then decrement index and add its position to the stack.
        if (pos < last_pos) then
            indent_val = last_pos - pos
            cat_index = cat_index - (indent_val / 2)
            if (cat_index >= 1) then
                cat_pos(cat_index) = pos
            endif
        endif

        ! If the index is negative or the category begins at the first
        ! character of the line, then set index to 1 and store its
        ! starting position in the first element of the stack.
        if (cat_index <= 0 .or. pos == 1) then
            cat_index = 1
            cat_pos(cat_index) = pos
        endif

        ! Extract the category name and add it to the stack
        anchor_tgt = ""
        category = line(pos:colon_ix-1)
        if (category == "'NO'") category = "NO"   ! Avoid clash w/ FALSE
        cat_stack(cat_index) = category

        ! Update the category starting position for the next iteration
        last_pos = pos

    end subroutine fyaml_handle_category

    !> \brief Determine category for a variable
    subroutine fyaml_determine_category(pos, cat_index, cat_pos, cat_stack, category)
        integer, intent(in) :: pos, cat_index
        integer, intent(in) :: cat_pos(:)
        character(len=fyaml_NamLen), intent(in) :: cat_stack(:)
        character(len=fyaml_NamLen), intent(out) :: category
        integer :: C, CC

        category = ""
        do C = cat_index, 1, -1
            ! If the variable starts at position 1, then it has no category.
            if (pos == 1) then
                category = ""
                exit
            endif

            ! If the variable starts beyond the highest category's
            ! starting position, then it belongs to that category.
            if (pos > cat_pos(C)) then
                category = cat_stack(C)
                if (C > 1) then
                    do CC = C-1, 1, -1
                        category = trim(cat_stack(CC)) // fyaml_Category_Separator // trim(category)
                    enddo
                endif
                exit
            endif

            ! If the variable starts at the same position as the highest
            ! category, then it belongs to the previous category
            if (pos == cat_pos(C)) then
                category = cat_stack(max(C-1, 1))
                if (C-1 > 1) then
                    do CC = C-2, 1, -1
                        category = trim(cat_stack(CC)) // fyaml_Category_Separator // trim(category)
                    enddo
                endif
                exit
            endif
        enddo

    end subroutine fyaml_determine_category

    !> \brief Get variable name for YAML sequence
    subroutine fyaml_get_sequence_varname(cat_index, cat_stack, category, var_name, append)
        integer, intent(in) :: cat_index
        character(len=fyaml_NamLen), intent(in) :: cat_stack(:)
        character(len=fyaml_NamLen), intent(out) :: category, var_name
        logical, intent(out) :: append
        integer :: C
        character(len=fyaml_NamLen), save :: last_var = ""

        ! Compute category name
        category = ""
        do C = cat_index, 1, -1
            if (C == cat_index) then
                category = cat_stack(C)
            else
                category = trim(cat_stack(C)) // fyaml_Category_Separator // trim(category)
            endif
        enddo

        ! Create the variable name
        var_name = trim(category)

        ! Check if we need to append
        append = .false.
        if (trim(var_name) == trim(last_var)) append = .true.

        ! Save for next iteration
        last_var = var_name

    end subroutine fyaml_get_sequence_varname

    ! ===== Helper functions for sorting and searching =====

    !> \brief Binary search for variable name
    subroutine fyaml_binary_search_variable(yml, var_name, ix)
        type(fyaml_t), intent(in) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(out) :: ix
        integer :: i_min, i_max, i_mid

        i_min = 1
        i_max = yml%num_vars
        ix = -1

        do while (i_min <= i_max)
            i_mid = i_min + (i_max - i_min) / 2
            if (llt(yml%vars(i_mid)%var_name, var_name)) then
                i_min = i_mid + 1
            else if (lgt(yml%vars(i_mid)%var_name, var_name)) then
                i_max = i_mid - 1
            else
                ix = i_mid
                exit
            endif
        enddo

    end subroutine fyaml_binary_search_variable

    !> \brief Quicksort algorithm for variable sorting
    recursive subroutine fyaml_qsort(list)
        type(fyaml_var_t), intent(inout) :: list(:)
        integer :: first, last
        integer :: pivot_index

        first = 1
        last = size(list)

        if (first < last) then
            call fyaml_partition(list, first, last, pivot_index)
            if (pivot_index > first) call fyaml_qsort(list(first:pivot_index-1))
            if (pivot_index < last) call fyaml_qsort(list(pivot_index+1:last))
        endif

    end subroutine fyaml_qsort

    !> \brief Partition function for quicksort
    subroutine fyaml_partition(list, first, last, pivot_index)
        type(fyaml_var_t), intent(inout) :: list(:)
        integer, intent(in) :: first, last
        integer, intent(out) :: pivot_index
        type(fyaml_var_t) :: pivot, temp
        integer :: i, j

        pivot = list(last)
        i = first - 1

        do j = first, last - 1
            if (llt(list(j)%var_name, pivot%var_name)) then
                i = i + 1
                temp = list(i)
                list(i) = list(j)
                list(j) = temp
            endif
        enddo

        temp = list(i + 1)
        list(i + 1) = list(last)
        list(last) = temp
        pivot_index = i + 1

    end subroutine fyaml_partition

    !> \brief Ensure yml object has free storage for new variables
    !!
    !! \param[inout] yml YAML configuration object
    subroutine fyaml_ensure_free_storage(yml)
        type(fyaml_t), intent(inout) :: yml

        type(fyaml_var_t), allocatable :: yml_copy(:)
        integer :: cur_size, new_size
        integer, parameter :: min_dyn_size = 100

        if (allocated(yml%vars)) then
            cur_size = size(yml%vars)

            if (cur_size < yml%num_vars + 1) then
                new_size = 2 * cur_size
                allocate(yml_copy(cur_size))
                yml_copy = yml%vars
                deallocate(yml%vars)
                allocate(yml%vars(new_size))
                yml%vars(1:cur_size) = yml_copy
                deallocate(yml_copy)
            endif
        else
            allocate(yml%vars(min_dyn_size))
        endif

    end subroutine fyaml_ensure_free_storage

    !> \brief Read variable from stored data
    !!
    !! \param[inout] var Variable to read data into
    !! \param[out] RC Return code
    subroutine fyaml_read_variable(var, RC)
        type(fyaml_var_t), intent(inout) :: var
        integer, intent(out) :: RC

        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_read_variable (in module fyaml_utils.f90)'

        ! Process based on variable type
        select case (var%var_type)
        case (fyaml_real_type)
            if (var%var_size == 1) then
                read(var%stored_data, *, iostat=RC) var%real_data(1)
            else
                call fyaml_string_to_real_arr(var%stored_data, var%real_data, var%var_size, RC)
            endif

        case (fyaml_integer_type)
            if (var%var_size == 1) then
                read(var%stored_data, *, iostat=RC) var%int_data(1)
            else
                call fyaml_string_to_integer_arr(var%stored_data, var%int_data, var%var_size, RC)
            endif

        case (fyaml_string_type)
            if (var%var_size == 1) then
                var%char_data(1) = trim(var%stored_data)
            else
                call fyaml_string_to_string_arr(var%stored_data, var%char_data, var%var_size, RC)
            endif

        case (fyaml_bool_type)
            if (var%var_size == 1) then
                read(var%stored_data, *, iostat=RC) var%bool_data(1)
            else
                call fyaml_string_to_boolean_arr(var%stored_data, var%bool_data, var%var_size, RC)
            endif

        case default
            RC = fyaml_failure
        end select

        if (RC /= fyaml_success) then
            errMsg = 'Error reading variable data from: ' // trim(var%stored_data)
            call fyaml_handle_error(errMsg, RC, thisLoc)
        endif

    end subroutine fyaml_read_variable

    !> \brief Prepare variable storage in yml object
    !!
    !! \param[inout] yml YAML configuration object
    !! \param[in] var_name Variable name
    !! \param[in] var_type Variable type
    !! \param[in] var_size Variable size
    !! \param[in] description Variable description
    !! \param[out] ix Variable index
    !! \param[out] RC Return code
    !! \param[in] dynamic_size Optional flag for dynamic sizing
    subroutine fyaml_prepare_store_var(yml, var_name, var_type, var_size, description, ix, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(in) :: var_type
        integer, intent(in) :: var_size
        character(len=*), intent(in) :: description
        integer, intent(out) :: ix
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_Success
        errMsg = ''
        thisLoc = ' -> at fyaml_prepare_store_var (in module fyaml_utils.f90)'

        ! Check if variable already exists
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix == -1) then ! Create a new variable
            call fyaml_ensure_free_storage(yml)
            yml%sorted = .false.
            ix = yml%num_vars + 1
            yml%num_vars = yml%num_vars + 1
            yml%vars(ix)%used = .false.
            yml%vars(ix)%stored_data = unstored_data_string
        else
            ! Only allowed when the variable is not yet created
            if (yml%vars(ix)%var_type /= fyaml_unknown_type) then
                errMsg = "Variable " // trim(var_name) // " already exists"
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        endif

        yml%vars(ix)%var_name = var_name
        yml%vars(ix)%description = description
        yml%vars(ix)%var_type = var_type
        yml%vars(ix)%var_size = var_size

        if (present(dynamic_size)) then
            yml%vars(ix)%dynamic_size = dynamic_size
        else
            yml%vars(ix)%dynamic_size = .false.
        endif

        select case (var_type)
        case (fyaml_INTEGER_type)
            allocate(yml%vars(ix)%int_data(var_size))
        case (fyaml_real_type)
            allocate(yml%vars(ix)%real_data(var_size))
        case (fyaml_string_type)
            allocate(yml%vars(ix)%char_data(var_size))
        case (fyaml_bool_type)
            allocate(yml%vars(ix)%bool_data(var_size))
        end select

    end subroutine fyaml_prepare_store_var

    !> \brief Add variable to YAML store
    !!
    !! \param[inout] yml YAML configuration object
    !! \param[in] append Whether to append or overwrite data
    !! \param[in] set_by Source identifier
    !! \param[in] line_arg Data line
    !! \param[in] anchor_ptr_arg Anchor pointer
    !! \param[in] anchor_tgt_arg Anchor target
    !! \param[in] category_arg Variable category
    !! \param[in] var_name_arg Variable name
    !! \param[out] RC Return code
    subroutine fyaml_add_variable_to_store(yml, append, set_by, line_arg, anchor_ptr_arg, &
                                          anchor_tgt_arg, category_arg, var_name_arg, RC)
        type(fyaml_t), intent(inout) :: yml
        logical, intent(in) :: append
        integer, intent(in) :: set_by
        character(len=*), intent(in) :: line_arg, anchor_ptr_arg, anchor_tgt_arg
        character(len=*), intent(in) :: category_arg, var_name_arg
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_add_variable_to_store (in module fyaml_utils.f90)'

        ! Find variable corresponding to name in file
        call fyaml_get_var_index(yml, var_name_arg, ix)

        if (ix <= 0) then
            ! Variable is not already present in the yml object
            ! Prepare to store the data as a string
            call fyaml_prepare_store_var(yml, trim(var_name_arg), fyaml_unknown_type, &
                                        1, "Not yet created", ix, RC, .false.)

            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif

            ! Store the value of the mapping in the "stored_data" field
            yml%vars(ix)%stored_data = trim(line_arg)

            ! Infer the type from the stored data
            call fyaml_infer_variable_type(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_infer_variable_type"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            ! Variable is already present in the yml object
            if (append) then
                ! Append data to data that is already present (use comma for YAML sequences)
                yml%vars(ix)%stored_data = trim(yml%vars(ix)%stored_data) // ',' // trim(line_arg)

                ! Re-infer type after appending (single string may become array)
                call fyaml_infer_variable_type(yml%vars(ix), RC)
                if (RC /= fyaml_Success) then
                    errMsg = 'Error encountered in "fyaml_infer_variable_type" after append!'
                    call fyaml_handle_error(errMsg, RC, thisLoc)
                    return
                endif
            else
                ! Or store overwrite existing data
                yml%vars(ix)%stored_data = line_arg
            endif

            ! If type is known, read in values
            if (yml%vars(ix)%var_type /= fyaml_unknown_type) then
                call fyaml_read_variable(yml%vars(ix), RC)
                if (RC /= fyaml_Success) then
                    errMsg = 'Error encountered in "fyaml_read_variable"!'
                    call fyaml_handle_error(errMsg, RC, thisLoc)
                    return
                endif
            endif
        endif

        ! Store other fields of this variable
        yml%vars(ix)%anchor_tgt = anchor_tgt_arg
        yml%vars(ix)%anchor_ptr = anchor_ptr_arg
        yml%vars(ix)%category = category_arg
        yml%vars(ix)%set_by = set_by

    end subroutine fyaml_add_variable_to_store

    !> \brief Infer variable type from stored data and convert it
    !!
    !! \param[inout] var Variable to infer type for
    !! \param[out] RC Return code
    subroutine fyaml_infer_variable_type(var, RC)
        type(fyaml_var_t), intent(inout) :: var
        integer, intent(out) :: RC

        character(len=fyaml_StrLen) :: trimmed_data, errMsg, thisLoc
        integer :: i, comma_count, bracket_count
        logical :: is_array, is_quoted

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_infer_variable_type (in module fyaml_utils.f90)'

        ! Get trimmed data
        trimmed_data = trim(adjustl(var%stored_data))
        if (len_trim(trimmed_data) == 0) then
            ! Empty data defaults to string
            var%var_type = fyaml_string_type
            var%var_size = 1
            allocate(var%char_data(1))
            var%char_data(1) = ""
            return
        endif

        ! Check if it's an array (contains [ ] or commas)
        bracket_count = 0
        comma_count = 0
        is_quoted = .false.

        do i = 1, len_trim(trimmed_data)
            if (trimmed_data(i:i) == '"' .or. trimmed_data(i:i) == "'") then
                is_quoted = .not. is_quoted
            else if (.not. is_quoted) then
                if (trimmed_data(i:i) == '[') bracket_count = bracket_count + 1
                if (trimmed_data(i:i) == ']') bracket_count = bracket_count - 1
                if (trimmed_data(i:i) == ',') comma_count = comma_count + 1
            endif
        end do

        is_array = (bracket_count == 0 .and. comma_count > 0) .or. &
                   (trimmed_data(1:1) == '[' .and. trimmed_data(len_trim(trimmed_data):len_trim(trimmed_data)) == ']')

        if (is_array) then
            ! Handle array types
            call fyaml_infer_array_type(var, RC)
        else
            ! Handle scalar types
            call fyaml_infer_scalar_type(var, RC)
        endif

        if (RC /= fyaml_success) then
            errMsg = 'Error inferring variable type for: ' // trim(var%stored_data)
            call fyaml_handle_error(errMsg, RC, thisLoc)
        endif

    end subroutine fyaml_infer_variable_type

    !> \brief Infer scalar variable type from stored data
    !!
    !! \param[inout] var Variable to infer type for
    !! \param[out] RC Return code
    subroutine fyaml_infer_scalar_type(var, RC)
        type(fyaml_var_t), intent(inout) :: var
        integer, intent(out) :: RC

        character(len=fyaml_StrLen) :: trimmed_data, lower_data
        integer :: ios
        real(yp) :: test_real
        integer :: test_int

        ! Initialize
        RC = fyaml_success
        trimmed_data = trim(adjustl(var%stored_data))
        lower_data = trimmed_data

        ! Convert to lowercase for boolean checking
        do ios = 1, len_trim(lower_data)
            if (lower_data(ios:ios) >= 'A' .and. lower_data(ios:ios) <= 'Z') then
                lower_data(ios:ios) = char(ichar(lower_data(ios:ios)) + 32)
            endif
        end do

        ! Check for boolean values
        if (lower_data == 'true' .or. lower_data == '.true.' .or. lower_data == 't' .or. &
            lower_data == 'false' .or. lower_data == '.false.' .or. lower_data == 'f') then
            var%var_type = fyaml_bool_type
            var%var_size = 1
            allocate(var%bool_data(1))
            if (lower_data == 'true' .or. lower_data == '.true.' .or. lower_data == 't') then
                var%bool_data(1) = .true.
            else
                var%bool_data(1) = .false.
            endif
            return
        endif

        ! Try to parse as integer
        read(trimmed_data, *, iostat=ios) test_int
        if (ios == 0) then
            ! Check if it's really an integer (no decimal point)
            if (index(trimmed_data, '.') == 0 .and. index(trimmed_data, 'e') == 0 .and. &
                index(trimmed_data, 'E') == 0) then
                var%var_type = fyaml_integer_type
                var%var_size = 1
                allocate(var%int_data(1))
                var%int_data(1) = test_int
                return
            endif
        endif

        ! Try to parse as real
        read(trimmed_data, *, iostat=ios) test_real
        if (ios == 0) then
            var%var_type = fyaml_real_type
            var%var_size = 1
            allocate(var%real_data(1))
            var%real_data(1) = test_real
            return
        endif

        ! Default to string
        var%var_type = fyaml_string_type
        var%var_size = 1
        allocate(var%char_data(1))
        ! Remove quotes if present
        if ((trimmed_data(1:1) == '"' .and. trimmed_data(len_trim(trimmed_data):len_trim(trimmed_data)) == '"') .or. &
            (trimmed_data(1:1) == "'" .and. trimmed_data(len_trim(trimmed_data):len_trim(trimmed_data)) == "'")) then
            var%char_data(1) = trimmed_data(2:len_trim(trimmed_data)-1)
        else
            var%char_data(1) = trimmed_data
        endif

    end subroutine fyaml_infer_scalar_type

    !> \brief Infer array variable type from stored data
    !!
    !! \param[inout] var Variable to infer type for
    !! \param[out] RC Return code
    subroutine fyaml_infer_array_type(var, RC)
        type(fyaml_var_t), intent(inout) :: var
        integer, intent(out) :: RC

        character(len=fyaml_StrLen) :: trimmed_data, array_content

        ! Initialize
        RC = fyaml_success
        trimmed_data = trim(adjustl(var%stored_data))

        ! Strip brackets if present
        if (trimmed_data(1:1) == '[' .and. &
            trimmed_data(len_trim(trimmed_data):len_trim(trimmed_data)) == ']') then
            ! Extract content between brackets
            array_content = trimmed_data(2:len_trim(trimmed_data)-1)
        else
            ! No brackets, use as is
            array_content = trimmed_data
        endif

        ! Trim whitespace
        array_content = trim(adjustl(array_content))

        ! For now, try to parse as different array types using existing functions
        ! Try integer array first
        var%var_type = fyaml_integer_type
        call fyaml_string_to_integer_arr(array_content, var%int_data, var%var_size, RC)
        if (RC == fyaml_success) return

        ! Try real array
        var%var_type = fyaml_real_type
        call fyaml_string_to_real_arr(array_content, var%real_data, var%var_size, RC)
        if (RC == fyaml_success) return

        ! Try boolean array
        var%var_type = fyaml_bool_type
        call fyaml_string_to_boolean_arr(array_content, var%bool_data, var%var_size, RC)
        if (RC == fyaml_success) return

        ! Default to string array
        var%var_type = fyaml_string_type
        call fyaml_string_to_string_arr(array_content, var%char_data, var%var_size, RC)

    end subroutine fyaml_infer_array_type

end module fyaml_utils

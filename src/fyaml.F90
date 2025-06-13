!> \file fyaml.f90
!! \brief Main public interface for FYAML library
!!
!! This module provides the main public interface for the FYAML library,
!! exposing all the functionality needed by users while maintaining
!! a clean and organized API.
!!
!! \author FYAML Development Team
!! \date 2025
!! \version 1.0

module fyaml
    ! Import all required modules
    use fyaml_precision, only: yp
    use fyaml_constants
    use fyaml_types, only: fyaml_t, fyaml_var_t
    use fyaml_error, only: fyaml_handle_error
    use fyaml_string_utils
    use fyaml_utils

    implicit none
    private

    ! Re-export precision
    public :: yp

    ! Re-export constants
    public :: fyaml_Success, fyaml_Failure
    public :: fyaml_MaxArr, fyaml_MaxStack, fyaml_NamLen, fyaml_StrLen
    public :: fyaml_num_types, fyaml_integer_type, fyaml_real_type
    public :: fyaml_string_type, fyaml_bool_type, fyaml_unknown_type

    ! Re-export types
    public :: fyaml_t

    ! High-level interface procedures
    public :: fyaml_init, fyaml_species_init, fyaml_emis_init
    public :: fyaml_merge, fyaml_cleanup, fyaml_print
    public :: fyaml_check, fyaml_get_size, fyaml_get_type
    public :: fyaml_find_depth, fyaml_find_next_higher, fyaml_split_category

    ! YAML parsing functions (from utils module)
    public :: fyaml_parse_file, fyaml_parse_line, fyaml_parse_species_file
    public :: fyaml_get_var_index, fyaml_sort_variables

    ! Configuration management functions
    public :: fyaml_merge_configs, fyaml_print_config

    ! Species parsing interface (overloaded)
    interface fyaml_parse_species_file
        module procedure fyaml_parse_species_file_full
        module procedure fyaml_parse_species_file_simple
    end interface fyaml_parse_species_file

    ! Legacy interface for backwards compatibility
    public :: fyaml_read_file

    ! Variable access interfaces
    public :: fyaml_add, fyaml_get, fyaml_add_get, fyaml_update

    ! Internal functions used by fyaml_utils (required for linking)
    public :: fyaml_add_variable_to_store, fyaml_prepare_store_var

    ! String utility functions
    public :: fyaml_string_to_real_arr, fyaml_string_to_integer_arr
    public :: fyaml_string_to_string_arr, fyaml_string_to_boolean_arr
    public :: fyaml_first_char_pos, fyaml_trim_comment

    ! Generic interfaces for type-safe variable operations
    interface fyaml_add
        module procedure add_real, add_real_array
        module procedure add_int, add_int_array
        module procedure add_string, add_string_array
        module procedure add_bool, add_bool_array
    end interface fyaml_add

    interface fyaml_get
        module procedure get_real, get_real_array
        module procedure get_int, get_int_array
        module procedure get_bool, get_bool_array
        module procedure get_string, get_string_array
    end interface fyaml_get

    interface fyaml_add_get
        module procedure add_get_real, add_get_real_array
        module procedure add_get_int, add_get_int_array
        module procedure add_get_bool, add_get_bool_array
        module procedure add_get_string, add_get_string_array
    end interface fyaml_add_get

    interface fyaml_update
        module procedure update_real, update_real_array
        module procedure update_int, update_int_array
        module procedure update_bool, update_bool_array
        module procedure update_string, update_string_array
    end interface fyaml_update

contains

    !> \brief Initialize FYAML from a file
    !!
    !! \param[in] fileName Name of YAML file to read
    !! \param[inout] yml Main configuration object
    !! \param[inout] yml_anchored Anchored variables object (optional)
    !! \param[out] RC Return code
    subroutine fyaml_init(fileName, yml, yml_anchored, RC)
        character(len=*), intent(in)    :: fileName
        type(fyaml_t),   intent(inout) :: yml
        type(fyaml_t),   intent(inout), optional :: yml_anchored
        integer,          intent(out)   :: RC

        type(fyaml_t) :: yml_anchored_local
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_init (in module fyaml.f90)'

        ! Use provided anchored object or local one
        if (present(yml_anchored)) then
            call fyaml_parse_file(fileName, yml, yml_anchored, RC)
        else
            call fyaml_parse_file(fileName, yml, yml_anchored_local, RC)
        end if

        ! Handle errors
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in fyaml_parse_file!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        end if

        ! Sort the variable names for faster search
        call fyaml_sort_variables(yml)

    end subroutine fyaml_init

    !> \brief Initialize FYAML species configuration
    !!
    !! \param[in] fileName Name of YAML file to read
    !! \param[inout] yml Main configuration object
    !! \param[inout] yml_anchored Anchored variables object
    !! \param[inout] species_names Array of species names
    !! \param[out] RC Return code
    subroutine fyaml_species_init(fileName, yml, yml_anchored, species_names, RC)
        character(len=*), intent(in)    :: fileName
        type(fyaml_t),   intent(inout) :: yml
        type(fyaml_t),   intent(inout) :: yml_anchored
        character(len=*), allocatable, intent(inout) :: species_names(:)
        integer,          intent(out)   :: RC

        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_species_init (in module fyaml.f90)'

        ! Parse species file
        call fyaml_parse_species_file_full(fileName, yml, yml_anchored, species_names, RC)

        ! Handle errors
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in fyaml_parse_species_file!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        end if

    end subroutine fyaml_species_init

    !> \brief Initialize FYAML emissions configuration
    !!
    !! \param[in] fileName Name of YAML file to read
    !! \param[inout] yml Main configuration object
    !! \param[inout] yml_anchored Anchored variables object
    !! \param[inout] EmisState Emissions state object
    !! \param[out] RC Return code
    subroutine fyaml_emis_init(fileName, yml, yml_anchored, EmisState, RC)
        character(len=*), intent(in)    :: fileName
        type(fyaml_t),   intent(inout) :: yml
        type(fyaml_t),   intent(inout) :: yml_anchored
        class(*),         intent(inout) :: EmisState
        integer,          intent(out)   :: RC

        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_emis_init (in module fyaml.f90)'

        ! Parse emissions file (using standard YAML parser)
        call fyaml_parse_file(fileName, yml, yml_anchored, RC)

        ! Handle errors
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in fyaml_parse_file!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        end if

    end subroutine fyaml_emis_init

    !> \brief Merge two FYAML configurations
    !!
    !! \param[in] yml1 First configuration
    !! \param[in] yml2 Second configuration
    !! \param[out] yml Merged configuration
    !! \param[out] RC Return code
    subroutine fyaml_merge(yml1, yml2, yml, RC)
        type(fyaml_t), intent(in)  :: yml1, yml2
        type(fyaml_t), intent(out) :: yml
        integer,       intent(out) :: RC

        call fyaml_merge_configs(yml1, yml2, yml, RC)

    end subroutine fyaml_merge

    !> \brief Print FYAML configuration
    !!
    !! \param[inout] yml Configuration object
    !! \param[out] RC Return code
    !! \param[in] fileName Optional output file name
    !! \param[in] searchKeys Optional search keys
    subroutine fyaml_print(yml, RC, fileName, searchKeys)
        type(fyaml_t),   intent(inout) :: yml
        integer,          intent(out)   :: RC
        character(len=*), optional, intent(in) :: fileName
        character(len=*), optional, intent(in) :: searchKeys(:)

        call fyaml_print_config(yml, fileName, searchKeys, RC)

    end subroutine fyaml_print

    !> \brief Check if variable exists
    !!
    !! \param[in] yml Configuration object
    !! \param[in] var_name Variable name
    !! \param[out] exists Whether variable exists
    subroutine fyaml_check(yml, var_name, exists)
        type(fyaml_t), intent(in) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(out) :: exists

        integer :: ix
        call fyaml_get_var_index(yml, var_name, ix)
        exists = (ix > 0)

    end subroutine fyaml_check

    !> \brief Get size of array variable
    !!
    !! \param[in] yml Configuration object
    !! \param[in] var_name Variable name
    !! \param[out] var_size Size of variable
    !! \param[out] RC Return code
    subroutine fyaml_get_size(yml, var_name, var_size, RC)
        type(fyaml_t), intent(in) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(out) :: var_size
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        var_size = 0
        errMsg = ''
        thisLoc = ' -> at fyaml_get_size (in module fyaml.f90)'

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            var_size = yml%vars(ix)%var_size
        else
            errMsg = 'Variable not found: ' // trim(var_name)
            call fyaml_handle_error(errMsg, RC, thisLoc)
        end if

    end subroutine fyaml_get_size

    !> \brief Get type of variable
    !!
    !! \param[in] yml Configuration object
    !! \param[in] var_name Variable name
    !! \param[out] var_type Type of variable
    !! \param[out] RC Return code
    subroutine fyaml_get_type(yml, var_name, var_type, RC)
        type(fyaml_t), intent(in) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(out) :: var_type
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        var_type = fyaml_unknown_type
        errMsg = ''
        thisLoc = ' -> at fyaml_get_type (in module fyaml.f90)'

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            var_type = yml%vars(ix)%var_type
        else
            errMsg = 'Variable not found: ' // trim(var_name)
            call fyaml_handle_error(errMsg, RC, thisLoc)
        end if

    end subroutine fyaml_get_type

    !> \brief Find depth of variable in hierarchy
    !!
    !! \param[in] var_name Variable name
    !! \param[out] depth Depth level
    subroutine fyaml_find_depth(var_name, depth)
        character(len=*), intent(in) :: var_name
        integer, intent(out) :: depth

        integer :: i, sep_count

        sep_count = 0
        do i = 1, len_trim(var_name)
            if (var_name(i:i) == fyaml_category_separator) then
                sep_count = sep_count + 1
            end if
        end do
        depth = sep_count

    end subroutine fyaml_find_depth

    !> \brief Find next higher level variable
    !!
    !! \param[in] var_name Variable name
    !! \param[out] parent_name Parent variable name
    subroutine fyaml_find_next_higher(var_name, parent_name)
        character(len=*), intent(in) :: var_name
        character(len=*), intent(out) :: parent_name

        integer :: last_sep

        last_sep = index(var_name, fyaml_category_separator, back=.true.)
        if (last_sep > 0) then
            parent_name = var_name(1:last_sep-1)
        else
            parent_name = ""
        end if

    end subroutine fyaml_find_next_higher

    !> \brief Split category from variable name
    !!
    !! \param[in] full_name Full variable name with category
    !! \param[out] category Category part
    !! \param[out] var_name Variable name part
    subroutine fyaml_split_category(full_name, category, var_name)
        character(len=*), intent(in) :: full_name
        character(len=*), intent(out) :: category
        character(len=*), intent(out) :: var_name

        integer :: last_sep

        last_sep = index(full_name, fyaml_category_separator, back=.true.)
        if (last_sep > 0) then
            category = full_name(1:last_sep-1)
            var_name = full_name(last_sep+1:)
        else
            category = ""
            var_name = full_name
        end if

    end subroutine fyaml_split_category

    ! Implementation stubs for variable operations
    ! These would need to be implemented with proper type checking and data handling

    !> \brief Add a real scalar variable
    subroutine add_real(yml, var_name, real_data, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(in) :: real_data
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_real (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_real_type, 1, comment, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%real_data(1) = real_data
        endif
    end subroutine add_real

    !> \brief Add a real array variable
    subroutine add_real_array(yml, var_name, real_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(in) :: real_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_real_array (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_real_type, size(real_data), &
                                    comment, ix, RC, dynamic_size)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%real_data = real_data
        endif
    end subroutine add_real_array

    !> \brief Add an integer scalar variable
    subroutine add_int(yml, var_name, int_data, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(in) :: int_data
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_int (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_integer_type, 1, comment, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%int_data(1) = int_data
        endif
    end subroutine add_int

    !> \brief Add an integer array variable
    subroutine add_int_array(yml, var_name, int_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(in) :: int_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_int_array (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_integer_type, size(int_data), &
                                    comment, ix, RC, dynamic_size)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%int_data = int_data
        endif
    end subroutine add_int_array

    !> \brief Add a string variable
    subroutine add_string(yml, var_name, string_data, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(in) :: string_data
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_string (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_string_type, 1, comment, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%char_data(1) = string_data
        endif
    end subroutine add_string

    !> \brief Add a string array variable
    subroutine add_string_array(yml, var_name, string_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(in) :: string_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_string_array (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_string_type, size(string_data), &
                                    comment, ix, RC, dynamic_size)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%char_data = string_data
        endif
    end subroutine add_string_array

    !> \brief Add a boolean variable
    subroutine add_bool(yml, var_name, bool_data, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(in) :: bool_data
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_bool (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_bool_type, 1, comment, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%bool_data(1) = bool_data
        endif
    end subroutine add_bool

    !> \brief Add a boolean array variable
    subroutine add_bool_array(yml, var_name, bool_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(in) :: bool_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = '-> at add_bool_array (in module fyaml.f90)'

        call fyaml_prepare_store_var(yml, var_name, fyaml_bool_type, size(bool_data), &
                                    comment, ix, RC, dynamic_size)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_store_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        if (yml%vars(ix)%stored_data /= unstored_data_string) then
            call fyaml_read_variable(yml%vars(ix), RC)
            if (RC /= fyaml_Success) then
                errMsg = 'Error encountered in "fyaml_read_variable"!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        else
            yml%vars(ix)%bool_data = bool_data
        endif
    end subroutine add_bool_array

    ! Complete implementations for get operations
    subroutine get_real(yml, var_name, real_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(out) :: real_data
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        real_data = 0.0_yp
        errMsg = ''
        thisLoc = ' -> at get_real (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_real_type, 1, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        real_data = yml%vars(ix)%real_data(1)
    end subroutine get_real

    subroutine get_real_array(yml, var_name, real_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(out) :: real_data(:)
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        real_data = 0.0_yp
        errMsg = ''
        thisLoc = ' -> at get_real_array (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_real_type, size(real_data), ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        real_data(1:yml%vars(ix)%var_size) = yml%vars(ix)%real_data(1:yml%vars(ix)%var_size)
    end subroutine get_real_array

    subroutine get_int(yml, var_name, int_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(out) :: int_data
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        int_data = 0
        errMsg = ''
        thisLoc = ' -> at get_int (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_integer_type, 1, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        int_data = yml%vars(ix)%int_data(1)
    end subroutine get_int

    subroutine get_int_array(yml, var_name, int_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(out) :: int_data(:)
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        int_data = 0
        errMsg = ''
        thisLoc = ' -> at get_int_array (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_integer_type, size(int_data), ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        int_data(1:yml%vars(ix)%var_size) = yml%vars(ix)%int_data(1:yml%vars(ix)%var_size)
    end subroutine get_int_array

    subroutine get_string(yml, var_name, string_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(out) :: string_data
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        string_data = ""
        errMsg = ''
        thisLoc = ' -> at get_string (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_string_type, 1, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        string_data = yml%vars(ix)%char_data(1)
    end subroutine get_string

    subroutine get_string_array(yml, var_name, string_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(out) :: string_data(:)
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        string_data = ""
        errMsg = ''
        thisLoc = ' -> at get_string_array (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_string_type, size(string_data), ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        string_data(1:yml%vars(ix)%var_size) = yml%vars(ix)%char_data(1:yml%vars(ix)%var_size)
    end subroutine get_string_array

    subroutine get_bool(yml, var_name, bool_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(out) :: bool_data
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        bool_data = .false.
        errMsg = ''
        thisLoc = ' -> at get_bool (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_bool_type, 1, ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        bool_data = yml%vars(ix)%bool_data(1)
    end subroutine get_bool

    subroutine get_bool_array(yml, var_name, bool_data, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(out) :: bool_data(:)
        integer, intent(out) :: RC

        integer :: ix
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        bool_data = .false.
        errMsg = ''
        thisLoc = ' -> at get_bool_array (in module fyaml.f90)'

        call fyaml_prepare_get_var(yml, var_name, fyaml_bool_type, size(bool_data), ix, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_prepare_get_var"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        bool_data(1:yml%vars(ix)%var_size) = yml%vars(ix)%bool_data(1:yml%vars(ix)%var_size)
    end subroutine get_bool_array

    ! Complete implementations for add_get operations
    subroutine add_get_real(yml, var_name, real_data, default_val, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(inout) :: real_data
        real(yp), intent(in) :: default_val
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_real(yml, var_name, real_data, RC)
        else
            ! Variable doesn't exist, add it with default value
            real_data = default_val
            call add_real(yml, var_name, real_data, comment, RC)
        endif
    end subroutine add_get_real

    subroutine add_get_real_array(yml, var_name, real_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(inout) :: real_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_real_array(yml, var_name, real_data, RC)
        else
            ! Variable doesn't exist, add it with current array values
            call add_real_array(yml, var_name, real_data, comment, RC, dynamic_size)
        endif
    end subroutine add_get_real_array

    subroutine add_get_int(yml, var_name, int_data, default_val, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(inout) :: int_data
        integer, intent(in) :: default_val
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_int(yml, var_name, int_data, RC)
        else
            ! Variable doesn't exist, add it with default value
            int_data = default_val
            call add_int(yml, var_name, int_data, comment, RC)
        endif
    end subroutine add_get_int

    subroutine add_get_int_array(yml, var_name, int_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(inout) :: int_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_int_array(yml, var_name, int_data, RC)
        else
            ! Variable doesn't exist, add it with current array values
            call add_int_array(yml, var_name, int_data, comment, RC, dynamic_size)
        endif
    end subroutine add_get_int_array

    subroutine add_get_string(yml, var_name, string_data, default_val, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(inout) :: string_data
        character(len=*), intent(in) :: default_val
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_string(yml, var_name, string_data, RC)
        else
            ! Variable doesn't exist, add it with default value
            string_data = default_val
            call add_string(yml, var_name, string_data, comment, RC)
        endif
    end subroutine add_get_string

    subroutine add_get_string_array(yml, var_name, string_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(inout) :: string_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_string_array(yml, var_name, string_data, RC)
        else
            ! Variable doesn't exist, add it with current array values
            call add_string_array(yml, var_name, string_data, comment, RC, dynamic_size)
        endif
    end subroutine add_get_string_array

    subroutine add_get_bool(yml, var_name, bool_data, default_val, comment, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(inout) :: bool_data
        logical, intent(in) :: default_val
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_bool(yml, var_name, bool_data, RC)
        else
            ! Variable doesn't exist, add it with default value
            bool_data = default_val
            call add_bool(yml, var_name, bool_data, comment, RC)
        endif
    end subroutine add_get_bool

    subroutine add_get_bool_array(yml, var_name, bool_data, comment, RC, dynamic_size)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(inout) :: bool_data(:)
        character(len=*), intent(in) :: comment
        integer, intent(out) :: RC
        logical, optional, intent(in) :: dynamic_size

        integer :: ix

        ! Try to get the variable first
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix > 0) then
            ! Variable exists, get its value
            call get_bool_array(yml, var_name, bool_data, RC)
        else
            ! Variable doesn't exist, add it with current array values
            call add_bool_array(yml, var_name, bool_data, comment, RC, dynamic_size)
        endif
    end subroutine add_get_bool_array

    ! Complete implementations for update operations
    subroutine update_real(yml, var_name, real_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(inout) :: real_data

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%real_data(1) = real_data
            real_data = yml%vars(ix)%real_data(1)
        endif
    end subroutine update_real

    subroutine update_real_array(yml, var_name, real_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        real(yp), intent(inout) :: real_data(:)

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%real_data = real_data
            real_data = yml%vars(ix)%real_data
        endif
    end subroutine update_real_array

    subroutine update_int(yml, var_name, int_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(inout) :: int_data

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%int_data(1) = int_data
            int_data = yml%vars(ix)%int_data(1)
        endif
    end subroutine update_int

    subroutine update_int_array(yml, var_name, int_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(inout) :: int_data(:)

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%int_data = int_data
            int_data = yml%vars(ix)%int_data
        endif
    end subroutine update_int_array

    subroutine update_string(yml, var_name, string_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(inout) :: string_data

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%char_data(1) = string_data
            string_data = yml%vars(ix)%char_data(1)
        endif
    end subroutine update_string

    subroutine update_string_array(yml, var_name, string_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        character(len=*), intent(inout) :: string_data(:)

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%char_data = string_data
            string_data = yml%vars(ix)%char_data
        endif
    end subroutine update_string_array

    subroutine update_bool(yml, var_name, bool_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(inout) :: bool_data

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%bool_data(1) = bool_data
            bool_data = yml%vars(ix)%bool_data(1)
        endif
    end subroutine update_bool

    subroutine update_bool_array(yml, var_name, bool_data)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        logical, intent(inout) :: bool_data(:)

        integer :: ix

        call fyaml_get_var_index(yml, var_name, ix)
        if (ix > 0) then
            yml%vars(ix)%bool_data = bool_data
            bool_data = yml%vars(ix)%bool_data
        endif
    end subroutine update_bool_array

    !=================================================================================
    !========================== PRIVATE HELPER FUNCTIONS =============================
    !=================================================================================

    !> \brief Prepare variable storage
    !!
    !! Helper routine to prepare variable storage in the configuration object
    !!
    !! \param[inout] yml Configuration object
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
        thisLoc = ' -> at fyaml_prepare_store_var (in module fyaml.f90)'

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

    !> \brief Prepare variable for getting data
    !!
    !! Helper routine to prepare variable for data retrieval
    !!
    !! \param[inout] yml Configuration object
    !! \param[in] var_name Variable name
    !! \param[in] var_type Expected variable type
    !! \param[in] var_size Expected variable size
    !! \param[out] ix Variable index
    !! \param[out] RC Return code
    subroutine fyaml_prepare_get_var(yml, var_name, var_type, var_size, ix, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: var_name
        integer, intent(in) :: var_type
        integer, intent(in) :: var_size
        integer, intent(out) :: ix
        integer, intent(out) :: RC

        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ""
        thisLoc = " -> at fyaml_prepare_get_var (in module fyaml.f90)"

        ! Get the variable index from the name
        call fyaml_get_var_index(yml, var_name, ix)

        if (ix == fyaml_Failure) then
            ! Couldn't find variable, exit with error
            errMsg = "fyaml_get: variable " // trim(var_name) // " not found!"
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return

        else if (yml%vars(ix)%var_type /= var_type) then
            ! Variable is different type than expected: exit with error
            write(errMsg, "(a)") &
                 "Variable " // trim(var_name) // " has different type (" // &
                 trim(fyaml_type_names(yml%vars(ix)%var_type)) // &
                 ") than requested (" // &
                 trim(fyaml_type_names(var_type)) // ")"
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return

        else if (var_size < yml%vars(ix)%var_size) then
            ! Variable has different size than requested: exit w/ error
            write(errMsg, "(a,i0,a,i0,a)") &
                 "Variable " // trim(var_name) // " has different size (", &
                 yml%vars(ix)%var_size, ") than requested (", var_size, ")"
            call fyaml_handle_error(errMsg, RC, thisLoc)

        else
            ! All good, variable will be used
            yml%vars(ix)%used = .true.
        endif

    end subroutine fyaml_prepare_get_var

    !> \brief Ensure free storage is available
    !!
    !! Ensures that enough storage is allocated for the configuration type.
    !! If not, the new size will be twice as much as the current size.
    !!
    !! \param[inout] yml Configuration object
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
    !! Reads variable data from stored string representation
    !!
    !! \param[inout] var Variable to read
    !! \param[out] RC Return code
    subroutine fyaml_read_variable(var, RC)
        type(fyaml_var_t), intent(inout) :: var
        integer, intent(out) :: RC

        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_read_variable (in module fyaml.f90)'

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

    !> \brief Simple YAML file parser
    !!
    !! \param[in] fileName Name of YAML file to read
    !! \param[inout] yml Main configuration object
    !> \brief Bridge function for utils module to add variables during parsing
    !!
    !! This function is called by the fyaml_utils module during parsing to
    !! add variables to the configuration object.
    !!
    !! \param[inout] yml Configuration object
    !! \param[in] append Whether to append to existing variable
    !! \param[in] set_by How the variable was set
    !! \param[in] line_arg Input line containing the value
    !! \param[in] anchor_ptr_arg Anchor pointer if any
    !! \param[in] anchor_tgt_arg Anchor target if any
    !! \param[in] category_arg Category name
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
        thisLoc = ' -> at fyaml_add_variable_to_store (in module fyaml.f90)'

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
        else
            ! Variable is already present in the yml object
            if (append) then
                ! Append data to data that is already present
                yml%vars(ix)%stored_data = trim(yml%vars(ix)%stored_data) // trim(line_arg)
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

    !> \brief Parse a species YAML file and extract species names (full interface)
    !!
    !! \param[in] fileName Name of YAML file to read
    !! \param[inout] yml Main configuration object
    !! \param[inout] yml_anchored Anchored variables object
    !! \param[inout] species_names Array of species names to be allocated and filled
    !! \param[out] RC Return code
    subroutine fyaml_parse_species_file_full(fileName, yml, yml_anchored, species_names, RC)
        character(len=*), intent(in) :: fileName
        type(fyaml_t), intent(inout) :: yml
        type(fyaml_t), intent(inout) :: yml_anchored
        character(len=*), allocatable, intent(inout) :: species_names(:)
        integer, intent(out) :: RC

        character(len=fyaml_NamLen) :: current
        integer :: i, n
        character(len=fyaml_StrLen) :: errMsg, thisLoc

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_parse_species_file (in module fyaml.f90)'

        ! First parse the file using standard parser
        call fyaml_parse_file(fileName, yml, yml_anchored, RC)
        if (RC /= fyaml_Success) then
            errMsg = 'Error encountered in "fyaml_parse_file"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        ! Count unique categories (species)
        i = 0
        current = ""
        do n = 1, yml%num_vars
            if (len_trim(yml%vars(n)%category) > 0) then
                if (trim(yml%vars(n)%category) /= trim(current)) then
                    i = i + 1
                    current = trim(yml%vars(n)%category)
                endif
            endif
        enddo

        ! Allocate species_names array
        allocate(species_names(i), stat=RC)
        if (RC /= 0) then
            errMsg = 'Error allocating "species_names"!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        ! Fill species_names array with unique categories
        current = ""
        i = 0
        do n = 1, yml%num_vars
            if (len_trim(yml%vars(n)%category) > 0) then
                if (i == 0) then
                    i = i + 1
                    current = trim(yml%vars(n)%category)
                    species_names(i) = yml%vars(n)%category
                else if (trim(yml%vars(n)%category) /= trim(current)) then
                    i = i + 1
                    species_names(i) = yml%vars(n)%category
                    current = trim(yml%vars(n)%category)
                endif
            endif
        enddo

    end subroutine fyaml_parse_species_file_full

    !> \brief Merge two YAML configuration objects
    !!
    !! \param[in] yml1 First configuration object
    !! \param[in] yml2 Second configuration object
    !! \param[out] yml Merged configuration object
    !! \param[out] RC Return code
    subroutine fyaml_merge_configs(yml1, yml2, yml, RC)
        type(fyaml_t), intent(in) :: yml1, yml2
        type(fyaml_t), intent(out) :: yml
        integer, intent(out) :: RC

        integer :: N, M, ix, final_count
        character(len=fyaml_StrLen) :: errMsg, thisLoc
        logical :: found_duplicate

        ! Initialize
        RC = fyaml_success
        errMsg = ''
        thisLoc = ' -> at fyaml_merge_configs (in module fyaml.f90)'

        ! Count unique variables (yml2 overwrites yml1)
        final_count = yml1%num_vars
        do N = 1, yml2%num_vars
            found_duplicate = .false.
            do M = 1, yml1%num_vars
                if (trim(yml2%vars(N)%var_name) == trim(yml1%vars(M)%var_name)) then
                    found_duplicate = .true.
                    exit
                endif
            enddo
            if (.not. found_duplicate) then
                final_count = final_count + 1
            endif
        enddo

        ! Initialize the merged object
        yml%num_vars = final_count
        yml%sorted = .false.

        ! Allocate space for variables
        allocate(yml%vars(yml%num_vars), stat=RC)
        if (RC /= 0) then
            errMsg = 'Error allocating merged variables array!'
            call fyaml_handle_error(errMsg, RC, thisLoc)
            return
        endif

        ! Add variables from first object
        ix = 0
        do N = 1, yml1%num_vars
            ix = ix + 1
            yml%vars(ix) = yml1%vars(N)
        enddo

        ! Add/overwrite variables from second object
        do N = 1, yml2%num_vars
            found_duplicate = .false.
            ! Check if this variable already exists from yml1
            do M = 1, yml1%num_vars
                if (trim(yml2%vars(N)%var_name) == trim(yml%vars(M)%var_name)) then
                    ! Overwrite existing variable
                    yml%vars(M) = yml2%vars(N)
                    found_duplicate = .true.
                    exit
                endif
            enddo

            ! If not a duplicate, add as new variable
            if (.not. found_duplicate) then
                ix = ix + 1
                yml%vars(ix) = yml2%vars(N)
            endif
        enddo

        ! Sort the variable names for faster search
        call fyaml_sort_variables(yml)

    end subroutine fyaml_merge_configs

    !> \brief Print YAML configuration to file or stdout
    !!
    !! \param[inout] yml Configuration object
    !! \param[in] fileName Optional output file name (if not provided, prints to stdout)
    !! \param[in] searchKeys Optional array of keys to filter output
    !! \param[out] RC Return code
    subroutine fyaml_print_config(yml, fileName, searchKeys, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), optional, intent(in) :: fileName
        character(len=*), optional, intent(in) :: searchKeys(:)
        integer, intent(out) :: RC

        ! Local variables
        logical :: isFileName, isSearchKeys, printVar
        integer :: c, c0, d, i, lun, varDepth
        character(len=fyaml_NamLen) :: display, varName
        character(len=fyaml_StrLen) :: errMsg, thisLoc
        character(len=fyaml_NamLen) :: stack(fyaml_MaxStack)
        character(len=fyaml_NamLen) :: lastStack(fyaml_MaxStack)
        character(len=2), parameter :: fyaml_indent = "  "

        ! Initialize
        RC = fyaml_success
        lun = 6  ! Default to stdout
        errMsg = ''
        thisLoc = ' -> at fyaml_print_config (in module fyaml.f90)'

        ! Check if arguments are present
        isFileName = present(fileName)
        isSearchKeys = present(searchKeys)

        ! Open output file if specified
        if (isFileName) then
            lun = 700
            open(lun, file=trim(fileName), status="replace", action="write", iostat=RC)
            if (RC /= fyaml_SUCCESS) then
                errMsg = 'Could not open file: ' // trim(fileName)
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
            ! Write YAML header
            write(lun, '(a)') '---'
        endif

        ! Step through YAML variables and write output
        lastStack = ''
        do i = 1, yml%num_vars
            ! Initialize loop variables
            c = 0
            c0 = 0
            display = ''
            stack = ''
            varName = yml%vars(i)%var_name

            ! Check if we should print this variable
            printVar = .true.
            if (isSearchKeys) then
                c = index(varName, fyaml_category_separator)
                if (c > 0) then
                    printVar = any(searchKeys == varName(1:c-1))
                endif
            endif

            ! Skip if not to be printed or has undefined data
            if (.not. printVar) cycle
            if (adjustl(yml%vars(i)%stored_data) == unstored_data_string) cycle

            ! Find variable depth and create stack
            call fyaml_find_depth(varName, varDepth)

            ! Split the variable into substrings
            c0 = 0
            do d = 1, varDepth-1
                c = index(varName(c0+1:), fyaml_category_separator)
                stack(d) = varName(c0+1:c0+c-1) // ':'
                c0 = c0 + c
            enddo
            stack(d) = trim(varName(c0+1:)) // ': ' // trim(yml%vars(i)%stored_data)

            ! Print only levels that haven't been printed before
            do d = 1, varDepth
                if (trim(stack(d)) /= trim(lastStack(d))) then
                    display = stack(d)

                    ! Handle special cases for "NO" or "no"
                    if (d == 1) then
                        if (display(1:3) == "NO:") display = "'NO':"
                        if (display(1:3) == "no:") display = "'no':"
                    endif

                    ! Print with proper indentation
                    write(lun, '(a,a)') repeat(fyaml_indent, d-1), trim(display)
                endif
            enddo

            ! Save copy of stack for next iteration
            lastStack = stack
        enddo

        ! Close file if opened
        if (isFileName .and. lun == 700) then
            close(lun, iostat=RC)
            if (RC /= fyaml_SUCCESS) then
                errMsg = 'Error closing YAML output file!'
                call fyaml_handle_error(errMsg, RC, thisLoc)
                return
            endif
        endif

    end subroutine fyaml_print_config

    !> \brief Legacy wrapper that includes anchor expansion
    !!
    !! This is a legacy wrapper to maintain backwards compatibility
    !! with old code that uses fyaml_read_file. It provides full
    !! anchor expansion functionality using fyaml_init.
    !!
    !! \param[inout] yml Main configuration object
    !! \param[in] fileName Name of YAML file to read
    !! \param[out] RC Return code
    subroutine fyaml_read_file(yml, fileName, RC)
        type(fyaml_t), intent(inout) :: yml
        character(len=*), intent(in) :: fileName
        integer, intent(out) :: RC

        type(fyaml_t) :: yml_anchored

        ! Call fyaml_init which includes full anchor expansion
        call fyaml_init(fileName, yml, yml_anchored, RC)

    end subroutine fyaml_read_file

    !> \brief Simple species parsing interface
    !!
    !! This is a simplified wrapper for species parsing that matches
    !! the expected test interface.
    !!
    !! \param[in] filename Name of YAML file to read
    !! \param[out] species Array of species names
    !! \param[out] num_species Number of species found
    !! \param[out] RC Return code
    subroutine fyaml_parse_species_file_simple(filename, species, num_species, RC)
        character(len=*), intent(in) :: filename
        character(len=*), allocatable, intent(out) :: species(:)
        integer, intent(out) :: num_species
        integer, intent(out) :: RC

        type(fyaml_t) :: yml, yml_anchored

        ! Call the full interface
        call fyaml_parse_species_file_full(filename, yml, yml_anchored, species, RC)

        if (RC == fyaml_Success) then
            num_species = size(species)
        else
            num_species = 0
        endif

        ! Clean up
        call fyaml_cleanup(yml)
        call fyaml_cleanup(yml_anchored)

    end subroutine fyaml_parse_species_file_simple

end module fyaml

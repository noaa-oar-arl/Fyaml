!> A modern Fortran module for parsing YAML files
!!
!! This module provides functionality to read and parse YAML files into Fortran
!! data structures. It supports nested dictionaries, sequences, and various data types.
!!
!! @note Currently supports strings, integers, reals, booleans, nulls, sequences and nested structures
!! @author Barry Baker
!! @date 2024
!! @version 0.1.0
!! @copyright GNU GENERAL PUBLIC LICENSE v3.0
module fyaml
    use yaml_parser
    use yaml_types
    use, intrinsic :: iso_fortran_env, only: error_unit
    implicit none

    private
    public :: fyaml_doc, yaml_value, yaml_dict, yaml_pair, yaml_wrapper, error_unit

    !> Constants for supported YAML value types
    integer, parameter :: TYPE_STRING = 1   !< String type
    integer, parameter :: TYPE_REAL = 2     !< Real number type
    integer, parameter :: TYPE_INTEGER = 3  !< Integer type
    integer, parameter :: TYPE_BOOLEAN = 4  !< Boolean type
    integer, parameter :: TYPE_NULL = 5     !< Null type
    integer, parameter :: TYPE_SEQUENCE = 6 !< Sequence type
    integer, parameter :: TYPE_DICT = 7     !< Dictionary type

    !> Value container type supporting multiple YAML data types
    type :: yaml_value
        character(len=:), allocatable :: str_val     !< String value
        real :: real_val                             !< Real number value
        integer :: int_val                           !< Integer value
        logical :: bool_val                          !< Boolean value
        logical :: is_null = .false.                 !< Null indicator
        character(len=:), allocatable, dimension(:) :: sequence !< Sequence value
        integer :: value_type = 0                    !< Type indicator
        type(yaml_dict), pointer :: dict_val => null() !< Dictionary value
    contains
        procedure :: get => get_nested_value !< Get value using dot notation path
    end type yaml_value

    !> Dictionary key-value pair type
    type :: yaml_pair
        character(len=:), allocatable :: key !< Dictionary key
        type(yaml_value) :: value           !< Value container
        type(yaml_dict), pointer :: nested => null() !< Nested dictionary
        type(yaml_pair), pointer :: next => null()   !< Next pair in linked list
    end type yaml_pair

    !> Dictionary container type
    type :: yaml_dict
        type(yaml_pair), pointer :: first => null() !< First key-value pair
        integer :: count = 0                        !< Number of entries
    contains
        procedure :: get => get_value    !< Get value by key
        procedure :: set => set_value    !< Set value for key
        procedure :: keys => get_keys    !< Get all keys
    end type yaml_dict

    !> YAML document container
    type :: fyaml_doc
        type(yaml_dict) :: root !< Root dictionary
    contains
        procedure :: load => load_yaml_doc !< Load YAML from file
    end type fyaml_doc

    !> YAML document wrapper with raw and processed forms
    type :: yaml_wrapper
        type(yaml_document) :: raw_doc !< Raw YAML document
        type(fyaml_doc) :: doc        !< Processed document
        type(yaml_dict) :: dict       !< Dictionary structure
    contains
        procedure :: load => load_yaml_wrapper !< Load and process YAML
        procedure :: convert => convert_to_dict !< Convert raw to dictionary
    end type yaml_wrapper

contains
    !> Load YAML document from file
    !!
    !! @param[in,out] this     The document instance
    !! @param[in]     filename Path to YAML file
    !! @param[out]    success  Optional success indicator
    subroutine load_yaml_doc(this, filename, success)
        class(fyaml_doc), intent(inout) :: this
        character(len=*), intent(in) :: filename
        logical, intent(out), optional :: success
        type(yaml_document), allocatable :: parsed_docs(:)
        logical :: ok
        integer :: unit, iostat

        ok = .false.

        ! Check if file exists and is readable
        open(newunit=unit, file=filename, status='old', action='read', iostat=iostat)
        if (iostat /= 0) then
            write(error_unit,*) 'Error opening file:', trim(filename)
            if (present(success)) success = .false.
            return
        end if
        close(unit)

        ! Parse YAML
        call parse_yaml(filename, parsed_docs)
        if (allocated(parsed_docs)) then
            if (associated(parsed_docs(1)%root)) then
                call convert_node_to_dict(parsed_docs(1)%root, this%root)
                ok = .true.
            end if
            deallocate(parsed_docs)
        end if

        if (present(success)) success = ok
    end subroutine load_yaml_doc

    !> Load and process YAML document through wrapper
    !!
    !! @param[in,out] this     The wrapper instance
    !! @param[in]     filename Path to YAML file
    subroutine load_yaml_wrapper(this, filename)
        class(yaml_wrapper), intent(inout) :: this
        character(len=*), intent(in) :: filename

        call this%doc%load(filename)
        call this%convert()
    end subroutine load_yaml_wrapper

    !> Parse a YAML sequence string into array
    !!
    !! @param[in]  str Input sequence string in format '[item1,item2,...]'
    !! @return     Array of sequence items
    function fyaml_parse_sequence(str) result(seq)
        character(len=*), intent(in) :: str
        character(len=:), allocatable, dimension(:) :: seq
        integer :: n, i, start, end

        n = count(transfer(str, 'a', len(str)) == ',') + 1
        allocate(character(len=32) :: seq(n))

        start = 2  ! Skip '['
        do i = 1, n
            end = index(str(start:), ',') - 1
            if (end < 0) end = len_trim(str) - 1  ! Last item
            seq(i) = trim(adjustl(str(start:start+end-1)))
            start = start + end + 2
        end do
    end function fyaml_parse_sequence

    !> Recursively convert YAML node structure to dictionary
    !!
    !! @param[in]     node Input YAML node
    !! @param[in,out] dict Output dictionary structure
    recursive subroutine convert_node_to_dict(node, dict)
        type(yaml_node), pointer, intent(in) :: node
        type(yaml_dict), intent(inout) :: dict
        type(yaml_pair), pointer :: new_pair
        type(yaml_node), pointer :: current

        current => node
        do while (associated(current))
            allocate(new_pair)
            new_pair%key = current%key

            if (associated(current%children)) then
                allocate(new_pair%nested)
                new_pair%value%value_type = TYPE_DICT
                new_pair%value%dict_val => new_pair%nested
                call convert_node_to_dict(current%children, new_pair%nested)
            else
                ! Set value based on content
                if (is_sequence(current%value)) then
                    new_pair%value%value_type = TYPE_SEQUENCE
                    new_pair%value%sequence = fyaml_parse_sequence(current%value)
                else if (is_null(current%value)) then
                    new_pair%value%value_type = TYPE_NULL
                    new_pair%value%is_null = .true.
                else if (is_boolean(current%value)) then
                    new_pair%value%value_type = TYPE_BOOLEAN
                    new_pair%value%bool_val = current%value == 'true'  ! Direct comparison instead of parse_sequence
                else if (is_number(current%value)) then
                    if (index(current%value, '.') > 0) then
                        new_pair%value%value_type = TYPE_REAL
                        read(current%value, *) new_pair%value%real_val
                    else
                        new_pair%value%value_type = TYPE_INTEGER
                        read(current%value, *) new_pair%value%int_val
                    endif
                else
                    new_pair%value%value_type = TYPE_STRING
                    new_pair%value%str_val = current%value
                endif
            endif

            if (.not. associated(dict%first)) then
                dict%first => new_pair
            else
                new_pair%next => dict%first
                dict%first => new_pair
            endif
            dict%count = dict%count + 1

            current => current%next
        end do
    end subroutine convert_node_to_dict

    !> Set value for a given key in dictionary
    !!
    !! @param[in,out] this  The dictionary instance
    !! @param[in]     key   Key to set
    !! @param[in]     value Value to associate with key
    subroutine set_value(this, key, value)
        class(yaml_dict), intent(inout) :: this
        character(len=*), intent(in) :: key
        type(yaml_value), intent(in) :: value
        type(yaml_pair), pointer :: current, new_pair

        ! Check if key exists
        current => this%first
        do while (associated(current))
            if (current%key == key) then
                ! Update existing value
                current%value = value
                return
            endif
            current => current%next
        end do

        ! Key doesn't exist, create new pair
        allocate(new_pair)
        new_pair%key = key
        new_pair%value = value

        ! Add to beginning of list
        new_pair%next => this%first
        this%first => new_pair
        this%count = this%count + 1
    end subroutine set_value

    !> Check if string represents a sequence
    !!
    !! @param[in]  str String to check
    !! @return     True if string starts with '['
    function is_sequence(str) result(res)
        character(len=*), intent(in) :: str
        logical :: res
        res = str(1:1) == '['
    end function is_sequence

    !> Check if string represents null
    !!
    !! @param[in]  str String to check
    !! @return     True if string equals 'null'
    function is_null(str) result(res)
        character(len=*), intent(in) :: str
        logical :: res
        res = trim(str) == 'null'
    end function is_null

    !> Check if string represents boolean
    !!
    !! @param[in]  str String to check
    !! @return     True if string equals 'true' or 'false'
    function is_boolean(str) result(res)
        character(len=*), intent(in) :: str
        logical :: res
        res = trim(str) == 'true' .or. trim(str) == 'false'
    end function is_boolean

    !> Check if string represents a number
    !!
    !! @param[in]  str String to check
    !! @return     True if string contains only digits, dot or minus
    function is_number(str) result(res)
        character(len=*), intent(in) :: str
        logical :: res
        res = verify(trim(str), '0123456789.-') == 0
    end function is_number

    !> Get value associated with key from dictionary
    !!
    !! @param[in]  this Dictionary instance
    !! @param[in]  key  Key to lookup
    !! @return     Value associated with key
    function get_value(this, key) result(val)
        class(yaml_dict), intent(in) :: this
        character(len=*), intent(in) :: key
        type(yaml_value) :: val
        type(yaml_pair), pointer :: current

        current => this%first
        do while (associated(current))
            if (current%key == key) then
                val = current%value
                return
            endif
            current => current%next
        end do
    end function get_value

    !> Get all keys in dictionary
    !!
    !! @param[in]  this Dictionary instance
    !! @return     Array of all keys
    function get_keys(this) result(keys)
        class(yaml_dict), intent(in) :: this
        character(len=:), allocatable, dimension(:) :: keys
        type(yaml_pair), pointer :: current
        integer :: i

        allocate(character(len=32) :: keys(this%count))
        current => this%first
        i = 1
        do while (associated(current))
            keys(i) = current%key
            i = i + 1
            current => current%next
        end do
    end function get_keys

    !> Convert raw YAML document to dictionary structure
    !!
    !! @param[in,out] this Wrapper instance containing raw and processed forms
    subroutine convert_to_dict(this)
        class(yaml_wrapper), intent(inout) :: this

        ! Convert from raw yaml_document to yaml_dict structure
        if (associated(this%raw_doc%root)) then
            call convert_node_to_dict(this%raw_doc%root, this%dict)
        endif
    end subroutine convert_to_dict

    !> Get nested value using dot notation path
    !!
    !! @param[in]  self YAML value instance
    !! @param[in]  key  Dot-separated path (e.g. "database.host")
    !! @return     Value at specified path
    recursive function get_nested_value(self, key) result(val)
        class(yaml_value), intent(in) :: self
        character(len=*), intent(in) :: key
        type(yaml_value) :: val
        integer :: dot_pos
        character(len=:), allocatable :: first_key, rest_path

        dot_pos = index(key, ".")

        if (dot_pos > 0) then
            first_key = key(1:dot_pos-1)
            rest_path = key(dot_pos+1:)

            if (associated(self%dict_val)) then
                val = self%dict_val%get(first_key)
                if (.not. val%is_null .and. allocated(rest_path)) then
                    val = val%get(rest_path)
                endif
            else
                val%is_null = .true.
            endif
        else
            if (associated(self%dict_val)) then
                val = self%dict_val%get(key)
            else
                val%is_null = .true.
            endif
        endif

    end function get_nested_value

end module fyaml
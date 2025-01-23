!> A modern Fortran module for parsing YAML files
!!
!! This module provides functionality to read and parse YAML files into Fortran
!! data structures. It supports nested dictionaries, sequences, and various data types.
!!
!! Example:
!! ```fortran
!! type(fyaml_doc) :: doc
!! call doc%load("config.yaml")
!! value = doc%get("config%nested%key")
!! ```
!!
!! @note Supports strings, integers, reals, booleans, nulls, and sequences
!! @version 1.0.0
!! @see yaml_parser
!! @see yaml_types
module fyaml
    use yaml_parser, only: yaml_node, check_sequence_node, parse_yaml, debug_print, DEBUG_INFO  ! Add DEBUG_INFO to imports
    use yaml_types
    use, intrinsic :: iso_fortran_env, only: error_unit
    implicit none

    private
    public :: fyaml_doc, yaml_value, yaml_dict, yaml_pair, error_unit
    public :: split_key, count_children, get_child_keys, get_root_keys  ! Add count_children, get_child_keys, and get_root_keys to public list

    ! Add interface declaration for nested value getters
    interface get_nested_value
        module procedure get_value_nested
        module procedure get_doc_nested
    end interface

    ! Add interface declaration for safe_allocate_string
    interface
        subroutine safe_allocate_string(str, length, status)
            character(len=:), allocatable, intent(out) :: str
            integer, intent(in) :: length
            integer, intent(out) :: status
        end subroutine safe_allocate_string
    end interface

    ! Add new interface declaration for count_children
    interface count_children
        module procedure count_node_children
        module procedure count_value_children
    end interface

    ! Add interface for get_child_keys
    interface get_child_keys
        module procedure get_node_child_keys
        module procedure get_value_child_keys
    end interface

    ! Add private declarations here
    private :: get_doc_nested
    private :: get_nested_str
    private :: get_nested_int
    private :: get_nested_real
    private :: get_nested_bool  ! Add boolean getter
    private :: get_value_nested
    private :: find_child_by_key
    private :: check_sequence_impl ! New private implementation
    private :: safe_allocate_string
    private :: determine_value_type ! New private subroutine
    private :: get_sequence_values  ! Add private declaration
    private :: get_sequence_integers ! Add private declaration
    private :: get_sequence_reals    ! Add private declaration
    private :: get_sequence_bools    ! Add private declaration
    private :: get_sequence_size  ! Add to private declarations

    !> Value container type supporting multiple YAML data types
    !!
    !! Wraps a yaml_node pointer and provides type-safe access methods
    type :: yaml_value
        type(yaml_node), pointer :: node => null()  !< Direct reference to yaml_parser node
    contains
        procedure :: get => get_value_nested     !< Get value using dot notation path (rename to avoid conflict)
        procedure :: get_str => get_string_value    !< Get string value
        procedure :: get_int => get_integer_value   !< Get integer value
        procedure :: get_real => get_real_value     !< Get real value
        procedure :: get_bool => get_boolean_value  !< Get boolean value
        procedure :: is_null => check_null          !< Check if value is null
        procedure :: is_sequence => check_sequence_impl  !< Check if value is sequence
        procedure :: child_keys => get_value_child_keys  ! Add method to type
        procedure :: child_at => get_child_at_index  ! Add new method
        procedure :: get_sequence => get_sequence_values       ! String sequence (default)
        procedure :: get_sequence_int => get_sequence_integers ! Integer sequence
        procedure :: get_sequence_real => get_sequence_reals   ! Real sequence
        procedure :: get_sequence_bool => get_sequence_bools   ! Boolean sequence
        procedure :: size => get_sequence_size  ! Add size method
    end type yaml_value

    !> Dictionary key-value pair type
    !!
    !! Represents a single key-value entry in a YAML dictionary
    type :: yaml_pair
        character(len=:), allocatable :: key     !< Dictionary key
        type(yaml_value) :: value               !< Value container
        type(yaml_dict), pointer :: nested => null() !< Nested dictionary
        type(yaml_pair), pointer :: next => null()   !< Next pair in linked list
        integer :: indent_level = 0              !< Indentation level (0 for root)
    end type yaml_pair

    !> Dictionary container type
    !!
    !! Manages a collection of key-value pairs in a linked list structure
    type :: yaml_dict
        type(yaml_pair), pointer :: first => null() !< First key-value pair
        integer :: count = 0                        !< Number of entries
    contains
        procedure :: get => get_value    !< Get value by key
        procedure :: set => set_value    !< Set value for key
        procedure :: keys => get_keys    !< Get all keys
    end type yaml_dict

    !> Main document type for YAML parsing
    !!
    !! Represents a complete YAML document with support for multiple documents
    type :: fyaml_doc
        type(yaml_dict), allocatable :: docs(:)  !< Array of documents
        integer :: n_docs = 0                    !< Number of documents
    contains
        procedure :: load => load_yaml_doc       !< Load YAML from file
        procedure :: get => get_doc_nested       !< Get nested value using % delimiter
        procedure :: get_str => get_nested_str   !< Get string value using % path
        procedure :: get_int => get_nested_int   !< Get integer value using % path
        procedure :: get_real => get_nested_real !< Get real value using % path
        procedure :: get_bool => get_nested_bool !< Get boolean value using % path
        procedure :: get_doc => get_document     !< Get specific document
        procedure :: get_default_doc => get_default_doc !< Get value from default document (first document)
        procedure :: root_keys => get_root_keys !< Get all root level keys
    end type fyaml_doc

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
        logical :: ok, file_exists
        integer :: rc, ios, i
        integer :: unit_num
        character(len=1024) :: buffer

        ok = .false.

        ! Clean up any existing documents
        if (allocated(this%docs)) deallocate(this%docs)
        this%n_docs = 0

        ! Check if file exists first
        inquire(file=filename, exist=file_exists)
        if (.not. file_exists) then
            write(error_unit,*) 'YAML file not found:', trim(filename)
            if (present(success)) success = .false.
            return
        endif

        ! Open file with error checking
        open(newunit=unit_num, file=filename, status='old', action='read', iostat=ios, iomsg=buffer)
        if (ios /= 0) then
            write(error_unit,*) 'Error opening file:', trim(filename), ' - ', trim(buffer)
            if (present(success)) success = .false.
            return
        endif

        ! Test read first line to verify file is readable
        read(unit_num, '(A)', iostat=ios, end=100) buffer
        if (ios /= 0) then
            write(error_unit,*) 'Error reading file:', trim(filename)
            if (present(success)) success = .false.
            close(unit_num)
            return
        endif
        rewind(unit_num)

        ! Parse YAML with error handling
        call parse_yaml(filename, parsed_docs, rc)
        close(unit_num)

        if (rc /= 0) then
            write(error_unit,*) 'Error parsing YAML:', trim(filename)
            if (present(success)) success = .false.
            return
        endif

        if (.not. allocated(parsed_docs)) then
            write(error_unit,*) 'No documents parsed from file:', trim(filename)
            if (present(success)) success = .false.
            return
        endif

        ! Store number of documents and allocate docs array
        this%n_docs = size(parsed_docs)
        allocate(this%docs(this%n_docs), stat=ios)
        if (ios /= 0) then
            write(error_unit,*) 'Error allocating document array'
            if (present(success)) success = .false.
            if (allocated(parsed_docs)) deallocate(parsed_docs)
            return
        endif

        ! Convert each document with error checking
        do i = 1, this%n_docs
            if (associated(parsed_docs(i)%root)) then
                call convert_node_to_dict(parsed_docs(i)%root, this%docs(i))
                ok = .true.
            else
                write(error_unit,*) 'Warning: Document', i, 'has no root node'
            endif
        end do

        if (allocated(parsed_docs)) deallocate(parsed_docs)
        if (present(success)) success = ok
        return

100     continue
        ! Handle empty file
        write(error_unit,*) 'Empty or invalid YAML file:', trim(filename)
        if (present(success)) success = .false.
        close(unit_num)
        return
    end subroutine load_yaml_doc

    !> Convert a yaml_node to yaml_value
    !!
    !! @param[in] node Source YAML node
    !! @return Value container wrapping the node
    function node_to_value(node) result(val)
        type(yaml_node), pointer, intent(in) :: node
        type(yaml_value) :: val

        if (.not. associated(node)) then
            val%node => null()
            return
        endif

        val%node => node
    end function

    !> Get string value from yaml_value
    !!
    !! @param[in] self Value container instance
    !! @return String value or empty string if invalid
    function get_string_value(self) result(str_val)
        class(yaml_value), intent(inout) :: self  ! Changed from intent(in) to intent(inout)
        character(len=:), allocatable :: str_val
        logical :: was_string

        if (.not. associated(self%node)) then
            str_val = ''
            write(error_unit,*) "DEBUG: Node not associated for string value"
            return
        endif

        ! Store if it was already marked as string
        was_string = self%node%is_string

        ! Force type determination if not already done
        call determine_value_type(self%node)

        ! If it wasn't originally a string but became one, or was one already
        if (self%node%is_string .or. was_string) then
            str_val = trim(self%node%value)
            write(error_unit,*) "DEBUG: Retrieved string value:", trim(str_val)
        else
            str_val = ''
            write(error_unit,*) "DEBUG: Node is not a string type. Type flags:", &
                              " is_string=", self%node%is_string, &
                              " is_integer=", self%node%is_integer, &
                              " is_float=", self%node%is_float, &
                              " is_boolean=", self%node%is_boolean
        endif
    end function

    !> Get integer value from yaml_value
    !!
    !! @param[in] self Value container instance
    !! @return Integer value or 0 if invalid
    function get_integer_value(self) result(int_val)
        class(yaml_value), intent(inout) :: self  ! Changed from intent(in) to intent(inout)
        integer :: int_val
        integer :: ios

        int_val = 0
        if (.not. associated(self%node)) then
            write(error_unit,*) "DEBUG: Node not associated for integer value"
            return
        endif

        ! Force type determination if not already done
        if (.not. self%node%is_integer) then
            call determine_value_type(self%node)
        endif

        if (self%node%is_integer) then
            read(self%node%value, *, iostat=ios) int_val
            if (ios /= 0) then
                write(error_unit,*) "DEBUG: Failed to convert value to integer:", trim(self%node%value)
                int_val = 0
            else
                write(error_unit,*) "DEBUG: Successfully converted to integer:", int_val
            endif
        else
            write(error_unit,*) "DEBUG: Node is not an integer type. Value:", trim(self%node%value)
        endif
    end function

    !> Get real value from yaml_value
    !!
    !! @param[in] self Value container instance
    !! @return Real value or 0.0 if invalid
    function get_real_value(self) result(real_val)
        class(yaml_value), intent(inout) :: self
        real :: real_val

        real_val = 0.0
        if (associated(self%node) .and. self%node%is_float) then
            read(self%node%value, *) real_val
        endif
    end function

    !> Get boolean value from yaml_value
    !!
    !! @param[in] self Value container instance
    !! @return Boolean value or false if invalid
    function get_boolean_value(self) result(bool_val)
        class(yaml_value), intent(inout) :: self
        logical :: bool_val

        bool_val = .false.
        if (associated(self%node) .and. self%node%is_boolean) then
            bool_val = (trim(self%node%value) == 'true')
        endif
    end function

    !> Check if value is null
    !!
    !! @param[in] self Value container instance
    !! @return True if value is null
    function check_null(self) result(is_null)
        class(yaml_value), intent(in) :: self
        logical :: is_null

        is_null = .not. associated(self%node) .or. self%node%is_null
    end function

    !> Check if value is a sequence
    !!
    !! @param[in] self Value container instance
    !! @return True if value is a sequence
    function check_sequence_impl(self) result(is_seq)
        class(yaml_value), intent(in) :: self
        logical :: is_seq

        is_seq = .false.
        if (associated(self%node)) then
            is_seq = check_sequence_node(self%node)
        endif
    end function check_sequence_impl

    !> Print yaml_node children keys
    !!
    !! @param[in] node Node to print
    !! @param[in] prefix Optional indentation prefix
    subroutine print_node_children(node, prefix)
        type(yaml_node), pointer, intent(in) :: node
        character(len=*), intent(in), optional :: prefix
        type(yaml_node), pointer :: current
        character(len=:), allocatable :: indent

        if (.not. associated(node)) then
            write(error_unit,*) "No node to print children"
            return
        endif

        indent = ""
        if (present(prefix)) indent = prefix

        write(error_unit,*) trim(indent)//"Node key:", trim(node%key)
        write(error_unit,*) trim(indent)//"Node value:", trim(node%value)
        write(error_unit,*) trim(indent)//"Has children:", associated(node%children)

        if (associated(node%children)) then
            write(error_unit,*) trim(indent)//"Children:"
            current => node%children
            do while (associated(current))
                write(error_unit,*) trim(indent)//"  -", trim(current%key), &
                                  " (value:", trim(current%value), ")", &
                                  " has_children:", associated(current%children)
                current => current%next
            end do
        endif
    end subroutine print_node_children

    !> Convert YAML node structure to dictionary
    !!
    !! @param[in] node Source node to convert
    !! @param[inout] dict Target dictionary
    recursive subroutine convert_node_to_dict(node, dict)
        type(yaml_node), pointer, intent(in) :: node
        type(yaml_dict), intent(inout) :: dict
        type(yaml_pair), pointer :: new_pair, last_pair, root_pair, current_node
        type(yaml_node), pointer :: current
        character(len=256) :: debug_msg
        logical :: is_root_level
        integer :: alloc_stat

        if (.not. associated(node)) then
            write(error_unit,*) "WARNING: Empty node passed to convert_node_to_dict"
            return
        endif

        current => node
        nullify(last_pair)
        nullify(root_pair)

        do while (associated(current))
            ! Check if this is a root-level node (no parent)
            is_root_level = (.not. associated(current%parent))
            if (is_root_level) then
                current%is_root = .true.  ! Changed from is_root_key to is_root
            endif

            ! Fix the format specifier to match the arguments
            write(debug_msg, '(A,A,A,I0,A,L1,A,I0)') "Converting node: ", &
                                             trim(current%value), &
                                             " at line ", current%line_num, &
                                             " root: ", is_root_level, &
                                             " indent: ", current%indent

            call debug_print(DEBUG_INFO, debug_msg)

            ! Create new pair
            allocate(new_pair, stat=alloc_stat)
            if (alloc_stat /= 0) then
                write(error_unit,*) "ERROR: Failed to allocate new pair"
                return
            endif

            ! Initialize new pair
            new_pair%key = trim(adjustl(current%key))
            nullify(new_pair%next)
            new_pair%value%node => current
            new_pair%indent_level = current%indent  ! Changed from indent_level to indent

            ! Handle nested structures
            if (associated(current%children)) then
                write(debug_msg, '(A,A,A,L1,A,I0)') "Creating nested dictionary for: ", &
                                             trim(current%key), &
                                             " (root level: ", is_root_level, &
                                             " indent: ", current%indent  ! Changed from indent_level to indent

                call debug_print(DEBUG_INFO, debug_msg)

                ! Create nested dictionary
                allocate(new_pair%nested, stat=alloc_stat)
                if (alloc_stat /= 0) then
                    write(error_unit,*) "ERROR: Failed to allocate nested dictionary"
                    deallocate(new_pair)
                    return
                endif

                ! Initialize nested dictionary
                new_pair%nested%first => null()
                new_pair%nested%count = 0

                ! Convert children
                call convert_node_to_dict(current%children, new_pair%nested)
            endif

            ! Link into dictionary based on root level status
            if (is_root_level) then
                ! For root-level nodes, start new chain
                if (.not. associated(dict%first)) then
                    dict%first => new_pair
                    root_pair => new_pair
                else
                    ! Link at root level
                    if (associated(root_pair)) then
                        root_pair%next => new_pair
                        root_pair => new_pair
                    else
                        ! Find end of root chain
                        root_pair => dict%first
                        do while (associated(root_pair%next))
                            root_pair => root_pair%next
                        end do
                        root_pair%next => new_pair
                        root_pair => new_pair
                    endif
                endif
                write(debug_msg, '(A,A)') "Added root level node: ", trim(new_pair%key)
                call debug_print(DEBUG_INFO, debug_msg)
            else
                ! For non-root nodes, maintain existing hierarchy
                if (.not. associated(last_pair)) then
                    ! Find correct parent based on hierarchy
                    if (associated(current%parent)) then
                        ! Follow parent's hierarchy
                        last_pair => dict%first
                        do while (associated(last_pair))
                            if (associated(last_pair%value%node, current%parent)) then
                                if (.not. associated(last_pair%nested)) then
                                    allocate(last_pair%nested)
                                    last_pair%nested%first => new_pair
                                else
                                    ! Find end of nested chain
                                    current_node => last_pair%nested%first
                                    if (associated(current_node)) then
                                        do while (associated(current_node%next))
                                            current_node => current_node%next
                                        end do
                                        current_node%next => new_pair
                                    else
                                        last_pair%nested%first => new_pair
                                    endif
                                endif
                                exit
                            endif
                            last_pair => last_pair%next
                        end do
                    endif
                else
                    last_pair%next => new_pair
                endif
            endif

            ! Update tracking for next iteration
            if (.not. is_root_level) then
                last_pair => new_pair
            endif
            dict%count = dict%count + 1

            ! Move to next node
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

    !> Get value associated with key from dictionary
    !!
    !! @param[in] this Dictionary instance
    !! @param[in] key Key to lookup
    !! @return Value associated with key
    function get_value(this, key) result(val)
        class(yaml_dict), intent(inout) :: this  ! Changed from intent(in) to intent(inout)
        character(len=*), intent(in) :: key
        type(yaml_value) :: val
        type(yaml_pair), pointer :: current
        character(len=:), allocatable, dimension(:) :: key_parts
        character(len=:), allocatable :: remaining_path
        integer :: i, path_start

        write(error_unit,*) "DEBUG: Dictionary get_value for key:", trim(key)
        val%node => null()

        ! Split key into parts
        key_parts = split_key(key)
        write(error_unit,*) "DEBUG: Looking for key part:", trim(key_parts(1))

        ! Start with first level search
        current => this%first
        do while (associated(current))
            write(error_unit,*) "DEBUG: Checking pair with key:", trim(current%key), &
                              " against target:", trim(key_parts(1))

            ! Do exact string comparison after trimming and adjusting
            if (trim(adjustl(current%key)) == trim(adjustl(key_parts(1)))) then
                write(error_unit,*) "DEBUG: Found first level match for:", trim(key_parts(1))

                if (size(key_parts) == 1) then
                    ! Direct match at this level
                    val%node => current%value%node
                    ! Ensure type is determined for direct matches
                    call determine_value_type(val%node)
                    write(error_unit,*) "DEBUG: Found direct match at first level"
                    write(error_unit,*) "DEBUG: Node has children:", associated(val%node%children)
                    write(error_unit,*) "DEBUG: Node value:", trim(val%node%value)
                    write(error_unit,*) "DEBUG: Is integer:", val%node%is_integer
                    return
                else
                    ! For nested access
                    val%node => current%value%node
                    write(error_unit,*) "DEBUG: Node children status:", associated(val%node%children)

                    if (.not. associated(val%node%children)) then
                        write(error_unit,*) "DEBUG: No children available for nested access"
                        val%node => null()
                    else
                        ! Get remaining path
                        path_start = len_trim(key_parts(1)) + 2
                        remaining_path = trim(key(path_start:))
                        write(error_unit,*) "DEBUG: Continuing with nested path:", trim(remaining_path)
                        val = val%get(remaining_path)
                    endif
                    return
                endif
            endif

            write(error_unit,*) "DEBUG: Moving to next pair"
            current => current%next
        end do

        write(error_unit,*) "DEBUG: Key not found in dictionary:", trim(key_parts(1))
        val%node => null()
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

        if (this%count > 0) then
            allocate(character(len=32) :: keys(this%count))
            keys = ""
            current => this%first
            i = 1
            do while (associated(current))
                keys(i) = current%key
                i = i + 1
                current => current%next
            end do
        else
            allocate(character(len=0) :: keys(0))
        endif
    end function get_keys

    !> Get nested value for yaml_value type
    !!
    !! @param[in] self Value container instance
    !! @param[in] key Nested key path with % delimiters
    !! @return Value at nested path
    recursive function get_value_nested(self, key) result(val)
        class(yaml_value), intent(inout) :: self
        character(len=*), intent(in) :: key
        type(yaml_value) :: val, temp_val
        character(len=:), allocatable, dimension(:) :: key_parts
        character(len=:), allocatable :: remaining_path
        type(yaml_node), pointer :: current
        integer :: i

        write(error_unit,*) "DEBUG: Starting get_value_nested for key:", trim(key)
        val%node => null()

        if (.not. associated(self%node)) then
            write(error_unit,*) "DEBUG: Initial node is not associated"
            return
        endif

        ! Split key into parts
        key_parts = split_key(key)
        write(error_unit,*) "DEBUG: Looking for first key part:", trim(key_parts(1))

        ! Handle direct children mode for better traversal
        current => self%node
        if (associated(current%children)) then
            current => current%children
        else
            write(error_unit,*) "DEBUG: Node has no children"
            return
        endif

        ! Search through children at this level
        do while (associated(current))
            write(error_unit,*) "DEBUG: Checking node key:", trim(current%key), &
                               " against target:", trim(key_parts(1))

            if (trim(adjustl(current%key)) == trim(adjustl(key_parts(1)))) then
                write(error_unit,*) "DEBUG: Found match for:", trim(key_parts(1))

                if (size(key_parts) == 1) then
                    ! Found final target
                    val%node => current
                    call determine_value_type(val%node)
                    write(error_unit,*) "DEBUG: Final target found with value:", trim(val%node%value)
                    return
                else
                    ! Need to traverse deeper
                    temp_val%node => current
                    write(error_unit,*) "DEBUG: Going deeper with node:", trim(current%key)

                    ! Build remaining path
                    remaining_path = ""
                    do i = 2, size(key_parts)
                        if (i > 2) remaining_path = trim(remaining_path) // "%"
                        remaining_path = trim(remaining_path) // trim(key_parts(i))
                    end do
                    write(error_unit,*) "DEBUG: Continuing with remaining path:", trim(remaining_path)
                    val = temp_val%get(remaining_path)
                    return
                endif
            endif
            current => current%next
        end do

        write(error_unit,*) "DEBUG: Key not found:", trim(key_parts(1))
    end function get_value_nested

    !> Get nested value for fyaml_doc type
    !!
    !! @param[in] self Document instance
    !! @param[in] path Nested path with % delimiters
    !! @param[in] doc_index Optional document index
    !! @return Value at nested path
    recursive function get_doc_nested(self, path, doc_index) result(val)
        class(fyaml_doc), intent(inout) :: self  ! Changed from intent(in) to intent(inout)
        character(len=*), intent(in) :: path
        integer, intent(in), optional :: doc_index
        type(yaml_value) :: val
        integer :: doc_idx

        doc_idx = 1  ! Default to first document
        if (present(doc_index)) doc_idx = doc_index

        if (doc_idx < 1 .or. doc_idx > self%n_docs) then
            val%node => null()
            return
        endif

        val = self%docs(doc_idx)%get(path)
    end function get_doc_nested

    !> Get nested string value
    !!
    !! @param[in] self Document instance
    !! @param[in] path Nested path with % delimiters
    !! @param[in] doc_index Optional document index
    !! @return String value at nested path
    function get_nested_str(self, path, doc_index) result(val)
        class(fyaml_doc), intent(inout) :: self  ! Changed from intent(in) to intent(inout)
        character(len=*), intent(in) :: path
        integer, intent(in), optional :: doc_index
        character(len=:), allocatable :: val
        type(yaml_value) :: temp

        write(error_unit,*) "DEBUG: Getting nested string for path:", trim(path)

        temp = self%get(path, doc_index)
        if (associated(temp%node)) then
            ! Force type determination
            call determine_value_type(temp%node)

            ! Mark as string if not already typed
            if (.not. (temp%node%is_integer .or. temp%node%is_float .or. &
                      temp%node%is_boolean .or. temp%node%is_null)) then
                temp%node%is_string = .true.
            endif

            write(error_unit,*) "DEBUG: Found node value:", trim(temp%node%value)
            write(error_unit,*) "DEBUG: Node type flags - string:", temp%node%is_string, &
                              " int:", temp%node%is_integer, &
                              " float:", temp%node%is_float, &
                              " bool:", temp%node%is_boolean

            ! Get string value
            val = trim(temp%node%value)
            write(error_unit,*) "DEBUG: Returning string value:", trim(val)
        else
            write(error_unit,*) "DEBUG: Node not found for path:", trim(path)
            val = ''
        endif
    end function get_nested_str

    !> Get nested integer value
    !!
    !! @param[in] self Document instance
    !! @param[in] path Nested path with % delimiters
    !! @param[in] doc_index Optional document index
    !! @return Integer value at nested path
    function get_nested_int(self, path, doc_index) result(val)
        class(fyaml_doc), intent(inout) :: self  ! Changed from intent(in) to intent(inout)
        character(len=*), intent(in) :: path
        integer, intent(in), optional :: doc_index
        integer :: val
        type(yaml_value) :: temp

        write(error_unit,*) "DEBUG: Getting nested integer for path:", trim(path)
        temp = self%get(path, doc_index)
        if (associated(temp%node)) then
            ! Force type determination
            call determine_value_type(temp%node)
            val = temp%get_int()
            write(error_unit,*) "DEBUG: Found integer value:", val
        else
            write(error_unit,*) "DEBUG: Node not found, returning 0"
            val = 0
        endif
    end function get_nested_int

    !> Get nested real value
    !!
    !! @param[in] self Document instance
    !! @param[in] path Nested path with % delimiters
    !! @param[in] doc_index Optional document index
    !! @return Real value at nested path
    function get_nested_real(self, path, doc_index) result(val)
        class(fyaml_doc), intent(inout) :: self  ! Changed from intent(in) to intent(inout)
        character(len=*), intent(in) :: path
        integer, intent(in), optional :: doc_index
        real :: val
        type(yaml_value) :: temp

        temp = self%get(path, doc_index)
        if (associated(temp%node)) then
            val = temp%get_real()
        else
            val = 0.0
        endif
    end function get_nested_real

    !> Get nested boolean value
    !!
    !! @param[in] self Document instance
    !! @param[in] path Nested path with % delimiters
    !! @param[in] doc_index Optional document index
    !! @return Boolean value at nested path
    function get_nested_bool(self, path, doc_index) result(val)
        class(fyaml_doc), intent(inout) :: self  ! Changed from intent(in) to intent(inout)
        character(len=*), intent(in) :: path
        integer, intent(in), optional :: doc_index
        logical :: val
        type(yaml_value) :: temp

        temp = self%get(path, doc_index)
        if (associated(temp%node)) then
            val = temp%get_bool()
        else
            val = .false.
        endif
    end function get_nested_bool

    !> Get specific document by index
    !!
    !! @param[in] this Document collection
    !! @param[in] doc_index Index of document to get
    !! @return Document at specified index
    function get_document(this, doc_index) result(val)
        class(fyaml_doc), intent(in) :: this
        integer, intent(in) :: doc_index
        type(yaml_dict) :: val  ! Changed from pointer to regular type

        if (doc_index > 0 .and. doc_index <= this%n_docs) then
            val = this%docs(doc_index)  ! Regular assignment instead of pointer assignment
        endif
    end function get_document

    !> Get value from default document (first document)
    !!
    !! @param[in] this Document collection
    !! @return First document in collection
    function get_default_doc(this) result(val)
        class(fyaml_doc), intent(in) :: this
        type(yaml_dict) :: val

        if (this%n_docs > 0) then
            val = this%docs(1)
        endif
    end function get_default_doc

    !> Find child node by key
    !!
    !! @param[in] node Parent node to search
    !! @param[in] search_key Key to find
    !! @return Value container for found child
    function find_child_by_key(node, search_key) result(found_val)
        type(yaml_node), pointer, intent(in) :: node
        character(len=*), intent(in) :: search_key
        type(yaml_value) :: found_val
        type(yaml_node), pointer :: current

        write(error_unit,*) "DEBUG: Searching for child with key:", trim(search_key)
        found_val%node => null()

        ! Search only immediate children
        if (associated(node%children)) then
            current => node%children
            do while (associated(current))
                write(error_unit,*) "DEBUG: Checking child node:", trim(current%key)
                if (trim(adjustl(current%key)) == trim(adjustl(search_key))) then
                    write(error_unit,*) "DEBUG: Found matching child node"
                    found_val%node => current
                    ! Preserve sequence flags
                    if (current%is_sequence .and. associated(current%children)) then
                        current%children%is_sequence = .true.
                    endif
                    return
                endif
                current => current%next
            end do
        endif
        write(error_unit,*) "DEBUG: Child not found"
    end function find_child_by_key

    !> Split a path by % delimiter
    !!
    !! @param[in] path Path string to split
    !! @return Array of path segments
    function split_key(path) result(parts)
        character(len=*), intent(in) :: path
        character(len=:), allocatable, dimension(:) :: parts
        integer :: n_parts, i, prev_pos, pos

        ! Count parts
        n_parts = 1
        do i = 1, len_trim(path)
            if (path(i:i) == '%') n_parts = n_parts + 1
        end do

        ! Allocate parts array
        allocate(character(len=32) :: parts(n_parts))

        ! Split string
        prev_pos = 1
        i = 1
        do
            pos = index(path(prev_pos:), '%')
            if (pos == 0) then
                parts(i) = trim(adjustl(path(prev_pos:)))
                exit
            endif
            parts(i) = trim(adjustl(path(prev_pos:prev_pos+pos-2)))
            prev_pos = prev_pos + pos
            i = i + 1
        end do

        ! Clean up each part
        do i = 1, n_parts
            parts(i) = trim(adjustl(parts(i)))
        end do
    end function split_key

    !> Determine the type of a node's value
    !!
    !! @param[inout] node Node to analyze
    subroutine determine_value_type(node)
        type(yaml_node), pointer, intent(inout) :: node
        integer :: int_val, ios
        real :: real_val
        character(len=:), allocatable :: cleaned_value

        ! Reset type flags
        if (.not. associated(node)) then
            write(error_unit,*) "DEBUG: Cannot determine type for null node"
            return
        endif

        node%is_integer = .false.
        node%is_float = .false.
        node%is_boolean = .false.
        node%is_string = .false.
        node%is_null = .false.

        ! Clean the value
        cleaned_value = trim(adjustl(node%value))

        if (len_trim(cleaned_value) == 0 .or. cleaned_value == '~') then
            node%is_null = .true.
            write(error_unit,*) "DEBUG: Value determined as null"
            return
        endif

        ! Try integer first
        read(cleaned_value, *, iostat=ios) int_val
        if (ios == 0 .and. index(cleaned_value, '.') == 0 .and. &
            index(cleaned_value, 'e') == 0 .and. index(cleaned_value, 'E') == 0) then
            node%is_integer = .true.
            write(error_unit,*) "DEBUG: Value determined as integer:", int_val
            return
        endif

        ! Try real
        read(cleaned_value, *, iostat=ios) real_val
        if (ios == 0) then
            node%is_float = .true.
            write(error_unit,*) "DEBUG: Value determined as real:", real_val
            return
        endif

        ! Check boolean
        if (cleaned_value == 'true' .or. cleaned_value == 'false') then
            node%is_boolean = .true.
            write(error_unit,*) "DEBUG: Value determined as boolean:", trim(cleaned_value)
            return
        endif

        ! Default to string
        node%is_string = .true.
        write(error_unit,*) "DEBUG: Value determined as string:", trim(cleaned_value)
    end subroutine determine_value_type

    !> Count direct children of a yaml_node
    !!
    !! @param[in] node Node to count children for
    !! @return Number of direct children
    function count_node_children(node) result(count)
        type(yaml_node), pointer, intent(in) :: node
        integer :: count
        type(yaml_node), pointer :: current

        count = 0
        if (.not. associated(node)) return
        if (.not. associated(node%children)) return

        current => node%children
        do while (associated(current))
            count = count + 1
            current => current%next
        end do
    end function count_node_children

    !> Count direct children of a yaml_value
    !!
    !! @param[in] val Value to count children for
    !! @return Number of direct children
    function count_value_children(val) result(count)
        type(yaml_value), intent(in) :: val
        integer :: count

        if (.not. associated(val%node)) then
            count = 0
            return
        endif

        count = count_node_children(val%node)
    end function count_value_children

    !> Get all child keys of a yaml_node
    !!
    !! @param[in] node Node to get children from
    !! @return Array of child key names
    function get_node_child_keys(node) result(keys)
        type(yaml_node), pointer, intent(in) :: node
        character(len=:), allocatable, dimension(:) :: keys
        type(yaml_node), pointer :: current
        integer :: count, i

        ! Initialize with empty array
        allocate(character(len=0) :: keys(0))

        ! Early return checks
        if (.not. associated(node)) return
        if (.not. associated(node%children)) return

        ! Count children first
        count = count_node_children(node)

        ! Allocate array for keys
        if (allocated(keys)) deallocate(keys)
        allocate(character(len=32) :: keys(count))

        ! Fill array with child keys
        current => node%children
        i = 1
        do while (associated(current))
            keys(i) = trim(adjustl(current%key))
            i = i + 1
            current => current%next
        end do
    end function get_node_child_keys

    !> Get all child keys of a yaml_value
    !!
    !! @param[in] val Value to get children from
    !! @return Array of child key names
    function get_value_child_keys(val) result(keys)
        class(yaml_value), intent(in) :: val
        character(len=:), allocatable, dimension(:) :: keys

        if (.not. associated(val%node)) then
            allocate(character(len=0) :: keys(0))
            return
        endif

        keys = get_node_child_keys(val%node)
    end function get_value_child_keys

    !> Get child value at specified index
    !!
    !! @param[in] self Value container instance
    !! @param[in] idx Index of child to retrieve (1-based)
    !! @return Value container for child at index or null if invalid
    function get_child_at_index(self, idx) result(val)
        class(yaml_value), intent(in) :: self
        integer, intent(in) :: idx
        type(yaml_value) :: val
        type(yaml_node), pointer :: current
        integer :: current_idx

        ! Initialize result
        val%node => null()

        ! Check for valid node and children
        if (.not. associated(self%node)) return
        if (.not. associated(self%node%children)) return
        if (idx < 1) return

        ! Traverse to desired index
        current => self%node%children
        current_idx = 1

        do while (associated(current))
            if (current_idx == idx) then
                val%node => current
                return
            endif
            current => current%next
            current_idx = current_idx + 1
        end do
    end function get_child_at_index

    !> Get sequence values as an array of strings
    !!
    !! @param[in] self Value container instance
    !! @return Array of sequence values as strings
    function get_sequence_values(self) result(values)
        class(yaml_value), intent(in) :: self
        character(len=:), allocatable, dimension(:) :: values
        type(yaml_node), pointer :: current
        integer :: count, i

        ! Initialize with empty array
        allocate(character(len=0) :: values(0))

        ! Early return checks
        if (.not. associated(self%node)) return
        if (.not. associated(self%node%children)) return
        if (.not. self%is_sequence()) return

        ! Count items first
        count = count_node_children(self%node)
        if (count == 0) return

        ! Allocate array for values
        if (allocated(values)) deallocate(values)
        allocate(character(len=32) :: values(count))

        ! Fill array with values
        current => self%node%children
        i = 1
        do while (associated(current))
            values(i) = trim(adjustl(current%value))
            i = i + 1
            current => current%next
        end do
    end function get_sequence_values

    !> Get sequence values as integers
    !!
    !! @param[in] self Value container instance
    !! @return Array of sequence values as integers
    function get_sequence_integers(self) result(values)
        class(yaml_value), intent(in) :: self
        integer, allocatable, dimension(:) :: values
        type(yaml_node), pointer :: current
        integer :: count, i, ios

        ! Initialize with empty array
        allocate(values(0))

        ! Early return checks
        if (.not. associated(self%node)) return
        if (.not. associated(self%node%children)) return
        if (.not. self%is_sequence()) return

        ! Count and allocate
        count = count_node_children(self%node)
        if (count == 0) return

        if (allocated(values)) deallocate(values)
        allocate(values(count))
        values = 0  ! Initialize to default value

        ! Fill array with integer values
        current => self%node%children
        i = 1
        do while (associated(current))
            read(current%value, *, iostat=ios) values(i)
            if (ios /= 0) values(i) = 0  ! Set to 0 if conversion fails
            i = i + 1
            current => current%next
        end do
    end function get_sequence_integers

    !> Get sequence values as reals
    !!
    !! @param[in] self Value container instance
    !! @return Array of sequence values as reals
    function get_sequence_reals(self) result(values)
        class(yaml_value), intent(in) :: self
        real, allocatable, dimension(:) :: values
        type(yaml_node), pointer :: current
        integer :: count, i, ios

        ! Initialize with empty array
        allocate(values(0))

        ! Early return checks
        if (.not. associated(self%node)) return
        if (.not. associated(self%node%children)) return
        if (.not. self%is_sequence()) return

        ! Count and allocate
        count = count_node_children(self%node)
        if (count == 0) return

        if (allocated(values)) deallocate(values)
        allocate(values(count))
        values = 0.0  ! Initialize to default value

        ! Fill array with real values
        current => self%node%children
        i = 1
        do while (associated(current))
            read(current%value, *, iostat=ios) values(i)
            if (ios /= 0) values(i) = 0.0  ! Set to 0.0 if conversion fails
            i = i + 1
            current => current%next
        end do
    end function get_sequence_reals

    !> Get sequence values as logicals
    !!
    !! @param[in] self Value container instance
    !! @return Array of sequence values as logicals
    function get_sequence_bools(self) result(values)
        class(yaml_value), intent(in) :: self
        logical, allocatable, dimension(:) :: values
        type(yaml_node), pointer :: current
        integer :: count, i

        ! Initialize with empty array
        allocate(values(0))

        ! Early return checks
        if (.not. associated(self%node)) return
        if (.not. associated(self%node%children)) return
        if (.not. self%is_sequence()) return

        ! Count and allocate
        count = count_node_children(self%node)
        if (count == 0) return

        if (allocated(values)) deallocate(values)
        allocate(values(count))
        values = .false.  ! Initialize to default value

        ! Fill array with boolean values
        current => self%node%children
        i = 1
        do while (associated(current))
            values(i) = (trim(adjustl(current%value)) == 'true')
            i = i + 1
            current => current%next
        end do
    end function get_sequence_bools

    !> Get the size of a sequence
    !!
    !! @param[in] self Value container instance
    !! @return Size of sequence or 0 if not a sequence/invalid
    function get_sequence_size(self) result(size)
        class(yaml_value), intent(in) :: self
        integer :: size

        size = 0
        if (.not. associated(self%node)) return
        if (.not. self%is_sequence()) return

        size = count_node_children(self%node)

    end function get_sequence_size

    !> Get all root keys from the document
    !!
    !! @param[in] this Document instance
    !! @return Array of root key names
    function get_root_keys(this) result(keys)
        class(fyaml_doc), intent(in) :: this
        character(len=:), allocatable, dimension(:) :: keys
        type(yaml_pair), pointer :: current
        integer :: count, i

        ! Count root level pairs
        count = 0
        current => this%docs(1)%first
        do while (associated(current))
            if (associated(current%value%node) .and. current%value%node%is_root) then ! Changed from is_root_key
                count = count + 1
            endif
            current => current%next
        end do

        ! Allocate array for keys
        if (count > 0) then
            allocate(character(len=32) :: keys(count))
            keys = ""

            ! Fill array with root keys
            current => this%docs(1)%first
            i = 1
            do while (associated(current))
                if (associated(current%value%node) .and. current%value%node%is_root) then ! Changed from is_root_key
                    keys(i) = current%key
                    i = i + 1
                endif
                current => current%next
            end do
        else
            allocate(character(len=0) :: keys(0))
        endif
    end function get_root_keys

end module fyaml

!> Test utilities for YAML parser
!!
!! Provides comprehensive test coverage for YAML parsing functionality.
!! Includes tests for all supported data types and structures.
module test_utils
    use fyaml
    use yaml_parser, only: DEBUG_INFO, debug_print
    use yaml_types, only: yaml_node
    use iso_fortran_env, only: error_unit
    implicit none
    private

    ! Make test functions public
    public :: test_basic_loading
    public :: test_basic_types
    public :: test_sequences
    public :: test_root_keys
    public :: test_nested_access
    public :: test_get_value
    public :: test_get_values
    public :: test_multiple_docs
    public :: ERR_SUCCESS

    ! Error codes - properly define ERR_ALLOC
    integer, parameter :: ERR_SUCCESS = 0
    integer, parameter :: ERR_ASSERT = 1
    integer, parameter :: ERR_ALLOC = 2

    ! Debug level
    integer, parameter :: DEBUG = DEBUG_INFO  ! Use DEBUG_INFO from yaml_parser

    ! Test files
    character(len=*), parameter :: TEST_FILE = SOURCE_DIR//"/test_example.yaml"
    character(len=*), parameter :: TEST_MULTI_DOC_FILE = SOURCE_DIR//"/test_example_multi_doc.yaml"

    ! Remove duplicate test data - consolidate into single section
    ! Test data parameters
    integer, parameter :: flow_seq_int(3) = [1, 2, 4]
    real, parameter :: flow_seq_real(3) = [1.1, -2.2, 3.3]
    logical, parameter :: flow_seq_log(3) = [.true., .false., .true.]
    character(len=5), parameter :: flow_seq_str(3) = ["one  ", "two  ", "three"]
    character(len=5), parameter :: block_seq_str(3) = ["three", "four ", "five "]
    integer, parameter :: block_seq_int(3) = [4, 5, 6]
    ! Add new test data parameters
    real, parameter :: block_seq_real(3) = [4.4858292, 1.0e-10, -0.01]
    logical, parameter :: block_seq_log(3) = [.true., .false., .true.]

    ! Test keys
    character(len=*), parameter :: KEY_COMPANY = "company"
    character(len=*), parameter :: KEY_FLOW_SEQ = "flow_sequence"
    character(len=*), parameter :: KEY_FLOW_REAL = "flow_sequence_real"
    character(len=*), parameter :: KEY_FLOW_LOG = "flow_sequence_logical"
    character(len=*), parameter :: KEY_FLOW_STR = "flow_sequence_string"
    character(len=*), parameter :: KEY_BLOCK_STR = "block_sequence_string"
    character(len=*), parameter :: KEY_BLOCK_INT = "block_sequence_int"
    character(len=*), parameter :: KEY_BLOCK_REAL = "block_sequence_real"
    character(len=*), parameter :: KEY_BLOCK_LOG = "block_sequence_logical"

    interface assert_equal
        module procedure assert_equal_int
        module procedure assert_equal_string
        module procedure assert_equal_logical
        module procedure assert_equal_real
    end interface

contains
    ! Group 1: Basic Type Tests
    subroutine assert_equal_int(expected, actual, message, status)
        integer, intent(in) :: expected, actual
        character(len=*), intent(in) :: message
        integer, intent(out) :: status
        status = ERR_SUCCESS
        ! write(*,*) 'Comparing: ', expected, actual
        if (expected /= actual) then
            print *, 'FAILED: ', message
            print *, 'Expected: ', expected, ' Got: ', actual
            status = ERR_ASSERT
        else
            status = ERR_SUCCESS
        end if
    end subroutine

    ! Update real assertion to match interface
    subroutine assert_equal_real(expected, actual, message, status)
        real, intent(in) :: expected, actual
        character(len=*), intent(in) :: message
        integer, intent(out) :: status
        real, parameter :: tolerance = 1.0e-6

        status = ERR_SUCCESS
        if (abs(expected - actual) > tolerance) then
            write(error_unit,*) "FAILED:", message
            write(error_unit,*) "Expected:", expected, " Got:", actual
            status = ERR_ASSERT
        endif
    end subroutine assert_equal_real

    subroutine assert_equal_logical(expected, actual, message, status)
        logical, intent(in) :: expected, actual
        character(len=*), intent(in) :: message
        integer, intent(out) :: status
        if (.not. (expected .eqv. actual)) then
            write(error_unit,*) 'FAILED: ', message
            write(error_unit,*) 'Expected: ', expected, ' Got: ', actual
            status = ERR_ASSERT
        else
            status = ERR_SUCCESS
        end if
    end subroutine

    subroutine assert_equal_string(expected, actual, message, status)
        character(len=*), intent(in) :: expected, actual, message
        character(len=:), allocatable :: exp_val, act_val
        integer :: alloc_status
        integer, intent(out) :: status

        call allocate_string_value(exp_val, expected, alloc_status)
        if (alloc_status /= 0) then
            write(error_unit,*) 'FAILED: Memory allocation error for expected value'
            status = ERR_ALLOC
            return
        end if

        call allocate_string_value(act_val, actual, alloc_status)
        if (alloc_status /= 0) then
            print *, 'FAILED: Memory allocation error for actual value'
            if (allocated(exp_val)) deallocate(exp_val)
            status = ERR_ALLOC
            return
        end if

        if (exp_val /= act_val) then
            print *, 'FAILED: ', message
            print *, 'Expected: ', trim(exp_val), ' Got: ', trim(act_val)
            status = ERR_ASSERT
        else
            status = ERR_SUCCESS
        end if

        if (allocated(exp_val)) deallocate(exp_val)
        if (allocated(act_val)) deallocate(act_val)
    end subroutine

    ! Helper for safe string allocation
    subroutine safe_allocate_string(str, length, status)
        character(len=:), allocatable, intent(out) :: str
        integer, intent(in) :: length
        integer, intent(out) :: status

        if (allocated(str)) deallocate(str)
        allocate(character(len=length) :: str, stat=status)
        if (status /= 0) then
            write(error_unit,*) "Failed to allocate string of length", length
        end if
    end subroutine

    ! Allocation helper
    subroutine allocate_string_value(val, str, status)
        character(len=:), allocatable, intent(out) :: val
        character(len=*), intent(in) :: str
        integer, intent(out) :: status

        if (allocated(val)) deallocate(val)
        allocate(character(len=len_trim(str)) :: val, stat=status)
        if (status == 0) then
            val = trim(str)
        end if
    end subroutine

    ! Test routines returning status
    integer function test_basic_loading()
        type(fyaml_doc) :: doc
        character(len=*), parameter :: filename = TEST_FILE
        logical :: success

        test_basic_loading = ERR_SUCCESS
        write(*,*) 'Loading file:', trim(filename)
        call doc%load(filename, success)
        if (.not. success) then
            write(error_unit,*) 'Error loading YAML document.'
            test_basic_loading = ERR_ALLOC
            return
        endif
        write(*,*) 'YAML document loaded successfully.'
    end function

    integer function test_basic_types()
        type(fyaml_doc) :: doc
        type(yaml_value) :: val
        character(len=:), allocatable :: key
        integer :: status, node_count
        character(len=:), allocatable, dimension(:) :: node_keys

        test_basic_types = ERR_SUCCESS
        ! Initialize node_keys to avoid warning
        allocate(character(len=0) :: node_keys(0))

        call safe_allocate_string(key, 20, status)
        if (status /= 0) then
            write(error_unit,*) "Failed to allocate key string"
            test_basic_types = ERR_ALLOC
            return
        endif

        call doc%load(TEST_FILE)

        ! Get company node and validate
        key = "company"
        val = doc%get(key)  ! Replace doc%root%get
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company node"
            test_basic_types = ERR_ASSERT
            return
        endif

        ! Get node keys with proper checks
        if (associated(val%node) .and. associated(val%node%children)) then
            if (allocated(node_keys)) deallocate(node_keys)
            node_keys = get_sequence_as_strings(val%node)
            node_count = size(node_keys, dim=1)
        else
            if (allocated(node_keys)) deallocate(node_keys)
            allocate(character(len=0) :: node_keys(0))
            node_count = 0
        endif

        call assert_equal(16, node_count, "Number of keys in company", status)
        if (status /= ERR_SUCCESS) then
            test_basic_types = status
            return
        endif

        ! Test string value
        val = doc%get("company%name")  ! Add parent key to path
        call assert_equal("Example Corp", val%get_str(), "String value test", status)
        if (status /= ERR_SUCCESS) then
            test_basic_types = status
            return
        endif

        ! Test integer values
        val = doc%get("company%founded")  ! Add parent key to path
        call assert_equal(2001, val%get_int(), "Integer value test (founded)", status)
        if (status /= ERR_SUCCESS) then
            test_basic_types = status
            return
        endif

        val = doc%get("company%employees")  ! Add parent key to path
        call assert_equal(150, val%get_int(), "Integer value test (employees)", status)
        if (status /= ERR_SUCCESS) then
            test_basic_types = status
            return
        endif

        ! Test real value
        val = doc%get("company%pi")  ! Add parent key to path
        call assert_equal(3.141590, val%get_real(), "Real value test", status)
        if (status /= ERR_SUCCESS) then
            test_basic_types = status
            return
        endif

        ! Test null value
        val = doc%get("company%goodness")
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%goodness node"
            test_basic_types = ERR_ASSERT
            return
        endif

        ! Test if the value is actually null
        call assert_equal(.true., val%is_null(), "Null value test", status)
        if (status /= ERR_SUCCESS) then
            write(error_unit,*) "Value:", trim(val%node%value)
            write(error_unit,*) "Is null:", val%node%is_null
            test_basic_types = status
            return
        endif

        ! Test boolean value
        val = doc%get("company%okay")  ! Add parent key to path
        call assert_equal(.true., val%get_bool(), "Boolean value test", status)
        if (status /= ERR_SUCCESS) then
            test_basic_types = status
            return
        endif

        if (allocated(key)) deallocate(key)
    end function test_basic_types

    ! Group 2: Sequence Tests
    function test_sequences() result(status)
        type(fyaml_doc) :: doc
        type(yaml_value) :: val, company_node
        integer :: i, status, seq_size, ios
        character(len=:), allocatable, dimension(:) :: seq_items
        integer :: val_int
        real :: val_real
        logical :: val_bool
        logical :: success
        type(yaml_node), pointer :: current  ! Add this declaration

        status = ERR_SUCCESS
        call doc%load(TEST_FILE)

        ! Initialize seq_items to avoid warning
        allocate(character(len=0) :: seq_items(0))

        ! Get company node first
        val = doc%get("company")  ! Replace doc%root%get
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company node"
            status = ERR_ASSERT
            return
        endif
        company_node = val  ! Store company node for later use

        write(error_unit,*) "Testing company node children"
        if (.not. associated(val%node%children)) then
            write(error_unit,*) "Company node has no children"
            status = ERR_ASSERT
            return
        endif

        ! Navigate through children to find flow_sequence
        write(error_unit,*) "Finding flow_sequence in children"
        val = find_value_by_key(val%node%children, "flow_sequence")
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to find flow_sequence in company children"
            status = ERR_ASSERT
            return
        endif

        write(error_unit,*) "Node value:", trim(val%node%value)
        write(error_unit,*) "Is sequence:", val%node%is_sequence
        write(error_unit,*) "Has children:", associated(val%node%children)

        ! Process sequence items with proper checks
        write(error_unit,*) "Processing sequence items"
        if (associated(val%node) .and. associated(val%node%children)) then
            if (allocated(seq_items)) deallocate(seq_items)
            seq_items = get_sequence_as_strings(val%node)
            seq_size = size(seq_items, dim=1)
        else
            if (allocated(seq_items)) deallocate(seq_items)
            allocate(character(len=0) :: seq_items(0))
            seq_size = 0
        endif

        write(error_unit,*) "Found sequence of size:", seq_size
        write(error_unit,*) "Raw items:", seq_items

        call assert_equal(size(flow_seq_int), seq_size, "Integer sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            write(error_unit,*) "Converting item:", trim(adjustl(seq_items(i)))
            val_int = safe_string_to_int(seq_items(i), success)
            if (.not. success) then
                write(error_unit,*) "Failed to convert:", trim(adjustl(seq_items(i)))
                status = ERR_ASSERT
                return
            endif
            call assert_equal(flow_seq_int(i), val_int, "Integer element", status)
            if (status /= ERR_SUCCESS) return
        end do

        ! Test real sequence
        write(error_unit,*) "Testing real sequence..."
        write(error_unit,*) "Looking for key:", KEY_FLOW_REAL
        val = find_value_by_key(company_node%node%children, KEY_FLOW_REAL)

        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to find real sequence node with key:", KEY_FLOW_REAL
            write(error_unit,*) "Available keys in company node:"
            call debug_print_available_keys(company_node%node%children)
            status = ERR_ASSERT
            return
        endif

        ! Set sequence flag explicitly
        val%node%is_sequence = .true.
        if (associated(val%node%children)) then
            val%node%children%is_sequence = .true.
        endif

        write(error_unit,*) "Found real sequence node. Value:", trim(val%node%value)
        write(error_unit,*) "Is sequence:", val%node%is_sequence
        write(error_unit,*) "Has children:", associated(val%node%children)

        seq_items = get_sequence_as_strings(val%node)
        seq_size = size(seq_items, dim=1)  ! Add dim=1 to be explicit

        call assert_equal(size(flow_seq_real), seq_size, "Real sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            read(seq_items(i), '(F20.10)', iostat=ios) val_real  ! Fixed format for real reading
            if (ios /= 0) then
                write(error_unit,*) "Failed to convert:", trim(adjustl(seq_items(i))), &
                                  " Error code:", ios
                status = ERR_ASSERT
                return
            endif
            call assert_equal(flow_seq_real(i), val_real, "Real element", status)
            if (status /= ERR_SUCCESS) return
        end do

        ! Test logical sequence
        write(*,*) '------------ FLOW SEQUENCE LOGICAL ------------'
        val = company_node%get(KEY_FLOW_LOG)
        if (.not. val%is_sequence()) then
            write(error_unit,*) "Expected sequence type for logical sequence"
            status = ERR_ASSERT
            return
        endif

        seq_items = get_sequence_as_strings(val%node)
        seq_size = size(seq_items, dim=1)  ! Add dim=1 to be explicit

        call assert_equal(size(flow_seq_log), seq_size, "Logical sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            val_bool = (trim(seq_items(i)) == 'true')
            call assert_equal(flow_seq_log(i), val_bool, "Logical element", status)
            if (status /= ERR_SUCCESS) return
        end do

        ! Test block sequence
        write(*,*) '------------ BLOCK SEQUENCE INT ------------'
        val = company_node%get(KEY_BLOCK_INT)
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to find block sequence node"
            status = ERR_ASSERT
            return
        endif

        ! Debug sequence info
        write(error_unit,*) "Block sequence node:"
        write(error_unit,*) "  Key:", trim(val%node%key)
        write(error_unit,*) "  Value:", trim(val%node%value)
        write(error_unit,*) "  Is sequence:", val%node%is_sequence
        write(error_unit,*) "  Has children:", associated(val%node%children)

        ! Get sequence items
        seq_items = get_sequence_as_strings(val%node)
        seq_size = size(seq_items, dim=1)  ! Add dim=1 to be explicit

        write(*,*) "Sequence length:", seq_size
        if (seq_size > 0) then
            write(*,*) "Raw sequence elements:", seq_items
        endif

        call assert_equal(size(block_seq_int), seq_size, "Block integer sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            write(error_unit,*) "Converting item:", trim(adjustl(seq_items(i)))
            read(seq_items(i), *, iostat=ios) val_int
            if (ios /= 0) then
                write(error_unit,*) "Failed to convert:", trim(adjustl(seq_items(i))), &
                                  " Error code:", ios
                status = ERR_ASSERT
                return
            endif
            call assert_equal(block_seq_int(i), val_int, "Block integer element", status)
            if (status /= ERR_SUCCESS) return
        end do

        ! Ensure sequence flags are set
        val%node%is_sequence = .true.
        if (associated(val%node%children)) then
            current => val%node%children
            do while (associated(current))
                current%is_sequence = .true.
                current => current%next
            end do
        endif

        ! Debug sequence info
        write(error_unit,*) "Block sequence node:"
        write(error_unit,*) "  Key:", trim(val%node%key)
        write(error_unit,*) "  Value:", trim(val%node%value)
        write(error_unit,*) "  Is sequence:", val%node%is_sequence
        write(error_unit,*) "  Has children:", associated(val%node%children)
        write(error_unit,*) "  Sequence type:"

        if (associated(val%node%children)) then
            current => val%node%children
            write(error_unit,*) "Children values:"
            do while (associated(current))
                write(error_unit,*) "  -", trim(current%value)
                current => current%next
            end do
        endif

        seq_items = get_sequence_as_strings(val%node)
        seq_size = size(seq_items, dim=1)  ! Add dim=1 to be explicit

        write(*,*) "Sequence length:", seq_size
        if (seq_size > 0) then
            write(*,*) "Sequence elements:", seq_items
        endif

        call assert_equal(size(block_seq_int), seq_size, "Block integer sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            read(seq_items(i), *) val_int
            call assert_equal(block_seq_int(i), val_int, "Block integer element", status)
            if (status /= ERR_SUCCESS) return
        end do

        ! Test block sequence real values
        write(*,*) '------------ BLOCK SEQUENCE REAL ------------'
        val = company_node%get(KEY_BLOCK_REAL)
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to find block real sequence node"
            status = ERR_ASSERT
            return
        endif

        seq_items = get_sequence_as_strings(val%node)
        seq_size = size(seq_items, dim=1)  ! Add dim=1 to be explicit

        call assert_equal(size(block_seq_real), seq_size, "Block real sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            read(seq_items(i), *, iostat=ios) val_real
            if (ios /= 0) then
                write(error_unit,*) "Failed to convert real:", trim(adjustl(seq_items(i))), &
                                  " Error code:", ios
                status = ERR_ASSERT
                return
            endif
            call assert_equal(block_seq_real(i), val_real, "Block real element", status)
            if (status /= ERR_SUCCESS) return
        end do

        ! Test block sequence logical values
        write(*,*) '------------ BLOCK SEQUENCE LOGICAL ------------'
        val = company_node%get(KEY_BLOCK_LOG)
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to find block logical sequence node"
            status = ERR_ASSERT
            return
        endif

        seq_items = get_sequence_as_strings(val%node)
        seq_size = size(seq_items, dim=1)  ! Add dim=1 to be explicit

        call assert_equal(size(block_seq_log), seq_size, "Block logical sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            val_bool = (trim(adjustl(seq_items(i))) == 'true')
            call assert_equal(block_seq_log(i), val_bool, "Block logical element", status)
            if (status /= ERR_SUCCESS) return
        end do

        ! Test block sequence string values
        write(*,*) '------------ BLOCK SEQUENCE STRING ------------'
        val = company_node%get(KEY_BLOCK_STR)
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to find block string sequence node"
            status = ERR_ASSERT
            return
        endif

        seq_items = get_sequence_as_strings(val%node)
        seq_size = size(seq_items, dim=1)  ! Add dim=1 to be explicit

        call assert_equal(size(block_seq_str), seq_size, "Block string sequence size", status)
        if (status /= ERR_SUCCESS) return

        do i = 1, seq_size
            call assert_equal(block_seq_str(i), trim(adjustl(seq_items(i))), "Block string element", status)
            if (status /= ERR_SUCCESS) return
        end do

    contains
        function find_value_by_key(node, search_key) result(found_val)
            type(yaml_node), pointer, intent(in) :: node
            character(len=*), intent(in) :: search_key
            type(yaml_value) :: found_val
            type(yaml_node), pointer :: current

            found_val%node => null()
            current => node
            write(error_unit,*) "Searching for key:", trim(search_key)
            do while (associated(current))
                write(error_unit,*) "Checking node key:", trim(current%key)
                if (trim(adjustl(current%key)) == trim(adjustl(search_key))) then
                    found_val%node => current
                    write(error_unit,*) "Found matching key"
                    return
                endif
                current => current%next
            end do
            write(error_unit,*) "Key not found:", trim(search_key)
        end function find_value_by_key

        ! Add debug helper
        subroutine debug_print_available_keys(node)
            type(yaml_node), pointer, intent(in) :: node
            type(yaml_node), pointer :: current

            current => node
            do while (associated(current))
                write(error_unit,*) "  -", trim(current%key)
                current => current%next
            end do
        end subroutine

        ! Helper function to print node structure
        recursive subroutine debug_print_node(node, prefix)
            type(yaml_node), pointer :: node
            character(len=*), intent(in) :: prefix
            type(yaml_node), pointer :: current

            current => node
            do while (associated(current))
                write(error_unit,*) prefix, "Key:", trim(current%key), &
                                  "Value:", trim(current%value), &
                                  "Is sequence:", current%is_sequence
                if (associated(current%children)) then
                    call debug_print_node(current%children, prefix//"  ")
                endif
                current => current%next
            end do
        end subroutine debug_print_node

    end function test_sequences

    ! Move get_sequence_as_strings to module level
    function get_sequence_as_strings(node) result(items)
        type(yaml_node), pointer, intent(in) :: node
        character(len=:), allocatable, dimension(:) :: items
        type(yaml_node), pointer :: current
        integer :: count, i, alloc_stat
        character(len=256) :: debug_msg

        ! Initialize with empty array
        allocate(character(len=0) :: items(0))

        ! Early return checks
        if (.not. associated(node)) return
        if (.not. associated(node%children)) return

        ! Count items and allocate
        count = 0
        current => node%children
        do while (associated(current))
            count = count + 1
            current => current%next
        end do
        ! Allocate and fill array
        if (count > 0) then
            if (allocated(items)) deallocate(items)
            allocate(character(len=32) :: items(count), stat=alloc_stat)
            if (alloc_stat /= 0) return

            current => node%children
            i = 1
            do while (associated(current))
                items(i) = trim(adjustl(current%value))
                write(debug_msg, '(A,I0,A,A)') "Item ", i, ": ", trim(items(i))
                call debug_print(DEBUG_INFO, debug_msg)
                i = i + 1
                current => current%next
            end do
        endif
    end function get_sequence_as_strings

    ! Add helper function for safe string to integer conversion
    function safe_string_to_int(str, success) result(val_int)
        character(len=*), intent(in) :: str
        logical, intent(out) :: success
        integer :: val_int
        character(len=:), allocatable :: clean_str
        integer :: dot_pos, ios

        success = .false.
        val_int = 0

        ! Clean the string
        clean_str = trim(adjustl(str))

        ! Find and remove any decimal part
        dot_pos = index(clean_str, '.')
        if (dot_pos > 0) then
            clean_str = clean_str(1:dot_pos-1)
        endif

        ! Try to read the integer
        read(clean_str, *, iostat=ios) val_int
        if (ios == 0) then
            success = .true.
        endif
    end function

    subroutine test_value_getters()
        type(yaml_value) :: val
        type(yaml_node), pointer :: test_node
        integer :: status

        ! Test string value
        allocate(test_node)
        test_node%value = "Example Corp"
        test_node%is_string = .true.
        val%node => test_node
        call assert_equal("Example Corp", val%get_str(), "String value test", status)
        deallocate(test_node)

        ! Rest of value getter tests...
        ! Test integer value
        allocate(test_node)
        test_node%value = "2001"
        test_node%is_integer = .true.
        val%node => test_node
        call assert_equal(val%get_int(), 2001, "Integer value test", status)
        deallocate(test_node)

        ! Test real value
        allocate(test_node)
        test_node%value = "3.14159"
        test_node%is_float = .true.
        val%node => test_node
        call assert_equal(val%get_real(), 3.14159, "Real value test", status)
        deallocate(test_node)

        ! Test boolean value
        allocate(test_node)
        test_node%value = "true"
        test_node%is_boolean = .true.
        val%node => test_node
        call assert_equal(val%get_bool(), .true., "Boolean value test", status)
        deallocate(test_node)

        ! Test null value
        val%node => null()
        call assert_equal(val%is_null(), .true., "Null value test", status)

        ! Test sequence
        allocate(test_node)
        test_node%is_sequence = .true.
        val%node => test_node
        call assert_equal(val%is_sequence(), .true., "Sequence test", status)
        deallocate(test_node)
    end subroutine

    ! Group 3: Nested Access Tests
    ! Add new test function for nested access
    integer function test_nested_access()
        type(fyaml_doc) :: doc
        type(yaml_value) :: val
        character(len=:), allocatable :: str_val
        integer :: int_val, val_int, status
        real :: real_val
        logical :: success

        test_nested_access = ERR_SUCCESS

        ! Load test file
        call doc%load(TEST_FILE, success)
        if (.not. success) then
            write(error_unit,*) "Failed to load YAML file"
            test_nested_access = ERR_ALLOC
            return
        endif

        ! Test multi-level access using % delimiter
        write(*,*) ' ->>>>>>>>>>>> testing company%name ->>>>>>>>>>>>'
        val = doc%get("company%name")
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%name"
            test_nested_access = ERR_ASSERT
            return
        endif
        str_val = val%get_str()
        write(error_unit,*) "Got nested string:", trim(str_val)
        if (str_val /= "Example Corp") then
            write(error_unit,*) "Wrong nested string value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test sequence access
         write(*,*) ' ->>>>>>>>>>>> testing company%employees ->>>>>>>>>>>>'
        val = doc%get("company%employees")
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%employees"
            test_nested_access = ERR_ASSERT
            return
        endif
        int_val = val%get_int()
        write(error_unit,*) "Got nested integer:", int_val
        if (int_val /= 150) then
            write(error_unit,*) "Wrong nested integer value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test deep nesting with sequences
         write(*,*) ' ->>>>>>>>>>>> testing company%pi ->>>>>>>>>>>>'
        val = doc%get("company%pi")
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%pi"
            test_nested_access = ERR_ASSERT
            return
        endif
        real_val = val%get_real()
        write(error_unit,*) "Got deeply nested real:", real_val
        if (abs(real_val - 3.14159) > 1.0e-5) then
            write(error_unit,*) "Wrong deeply nested real value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test all value types with nested access
        ! Integer test
        write(*,*) ' ->>>>>>>>>>>> testing integer company%employees ->>>>>>>>>>>>'
        int_val = doc%get_int("company%employees")
        write(error_unit,*) "Got nested integer:", int_val
        if (int_val /= 150) then
            write(error_unit,*) "Wrong nested integer value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Real test
        write(*,*) ' ->>>>>>>>>>>> testing real company%pi ->>>>>>>>>>>>'
        real_val = doc%get_real("company%pi")
        write(error_unit,*) "Got nested real:", real_val
        if (abs(real_val - 3.14159) > 1.0e-5) then
            write(error_unit,*) "Wrong nested real value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Boolean test
        write(*,*) ' ->>>>>>>>>>>> testing boolean company%okay ->>>>>>>>>>>>'
        if (.not. doc%get_bool("company%okay")) then
            write(error_unit,*) "Wrong nested boolean value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Deep nesting test
        write(*,*) ' ->>>>>>>>>>>> testing deep nested integer ->>>>>>>>>>>>'
        val_int = doc%get_int("company%nested%values%integer")
        if (val_int /= 42) then
            write(error_unit,*) "Wrong deeply nested integer value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Deep sequence test
        write(*,*) ' ->>>>>>>>>>>> testing deep nested sequence ->>>>>>>>>>>>'
        val = doc%get("company%nested%values%sequence")
        if (.not. val%is_sequence()) then
            write(error_unit,*) "Expected sequence type for deep nested sequence"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test company%name access
        val = doc%get("company%name")
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%name node"
            test_nested_access = ERR_ASSERT
            return
        endif

        str_val = val%get_str()
        call assert_equal("Example Corp", str_val, "Nested string value test", status)
        if (status /= ERR_SUCCESS) then
            write(error_unit,*) "Failed string comparison for company%name"
            test_nested_access = status
            return
        endif

        ! Test deep nested access
        val = doc%get("company%nested%values%integer")
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%nested%values%integer node"
            test_nested_access = ERR_ASSERT
            return
        endif

        int_val = val%get_int()
        call assert_equal(42, int_val, "Deep nested integer value test", status)
        if (status /= ERR_SUCCESS) then
            test_nested_access = status
            return
        endif

        ! Additional Checks for Sequence Access
        val = doc%get("company%flow_sequence")
        if (.not. val%is_sequence()) then
            write(error_unit,*) "Failed to recognize flow sequence"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test first document access
        write(*,*) ' ->>>>>>>>>>>> testing doc1: company%name ->>>>>>>>>>>>'
        val = doc%get("company%name", doc_index=1)
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%name from doc 1"
            test_nested_access = ERR_ASSERT
            return
        endif
        str_val = val%get_str()
        write(error_unit,*) "Got nested string from doc 1:", trim(str_val)
        if (str_val /= "Example Corp") then
            write(error_unit,*) "Wrong nested string value in doc 1"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test default document (first) access
        write(*,*) ' ->>>>>>>>>>>> testing default doc: company%employees ->>>>>>>>>>>>'
        val = doc%get("company%employees")  ! Should default to doc_index=1
        if (.not. associated(val%node)) then
            write(error_unit,*) "Failed to get company%employees from default doc"
            test_nested_access = ERR_ASSERT
            return
        endif
        int_val = val%get_int()
        write(error_unit,*) "Got nested integer from default doc:", int_val
        if (int_val /= 150) then
            write(error_unit,*) "Wrong nested integer value in default doc"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test invalid document index
        write(*,*) ' ->>>>>>>>>>>> testing invalid doc index ->>>>>>>>>>>>'
        val = doc%get("company%name", doc_index=3)
        if (associated(val%node)) then
            write(error_unit,*) "Expected null for invalid doc index"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test all value types with nested access in first document
        write(*,*) ' ->>>>>>>>>>>> testing doc1: all value types ->>>>>>>>>>>>'

        ! Integer test
        int_val = doc%get_int("company%employees", doc_index=1)
        write(error_unit,*) "Got nested integer:", int_val
        if (int_val /= 150) then
            write(error_unit,*) "Wrong nested integer value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Real test
        real_val = doc%get_real("company%pi", doc_index=1)
        write(error_unit,*) "Got nested real:", real_val
        if (abs(real_val - 3.14159) > 1.0e-5) then
            write(error_unit,*) "Wrong nested real value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Boolean test
        if (.not. doc%get_bool("company%okay", doc_index=1)) then
            write(error_unit,*) "Wrong nested boolean value"
            test_nested_access = ERR_ASSERT
            return
        endif

        ! Test sequences across documents
        write(*,*) ' ->>>>>>>>>>>> testing sequences in both docs ->>>>>>>>>>>>'

        ! First document sequence
        val = doc%get("company%flow_sequence", doc_index=1)
        if (.not. val%is_sequence()) then
            write(error_unit,*) "Failed to recognize flow sequence in doc 1"
            test_nested_access = ERR_ASSERT
            return
        endif

        write(*,*) "All nested access tests passed successfully!"
    end function test_nested_access

    !> Test multiple document access
    integer function test_multiple_docs()
        type(fyaml_doc) :: doc
        type(yaml_value) :: val
        logical :: success
        integer :: status, int_val

        test_multiple_docs = ERR_SUCCESS

        ! Load test file (ensure file exists in binary dir)
        write(error_unit,*) "Loading test file: "//TEST_MULTI_DOC_FILE
        call doc%load(TEST_MULTI_DOC_FILE, success)
        if (.not. success) then
            write(error_unit,*) "Failed to load YAML file"
            test_multiple_docs = ERR_ALLOC
            return
        endif

        ! Verify number of documents
        if (doc%n_docs /= 2) then
            write(error_unit,*) "Expected 2 documents, got:", doc%n_docs
            test_multiple_docs = ERR_ASSERT
            return
        endif

        ! Test first document access
        val = doc%get("company%name", doc_index=1)
        call assert_equal("Example Corp", val%get_str(), "First doc string test", status)
        if (status /= ERR_SUCCESS) then
            test_multiple_docs = status
            return
        endif

        ! Test second document access
        val = doc%get("deep%nested%values%integer", doc_index=2)
        int_val = val%get_int()
        call assert_equal(42, int_val, "Second doc integer test", status)
        if (status /= ERR_SUCCESS) then
            test_multiple_docs = status
            return
        endif

        ! Test invalid document index
        val = doc%get("company%name", doc_index=3)
        if (associated(val%node)) then
            write(error_unit,*) "Expected null for invalid doc index"
            test_multiple_docs = ERR_ASSERT
            return
        endif
    end function test_multiple_docs

    ! Add tests for get_value and get_values functions
    integer function test_get_value()
        type(fyaml_doc) :: doc
        type(yaml_value) :: val
        character(len=:), allocatable :: str_val
        integer :: int_val, status
        real :: real_val
        logical :: bool_val, success

        test_get_value = ERR_SUCCESS

        ! Load test file
        call doc%load(TEST_FILE, success)
        if (.not. success) then
            write(error_unit,*) "Failed to load YAML file"
            test_get_value = ERR_ALLOC
            return
        endif

        ! Test string value
        val = doc%get("company%name")
        str_val = val%get_str()
        call assert_equal("Example Corp", str_val, "String value test", status)
        if (status /= ERR_SUCCESS) then
            test_get_value = status
            return
        endif

        ! Test integer value
        val = doc%get("company%founded")
        int_val = val%get_int()
        call assert_equal(2001, int_val, "Integer value test", status)
        if (status /= ERR_SUCCESS) then
            test_get_value = status
            return
        endif

        ! Test real value
        val = doc%get("company%pi")
        real_val = val%get_real()
        call assert_equal(3.14159, real_val, "Real value test", status)
        if (status /= ERR_SUCCESS) then
            test_get_value = status
            return
        endif

        ! Test boolean value
        val = doc%get("company%okay")
        bool_val = val%get_bool()
        call assert_equal(.true., bool_val, "Boolean value test", status)
        if (status /= ERR_SUCCESS) then
            test_get_value = status
            return
        endif

        ! Test integer value under rootnode2
        val = doc%get("rootnode2%test")  ! Changed from rootlevel2 to rootnode2
        int_val = val%get_int()
        call assert_equal(1, int_val, "Integer value test under rootnode2", status)  ! Updated test description
        if (status /= ERR_SUCCESS) then
            test_get_value = status
            return
        endif

        ! Rest of the function remains unchanged
        val = doc%get("rootnode2%test2%test3")
        int_val = val%get_int()
        call assert_equal(3, int_val, "Integer value test2%test3 under rootnode2 Integer value test", status)
        if (status /= ERR_SUCCESS) then
            test_get_value = status
            return
        endif

    end function test_get_value

    integer function test_get_values()
        type(fyaml_doc) :: doc
        type(yaml_value) :: val
        character(len=:), allocatable, dimension(:) :: str_vals
        integer, dimension(:), allocatable :: int_vals
        real, dimension(:), allocatable :: real_vals
        logical, dimension(:), allocatable :: bool_vals
        integer :: status, i
        logical :: success

        test_get_values = ERR_SUCCESS

        ! Load test file
        call doc%load(TEST_FILE, success)
        if (.not. success) then
            write(error_unit,*) "Failed to load YAML file"
            test_get_values = ERR_ALLOC
            return
        endif

        ! Test string sequence
        val = doc%get("company%flow_sequence_string")
        str_vals = val%get_sequence()
        do i = 1, size(flow_seq_str)
            call assert_equal(flow_seq_str(i), str_vals(i), "String sequence test", status)
            if (status /= ERR_SUCCESS) then
                test_get_values = status
                return
            endif
        end do

        ! Test integer sequence
        val = doc%get("company%flow_sequence")
        int_vals = val%get_sequence_int()
        do i = 1, size(flow_seq_int)
            call assert_equal(flow_seq_int(i), int_vals(i), "Integer sequence test", status)
            if (status /= ERR_SUCCESS) then
                test_get_values = status
                return
            endif
        end do

        ! Test real sequence
        val = doc%get("company%flow_sequence_real")
        real_vals = val%get_sequence_real()
        do i = 1, size(flow_seq_real)
            call assert_equal(flow_seq_real(i), real_vals(i), "Real sequence test", status)
            if (status /= ERR_SUCCESS) then
                test_get_values = status
                return
            endif
        end do

        ! Test boolean sequence
        val = doc%get("company%flow_sequence_logical")
        bool_vals = val%get_sequence_bool()
        do i = 1, size(flow_seq_log)
            call assert_equal(flow_seq_log(i), bool_vals(i), "Logical sequence test", status)
            if (status /= ERR_SUCCESS) then
                test_get_values = status
                return
            endif
        end do
    end function test_get_values

    ! Update check_null function
    function check_null(self) result(is_null)
        class(yaml_value), intent(in) :: self
        logical :: is_null

        is_null = .false.
        if (.not. associated(self%node)) return

        ! Check for null value ('~' or empty)
        if (trim(adjustl(self%node%value)) == '~' .or. &
            len_trim(adjustl(self%node%value)) == 0) then
            is_null = .true.
            self%node%is_null = .true.  ! Set the flag
        endif
    end function check_null

    integer function test_root_keys()
        type(fyaml_doc) :: doc
        type(yaml_value) :: val
        character(len=:), allocatable, dimension(:) :: root_keys
        logical :: success
        integer :: i, status

        test_root_keys = ERR_SUCCESS

        ! Load test file
        call doc%load(TEST_FILE, success)
        if (.not. success) then
            write(error_unit,*) "Failed to load YAML file"
            test_root_keys = ERR_ALLOC
            return
        endif

        ! Get root level node
        root_keys = get_root_keys(doc)
        do i = 1, size(root_keys)
            write(*,*) 'Root Key: ', root_keys(i)
        enddo
        ! if (.not. associated(val%node)) then
        !     write(error_unit,*) "Failed to get root node"
        !     test_root_keys = ERR_ASSERT
        !     return
        ! endif

        ! Get all root keys
        ! root_keys = val%child_keys()

        ! We expect 2 root keys: "company" and "rootnode2"
        call assert_equal(2, size(root_keys), "Number of root keys", status)
        if (status /= ERR_SUCCESS) then
            test_root_keys = status
            return
        endif

        ! Check key names
        call assert_equal("company", root_keys(1), "First root key", status)
        if (status /= ERR_SUCCESS) then
            test_root_keys = status
            return
        endif

        call assert_equal("rootnode2", root_keys(2), "Second root key", status)
        if (status /= ERR_SUCCESS) then
            test_root_keys = status
            return
        endif

        if (allocated(root_keys)) deallocate(root_keys)
    end function test_root_keys

end module test_utils

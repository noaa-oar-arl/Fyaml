!> YAML Parser module
!!
!! This module provides functionality for parsing YAML files into Fortran data structures.
!! It handles document structure, value types, indentation, sequences, and mapping nodes.
!!
!! @note Supports basic YAML features including scalars, sequences, and mappings
!! @author Barry Baker
!! @version 0.1.0
!! @see yaml_types
!! @see fyaml
module yaml_parser
  use yaml_types
  use iso_fortran_env, only: error_unit, output_unit
  implicit none

  ! Debug levels
  !=============
  !> Disable all debug output
  integer, parameter :: DEBUG_NONE = 0
  !> Show only error messages
  integer, parameter :: DEBUG_ERROR = 1
  !> Show warnings and errors
  integer, parameter :: DEBUG_WARN = 2
  !> Show general info messages
  integer, parameter :: DEBUG_INFO = 3
  !> Show verbose debug output
  integer, parameter :: DEBUG_VERBOSE = 4

  ! Error codes
  !============
  !> Operation completed successfully
  integer, parameter :: ERR_SUCCESS = 0
  !> YAML file not found or inaccessible
  integer, parameter :: ERR_FILE_NOT_FOUND = 1
  !> Error reading from file
  integer, parameter :: ERR_READ_ERROR = 2
  !> Error parsing YAML content
  integer, parameter :: ERR_PARSE_ERROR = 3
  !> Memory allocation error
  integer, parameter :: ERR_MEMORY = 4

  ! Module variables
  !=================
  integer :: debug_level = DEBUG_ERROR

contains

  !> Set the debug output level
  !!
  !! Controls how much debug information is printed during parsing
  !!
  !! @param[in] level Debug level (DEBUG_NONE through DEBUG_VERBOSE)
  subroutine set_debug_level(level)
    integer, intent(in) :: level
    debug_level = level
  end subroutine

  !> Debug message printer
  !!
  !! Prints debug messages based on current debug level
  !!
  !! @param[in] level Debug level of message
  !! @param[in] message Debug message to print
  !! @param[in] error_code Optional error code to include
  subroutine debug_print(level, message, error_code)
    integer, intent(in) :: level
    character(len=*), intent(in) :: message
    integer, intent(in), optional :: error_code

    if (level <= debug_level) then
      select case (level)
        case (DEBUG_ERROR)
          write(error_unit,*) "ERROR: ", trim(message)
          if (present(error_code)) write(error_unit,*) "Error code:", error_code
        case (DEBUG_WARN)
          write(error_unit,*) "WARNING: ", trim(message)
        case (DEBUG_INFO)
          write(output_unit,*) "INFO: ", trim(message)
        case (DEBUG_VERBOSE)
          write(output_unit,*) "DEBUG: ", trim(message)
      end select
    endif
  end subroutine

  !> Parse a YAML file into document structure
  !!
  !! Reads and parses a YAML file into one or more documents
  !!
  !! @param[in]  filename Path to YAML file
  !! @param[out] docs     Array of parsed YAML documents
  !! @param[out] status   Status code (ERR_SUCCESS on success)
  subroutine parse_yaml(filename, docs, status)
    use yaml_types
    use iso_fortran_env, only: error_unit
    implicit none

    character(len=*), intent(in) :: filename
    type(yaml_document), allocatable, intent(out) :: docs(:)
    integer, intent(out) :: status

    integer :: unit_num, io_stat, line_count, doc_count
    character(len=1024) :: line
    logical :: in_document, doc_started
    integer :: i
    character(len=256) :: error_msg
    character(len=32) :: cnt_str

    ! Initialize status
    status = ERR_SUCCESS

    call debug_print(DEBUG_INFO, "Starting YAML parse for: "//trim(filename))

    ! Open the YAML file for reading
    open(newunit=unit_num, file=filename, status='old', action='read', iostat=io_stat)
    if (io_stat /= 0) then
        write(error_msg, '(A,I0)') "Failed to open file. IO Status: ", io_stat
        call debug_print(DEBUG_ERROR, trim(error_msg))
        status = ERR_FILE_NOT_FOUND
        return
    endif

    call debug_print(DEBUG_VERBOSE, "Counting documents in file")

    ! First Pass: Count the number of YAML documents (separated by '---')
    doc_count = 0
    line_count = 0
    in_document = .false.

    do
        read(unit_num, '(A)', IOSTAT=io_stat) line
        if (io_stat == -1) exit  ! EOF reached
        if (io_stat /= 0) then
            write(error_msg, '(A,I0)') "Error reading file during document count. IO Status: ", io_stat
            call debug_print(DEBUG_ERROR, trim(error_msg))
            status = ERR_READ_ERROR
            close(unit_num)
            return
        endif

        line_count = line_count + 1
        line = adjustl(line)

        if (starts_with_trimmed(line, '---')) then
            doc_count = doc_count + 1
            in_document = .true.
        endif
    end do

    if (doc_count == 0 .and. line_count > 0) then
        ! At least one document exists even without '---' separator
        doc_count = 1
    endif

    write(cnt_str, '(I0)') doc_count
    call debug_print(DEBUG_INFO, "Number of YAML documents found: "//trim(adjustl(cnt_str)))

    rewind(unit_num)

    ! Allocate the documents array
    if (doc_count > 0) then
        allocate(docs(doc_count))
        do i = 1, doc_count
            call initialize_document(docs(i))
        end do
    else
        ! No documents found
        write(error_msg, '(A)') "No YAML documents found in the file."
        call debug_print(DEBUG_WARN, trim(error_msg))
        status = ERR_PARSE_ERROR
        close(unit_num)
        return
    endif

    ! Second Pass: Parse each YAML document
    doc_count = 1
    in_document = .false.
    doc_started = .false.

    call debug_print(DEBUG_VERBOSE, "Parsing documents")

    do
        read(unit_num, '(A)', IOSTAT=io_stat) line
        if (io_stat == -1) exit  ! EOF reached
        if (io_stat /= 0) then
            write(error_msg, '(A,I0)') "Error reading file during parsing. IO Status: ", io_stat
            call debug_print(DEBUG_ERROR, trim(error_msg))
            status = ERR_READ_ERROR
            exit
        endif

        line = adjustl(line)

        if (starts_with_trimmed(line, '---')) then
            ! New document starts
            if (doc_count > size(docs)) then
                write(error_msg, '(A)') "Document count exceeded allocation."
                call debug_print(DEBUG_ERROR, trim(error_msg))
                status = ERR_PARSE_ERROR
                exit
            endif
            if (in_document) then
                ! Finalize the previous document if needed
                doc_count = doc_count + 1
                if (doc_count > size(docs)) then
                    call debug_print(DEBUG_ERROR, "Exceeded allocated document count.")
                    status = ERR_PARSE_ERROR
                    exit
                endif
            else
                in_document = .true.
                doc_started = .true.
            endif
            cycle  ! Skip the '---' line
        endif

        if (in_document) then
            ! Parse the line into the current document
            call parse_line(line, docs(doc_count), status)
            if (status /= ERR_SUCCESS) then
                call debug_print(DEBUG_ERROR, "Error parsing line: "//trim(line))
                exit
            endif
        endif
    end do

    close(unit_num)

    ! Final checks after parsing
    if (.not. doc_started .and. line_count > 0) then
        write(error_msg, '(A)') "No valid YAML documents were parsed."
        call debug_print(DEBUG_WARN, trim(error_msg))
        status = ERR_PARSE_ERROR
    else
        call debug_print(DEBUG_INFO, "YAML parsing completed successfully.")
        status = ERR_SUCCESS
    endif

end subroutine parse_yaml

  !> Initialize a new YAML document
  !!
  !! Sets up empty document structure with nullified root
  !!
  !! @param[in,out] doc Document to initialize
  subroutine initialize_document(doc)
    implicit none
    type(yaml_document), intent(inout) :: doc

    ! Only initialize root node
    nullify(doc%root)
  end subroutine

  !> Parse a single line of YAML content
  !!
  !! Processes a line and updates document structure. Handles:
  !! - Indentation
  !! - Sequence items
  !! - Key-value pairs
  !! - Nested structures
  !!
  !! @param[in]     line Input line
  !! @param[in,out] doc  Document being built
  !! @param[out]    status Status code
  subroutine parse_line(line, doc, status)
    character(len=*), intent(in) :: line
    type(yaml_document), intent(inout) :: doc
    integer, intent(out) :: status
    type(yaml_node), pointer :: new_node, current_node, parent_node
    integer :: pos, current_indent, parent_indent, io_stat
    character(len=:), allocatable :: local_line
    logical :: is_sequence_item
    character(len=256) :: debug_msg

    call debug_print(DEBUG_VERBOSE, "Parsing line: "//trim(line))

    ! Validate input
    if (len_trim(line) == 0) then
        call debug_print(DEBUG_WARN, "Empty line received")
        status = ERR_SUCCESS
        return
    endif

    ! Create local copy and remove comments
    local_line = trim(line)
    pos = index(local_line, '#')
    if (pos > 0) local_line = trim(local_line(1:pos-1))
    if (len_trim(local_line) == 0) return

    ! Determine indentation and sequence status
    current_indent = count_leading_spaces(local_line)
    is_sequence_item = (index(trim(local_line), '-') == 1)

    ! ! Memory allocation and validation checks
    ! if (.not. associated(new_node)) then
    !     call debug_print(DEBUG_ERROR, "Node pointer not associated", ERR_MEMORY)
    !     status = ERR_MEMORY
    !     return
    ! endif
    new_node => null()

    ! Create new node
    allocate(new_node, stat=io_stat)
    if (io_stat /= 0) then
        call debug_print(DEBUG_ERROR, "Failed to allocate new node", ERR_MEMORY)
        status = ERR_MEMORY
        return
    endif

    ! Initialize node
    call initialize_node(new_node)
    call debug_print(DEBUG_VERBOSE, "Successfully created and initialized new node")

    ! Validate node initialization
    if (.not. associated(new_node)) then
        call debug_print(DEBUG_ERROR, "Node initialization failed", ERR_MEMORY)
        status = ERR_MEMORY
        return
    endif

    ! Parse sequence item
    if (is_sequence_item) then
        new_node%is_sequence = .true.
        pos = index(local_line, '-') + 1
        local_line = trim(local_line(pos:))

        ! Check for key-value pair in sequence item
        pos = index(local_line, ':')
        if (pos > 0) then
            new_node%key = trim(local_line(1:pos-1))
            new_node%value = trim(local_line(pos+1:))
        else
            new_node%value = trim(local_line)
        endif
    else
        ! Parse regular key-value pair
        pos = index(local_line, ':')
        if (pos > 0) then
            new_node%key = trim(local_line(1:pos-1))
            new_node%value = trim(local_line(pos+1:))
        else
            new_node%key = trim(local_line)
        endif
    endif

    ! Link node into document structure
    if (.not. associated(doc%root)) then
        doc%root => new_node
        status = ERR_SUCCESS
        return
    endif

    ! Find correct parent based on indentation
    current_node => doc%root
    parent_node => null()
    parent_indent = 0

    do while (associated(current_node))
        if (current_indent > parent_indent) then
            ! Going deeper in hierarchy
            if (.not. associated(current_node%children)) then
                current_node%children => new_node
                status = ERR_SUCCESS
                return
            endif
            parent_node => current_node
            current_node => current_node%children
            parent_indent = parent_indent + 2
        else if (current_indent == parent_indent) then
            ! Same level - add as sibling
            if (.not. associated(current_node%next)) then
                current_node%next => new_node
                status = ERR_SUCCESS
                return
            endif
            current_node => current_node%next
        else
            ! Going back up in hierarchy
            if (associated(parent_node)) then
                current_node => parent_node
                parent_node => null()
                parent_indent = parent_indent - 2
            else
                current_node%next => new_node
                status = ERR_SUCCESS
                return
            endif
        endif
    end do
  end subroutine parse_line

  !> Parse flow-style YAML syntax
  !!
  !! Handles flow-style sequences [...] and mappings {...}
  !!
  !! @param[in]     line Input containing flow syntax
  !! @param[in,out] node Node to store parsed content
  subroutine parse_flow_form(line, node)
      character(len=*), intent(in) :: line
      type(yaml_node), pointer, intent(inout) :: node  ! Changed to pointer
      integer :: pos, start, end
      character(len=:), allocatable :: content

      ! Handle flow form sequences
      if (index(line, '[') > 0) then
          start = index(line, '[')
          end = index(line, ']')
          if (end > start) then
              content = trim(line(start+1:end-1))
              ! Node is now a pointer, can be passed directly
              call parse_sequence(content, node)
          end if
      end if

      ! Handle flow form mappings
      if (index(line, '{') > 0) then
          start = index(line, '{')
          end = index(line, '}')
          if (end > start) then
              content = trim(line(start+1:end-1))
              call parse_mapping(content, node)
          end if
      end if
  end subroutine parse_flow_form

  !> Parse sequence elements from flow style
  !!
  !! Splits comma-separated sequence items into nodes
  !!
  !! @param[in,out] content Sequence content string
  !! @param[in,out] node Node to store sequence
  subroutine parse_sequence(content, node)
      ! Modified parameter declarations
      character(len=:), allocatable, intent(inout) :: content
      type(yaml_node), pointer, intent(inout) :: node

      ! Local variables
      character(len=:), allocatable :: item
      character(len=:), allocatable :: local_content
      integer :: pos

      ! Copy input content to local variable for manipulation
      local_content = content

      ! Split the content by commas to get individual items
      do
        pos = index(local_content, ',')
        if (pos > 0) then
          item = trim(local_content(1:pos-1))
          local_content = trim(local_content(pos+1:))
        else
          item = trim(local_content)
          local_content = ''
        end if

        ! Create a new node for each item
        allocate(node%children)
        call initialize_node(node%children)
        node%children%value = item
        node => node%children

        if (len(local_content) == 0) exit
      end do

      ! Update the original content
      content = local_content

  end subroutine parse_sequence

  !> Parse mapping elements from flow style
  !!
  !! Splits comma-separated key-value pairs into nodes
  !!
  !! @param[in,out] content Mapping content string
  !! @param[in,out] node Node to store mapping
  subroutine parse_mapping(content, node)
    character(len=*), intent(inout) :: content
    type(yaml_node), pointer, intent(inout) :: node
    character(len=:), allocatable :: key, value
    character(len=:), allocatable :: local_content, pair
    integer :: pos, content_len

    ! Safely initialize local content
    content_len = len_trim(content)
    if (content_len == 0) return

    allocate(character(len=content_len) :: local_content)
    local_content = trim(content)

    ! Process key-value pairs
    do while (len_trim(local_content) > 0)
        ! Get next pair
        pos = index(local_content, ',')
        if (pos > 0) then
            if (allocated(pair)) deallocate(pair)
            allocate(character(len=pos-1) :: pair)
            pair = trim(local_content(1:pos-1))
            local_content = trim(local_content(pos+1:))
        else
            if (allocated(pair)) deallocate(pair)
            allocate(character(len=len_trim(local_content)) :: pair)
            pair = trim(local_content)
            local_content = ''
        end if

        ! Process key-value pair
        pos = index(pair, ':')
        if (pos > 0) then
            if (allocated(key)) deallocate(key)
            if (allocated(value)) deallocate(value)

            allocate(character(len=pos-1) :: key)
            allocate(character(len=len_trim(pair)-pos) :: value)

            key = trim(pair(1:pos-1))
            value = trim(pair(pos+1:))

            ! Create new node
            allocate(node%children)
            call initialize_node(node%children)
            node%children%key = key
            node%children%value = value
            node => node%children
        end if
    end do

    ! Clean up
    if (allocated(local_content)) deallocate(local_content)
    if (allocated(key)) deallocate(key)
    if (allocated(value)) deallocate(value)
    if (allocated(pair)) deallocate(pair)

end subroutine parse_mapping

  !> Initialize a new YAML node
  !!
  !! Sets default values for a newly created node
  !!
  !! @param[in,out] node Node to initialize
  subroutine initialize_node(node)
    type(yaml_node), pointer, intent(inout) :: node
    node%key = ''
    node%value = ''
    node%children => null()
    node%next => null()
    node%is_sequence = .false.
    node%is_null = .false.
    node%is_boolean = .false.
    node%is_integer = .false.
    node%is_float = .false.
    node%is_string = .true.
  end subroutine initialize_node

  !> Determine value type of node
  !!
  !! Checks content and sets appropriate type flags
  !!
  !! @param[in,out] node Node to analyze
  subroutine determine_value_type(node)
    type(yaml_node), intent(inout) :: node
    real :: r_value
    integer :: i_value
    logical :: l_value
    logical :: is_real, is_int
    integer :: rc
    character(len=32) :: temp_str  ! Buffer for numeric conversions

    ! Early exit for empty values
    if (len_trim(node%value) == 0) then
        node%is_null = .true.
        return
    end if

    ! Check for null values
    if (to_lower(trim(node%value)) == 'null' .or. &
        trim(node%value) == '~' .or. &
        to_lower(trim(node%value)) == 'nan') then
      node%is_null = .true.
      node%value = ''
      return
    end if

    ! Check for boolean values
    if (trim(node%value) == 'true' .or. trim(node%value) == 'false') then
      node%is_boolean = .true.
      l_value = (trim(node%value) == 'true')
      write(temp_str, '(L1)', iostat=rc) l_value
      if (rc == 0) node%value = trim(temp_str)
      return
    end if

    ! Check for float values
    if (is_real_string(trim(node%value))) then
      read(node%value, *, iostat=rc) r_value
      if (rc == 0) then
        node%is_float = .true.
        write(temp_str, '(G14.6)', iostat=rc) r_value
        if (rc == 0) node%value = trim(temp_str)
        return
      end if
    end if

    ! Check for integer values
    if (is_int_string(trim(node%value))) then
      read(node%value, *, iostat=rc) i_value
      if (rc == 0) then
        node%is_integer = .true.
        write(temp_str, '(I0)', iostat=rc) i_value
        if (rc == 0) node%value = trim(temp_str)
        return
      end if
    end if

    ! Default to string
    node%is_string = .true.
  end subroutine determine_value_type

  !> Count leading spaces in a string
  !!
  !! Used for determining indentation level
  !!
  !! @param[in]  line Input string
  !! @return     Number of leading spaces
  integer function count_leading_spaces(line)
    implicit none

    character(len=*), intent(in) :: line
    integer :: i

    count_leading_spaces = 0
    do i = 1, len(line)
      if (line(i:i) /= ' ') exit
      count_leading_spaces = count_leading_spaces + 1
    end do
  end function count_leading_spaces

  !> Check if string can be parsed as real number
  !!
  !! @param[in]  str String to check
  !! @return     True if string represents a real number
  function is_real_string(str) result(is_real)
    implicit none
    character(len=*), intent(in) :: str
    logical :: is_real
    real :: r_value
    integer :: iostat

    read(str, *, iostat=iostat) r_value
    if (iostat == 0) then
      is_real = .true.
    else
      is_real = .false.
    end if
  end function is_real_string

  !> Check if string represents an integer
  !!
  !! @param[in] str String to check
  !! @return True if string can be parsed as integer
  function is_int_string(str) result(is_int)
    implicit none
    character(len=*), intent(in) :: str
    logical :: is_int
    integer :: i_value
    integer :: iostat

    read(str, *, iostat=iostat) i_value
    if (iostat == 0) then
      is_int = .true.
    else
      is_int = .false.
    end if
  end function is_int_string

  !> Convert string to lowercase
  !!
  !! @param[in]  str Input string
  !! @return     Lowercase version of input
  function to_lower(str) result(lower_str)
    implicit none
    character(len=*), intent(in) :: str
    character(len=len(str)) :: lower_str
    integer :: i

    lower_str = str
    do i = 1, len(str)
      if (iachar(str(i:i)) >= iachar('A') .and. iachar(str(i:i)) <= iachar('Z')) then
        lower_str(i:i) = achar(iachar(str(i:i)) + 32)
      end if
    end do
  end function to_lower

  !> Validate node structure and contents
  !!
  !! Performs validation checks on node pointers and content
  !!
  !! @param[in] node Node to validate
  !! @param[out] status Status code (ERR_SUCCESS if valid)
  subroutine validate_node(node, status)
    type(yaml_node), pointer, intent(in) :: node
    integer, intent(out) :: status

    if (.not. associated(node)) then
        call debug_print(DEBUG_ERROR, "Invalid node pointer", ERR_PARSE_ERROR)
        status = ERR_PARSE_ERROR
        return
    endif

    ! Validate node contents
    if (node%is_sequence .and. .not. associated(node%children)) then
        call debug_print(DEBUG_WARN, "Sequence node without children")
    endif

    status = ERR_SUCCESS
  end subroutine validate_node

  !> Check if a trimmed line starts with a specific string
  !!
  !! @param[in] line   Input line
  !! @param[in] prefix Prefix string to check
  !! @return     True if the trimmed line starts with the prefix
  logical function starts_with_trimmed(line, prefix)
    implicit none
    character(len=*), intent(in) :: line
    character(len=*), intent(in) :: prefix
    character(len=:), allocatable :: trimmed_line

    trimmed_line = trim(adjustl(line))
    if (len(trimmed_line) < len(prefix)) then
        starts_with_trimmed = .false.
    else
        starts_with_trimmed = (trimmed_line(1:len(prefix)) == trim(prefix))
    endif
  end function starts_with_trimmed

end module yaml_parser

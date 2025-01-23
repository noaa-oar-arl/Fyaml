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
  !> Show only error messages
  integer, parameter :: DEBUG_ERROR = 1
  !> Show general info messages
  integer, parameter :: DEBUG_INFO = 2

  ! Error codes
  !============
  !> Operation completed successfully
  integer, parameter :: ERR_SUCCESS = 0
  !> File access error
  integer, parameter :: ERR_FILE = 1
  !> Parse error
  integer, parameter :: ERR_PARSE = 2
  !> Memory allocation error
  integer, parameter :: ERR_MEMORY = 3

  ! Module variables
  !=================
  integer :: debug_level = DEBUG_INFO
  integer :: indent_width = 2  ! Default indentation width

  ! Public interfaces
  public :: find_sequence_parent_node, to_lower, count_leading_spaces
  public :: check_sequence, parse_yaml
  public :: find_nested_node  ! Add this function to the public interface at the top of the module

  ! Private interfaces
  private :: is_real_string
  private :: is_int_string
  private :: is_block_sequence
  private :: find_last_sequence_item
  private :: find_last_nonsequence_node
  private :: parse_yaml_internal
  private :: set_indent_width
  private :: detect_indent_width

  ! Move check_sequence interface declaration here
  interface check_sequence
    module procedure check_sequence_node
  end interface

  ! Update interface for parse_yaml
  interface parse_yaml
    module procedure parse_yaml_wrapper
  end interface

  ! Add type definition at module level before contains
  type :: stack_entry
    type(yaml_node), pointer :: node => null()
  end type stack_entry

  ! Add constants for debug output formatting
  character(len=*), parameter :: DBG_NEW_NODE    = "--- NEW NODE: "
  character(len=*), parameter :: DBG_PARENT      = "=== PARENT: "
  character(len=*), parameter :: DBG_CHILD       = "  |- CHILD: "
  character(len=*), parameter :: DBG_SIBLING     = "  |+ SIBLING: "
  character(len=*), parameter :: DBG_LEVEL       = "LEVEL "
  character(len=*), parameter :: DBG_INDENT      = "    "

  ! Add new format specifiers for debug messages
  character(len=*), parameter :: DBG_FMT_INDENT = "(2A)"  ! Changed from "(A,I0)"
  character(len=*), parameter :: DBG_FMT_NODE = "(3A,I0)"  ! Changed from "(A,A,A,I0)"
  character(len=*), parameter :: DBG_FMT_KEY = "(2A)"  ! No change needed
  character(len=*), parameter :: DBG_FMT_LEVEL = "(A,I0,2A,I0)"  ! Changed from "(2A,I0,2A)"

  ! Add tracking for last key at each indent level
  type :: indent_tracker
    integer :: indent
    character(len=:), allocatable :: last_key
    integer :: line_num
    type(indent_tracker), pointer :: next => null()
  end type indent_tracker

  ! Add module variable to track indentation history
  type(indent_tracker), pointer, save :: indent_history => null()

contains

  !> Set the debug output level for the YAML parser
  !!
  !! @param[in] level Debug level (DEBUG_ERROR or DEBUG_INFO)
  subroutine set_debug_level(level)
    integer, intent(in) :: level
    debug_level = level
  end subroutine

  !> Set the indentation width used for parsing YAML structure
  !!
  !! @param[in] width Number of spaces per indentation level
  subroutine set_indent_width(width)
    integer, intent(in) :: width
    if (width > 0) indent_width = width
  end subroutine

  !> Print debug messages with appropriate formatting and prefixes
  !!
  !! @param[in] level Debug level of the message
  !! @param[in] message The debug message to print
  !! @param[in] error_code Optional error code associated with the message
  !! @param[in] msg_type Optional message type for prefix selection
  subroutine debug_print(level, message, error_code, msg_type)
    integer, intent(in) :: level
    character(len=*), intent(in) :: message
    integer, intent(in), optional :: error_code
    character(len=*), intent(in), optional :: msg_type
    character(len=:), allocatable :: prefix, formatted_msg

    if (level <= debug_level) then
      ! Determine prefix based on message type
      if (present(msg_type)) then
        select case (msg_type)
          case ("NEW_NODE")
            prefix = DBG_NEW_NODE
          case ("PARENT")
            prefix = DBG_PARENT
          case ("CHILD")
            prefix = DBG_CHILD
          case ("SIBLING")
            prefix = DBG_SIBLING
          case ("LEVEL")
            prefix = DBG_LEVEL
          case default
            prefix = "INFO: "
        end select
      else
        prefix = "INFO: "
      endif

      select case (level)
        case (DEBUG_ERROR)
          write(output_unit,'(A,1X,A)') "ERROR:", trim(message)  ! Changed format
          if (present(error_code)) write(output_unit,'(A,1X,I0)') "Code:", error_code  ! Changed format
        case (DEBUG_INFO)
          write(output_unit,'(A,1X,A)') trim(prefix), trim(message)  ! Changed format
      end select
    endif
  end subroutine

  !> Wrapper subroutine for parsing YAML files
  !!
  !! @param[in] filename Name of the YAML file to parse
  !! @param[out] docs Array of parsed YAML documents
  !! @param[out] status Status code indicating success or error
  subroutine parse_yaml_wrapper(filename, docs, status)
    character(len=*), intent(in) :: filename
    type(yaml_document), allocatable, intent(out) :: docs(:)
    integer, intent(out) :: status
    integer :: doc_count
    logical :: found_doc_marker

    ! First pass: Count documents
    call count_documents(filename, size_out=doc_count, found_marker=found_doc_marker, stat=status)
    if (status /= ERR_SUCCESS) return

    ! If no explicit markers but content exists, treat as single document
    if (doc_count == 0 .and. .not. found_doc_marker) doc_count = 1

    ! Allocate documents array
    if (allocated(docs)) deallocate(docs)
    if (doc_count > 0) then
        allocate(docs(doc_count), stat=status)
        if (status /= ERR_SUCCESS) return
    endif

    ! Parse documents
    call parse_yaml_internal(filename, docs, status)
  end subroutine

  !> Helper subroutine to count the number of YAML documents in a file
  !!
  !! @param[in] filename Name of the YAML file to count documents in
  !! @param[out] size_out Number of documents found
  !! @param[out] found_marker Logical flag indicating if document markers were found
  !! @param[out] stat Status code indicating success or error
  subroutine count_documents(filename, size_out, found_marker, stat)
    character(len=*), intent(in) :: filename
    integer, intent(out) :: size_out
    logical, intent(out) :: found_marker
    integer, intent(out) :: stat
    integer :: unit_num, io_stat
    character(len=1024) :: line

    size_out = 0
    found_marker = .false.

    open(newunit=unit_num, file=filename, status='old', action='read', iostat=io_stat)
    if (io_stat /= 0) then
        stat = ERR_FILE
        return
    endif

    do
        read(unit_num, '(A)', iostat=io_stat) line
        if (io_stat /= 0) exit

        line = adjustl(line)
        if (line(1:3) == '---') then
            found_marker = .true.
            size_out = size_out + 1
        endif
    enddo

    close(unit_num)
    stat = ERR_SUCCESS
  end subroutine

  !> Internal subroutine for parsing YAML files
  !!
  !! @param[in] filename Name of the YAML file to parse
  !! @param[out] docs Array of parsed YAML documents
  !! @param[out] status Status code indicating success or error
  subroutine parse_yaml_internal(filename, docs, status)
    character(len=*), intent(in) :: filename
    type(yaml_document), allocatable, intent(out) :: docs(:)
    integer, intent(out) :: status

    integer :: unit_num, io_stat, line_count, doc_count, current_line
    character(len=1024) :: line
    logical :: in_document, doc_started, has_doc_markers
    integer :: i
    character(len=256) :: error_msg, debug_msg  ! Added debug_msg here
    character(len=32) :: cnt_str

    ! Initialize status and counters
    status = ERR_SUCCESS
    has_doc_markers = .false.
    line_count = 0      ! Total lines in file
    current_line = 0    ! Current line being processed

    call debug_print(DEBUG_INFO, "Starting YAML parse for: "//trim(filename))

    ! Open the YAML file for reading
    open(newunit=unit_num, file=filename, status='old', action='read', iostat=io_stat)
    if (io_stat /= 0) then
        write(error_msg, '(A,I0)') "Failed to open file. IO Status: ", io_stat
        call debug_print(DEBUG_ERROR, trim(error_msg))
        status = ERR_FILE
        return
    endif

    call debug_print(DEBUG_INFO, "Counting documents in file")

    ! First Pass: Look for document markers and count documents
    doc_count = 0
    line_count = 0
    in_document = .false.

    do
        read(unit_num, '(A)', IOSTAT=io_stat) line
        if (io_stat == -1) exit  ! EOF reached
        if (io_stat /= 0) then
            write(error_msg, '(A,I0)') "Error reading file during document count. IO Status: ", io_stat
            call debug_print(DEBUG_ERROR, trim(error_msg))
            status = ERR_FILE
            close(unit_num)
            return
        endif

        line_count = line_count + 1
        line = adjustl(line)

        if (starts_with_trimmed(line, '---')) then
            doc_count = doc_count + 1
            has_doc_markers = .true.
            in_document = .true.
        endif

        ! Check for document end marker
        if (starts_with_trimmed(line, '...')) then
            in_document = .false.
            has_doc_markers = .true.
        endif
    end do

    ! If no document markers found, treat as single document
    if (.not. has_doc_markers .and. line_count > 0) then
        doc_count = 1
        call debug_print(DEBUG_INFO, "No document markers found, treating as single document")
    else if (doc_count == 0 .and. line_count > 0) then
        ! At least one document exists even if only markers found
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
        call debug_print(DEBUG_INFO, trim(error_msg))
        status = ERR_PARSE
        close(unit_num)
        return
    endif

    ! Second Pass: Parse each YAML document
    doc_count = 1
    in_document = .not. has_doc_markers  ! Start in document if no markers
    doc_started = .not. has_doc_markers  ! Document started if no markers
    current_line = 0                     ! Reset line counter for second pass

    call debug_print(DEBUG_INFO, "Parsing documents")

    do
        read(unit_num, '(A)', IOSTAT=io_stat) line
        if (io_stat == -1) exit  ! EOF reached
        if (io_stat /= 0) then
            write(error_msg, '(A,I0)') "Error reading file during parsing. IO Status: ", io_stat
            call debug_print(DEBUG_ERROR, trim(error_msg))
            status = ERR_FILE
            exit
        endif

        current_line = current_line + 1  ! Increment line counter for each line read
        write(debug_msg, '(A,I0,A)') "Processing line ", current_line, ": "//trim(line)
        call debug_print(DEBUG_INFO, debug_msg)

        if (has_doc_markers) then
            if (starts_with_trimmed(line, '---')) then
                ! New document starts
                if (doc_count > size(docs)) then
                    write(error_msg, '(A)') "Document count exceeded allocation."
                    call debug_print(DEBUG_ERROR, trim(error_msg))
                    status = ERR_PARSE
                    exit
                endif
                if (in_document) then
                    ! Finalize the previous document if needed
                    doc_count = doc_count + 1
                    if (doc_count > size(docs)) then
                        call debug_print(DEBUG_ERROR, "Exceeded allocated document count.")
                        status = ERR_PARSE
                        exit
                    endif
                else
                    in_document = .true.
                    doc_started = .true.
                endif
                cycle  ! Skip the '---' line
            endif

            if (starts_with_trimmed(line, '...')) then
                in_document = .false.
                cycle  ! Skip the '...' line
            endif
        endif

        if (in_document .or. .not. has_doc_markers) then
            ! Parse the line into the current document
            call parse_line(line, docs(doc_count), status, current_line)  ! Pass current_line instead of line_count
            if (status /= ERR_SUCCESS) then
                call debug_print(DEBUG_ERROR, "Error parsing line "//trim(integer_to_string(current_line))//": "//trim(line))
                exit
            endif
        endif
    end do

    close(unit_num)

    ! Final checks after parsing
    if (.not. doc_started .and. line_count > 0) then
        write(error_msg, '(A)') "No valid YAML documents were parsed."
        call debug_print(DEBUG_INFO, trim(error_msg))
        status = ERR_PARSE
    else
        call debug_print(DEBUG_INFO, "YAML parsing completed successfully.")
        status = ERR_SUCCESS
    endif

    ! Clean up indent history
    call cleanup_indent_history()

end subroutine parse_yaml_internal

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
  !! @param[in]     line_num Line number of the input line
  subroutine parse_line(line, doc, status, line_num)
    character(len=*), intent(in) :: line
    type(yaml_document), intent(inout) :: doc
    integer, intent(out) :: status
    integer, intent(in) :: line_num  ! Add line number parameter
    type(yaml_node), pointer :: new_node, current_node, parent_node
    integer :: pos, current_indent, parent_indent, io_stat
    character(len=:), allocatable :: local_line, parent_key
    logical :: is_sequence_item
    character(len=256) :: debug_msg, error_msg  ! Added error_msg here

    call debug_print(DEBUG_INFO, "Parsing line: "//trim(line))

    ! Validate input
    if (len_trim(line) == 0) then
        call debug_print(DEBUG_INFO, "Empty line received")
        status = ERR_SUCCESS
        return
    endif

    ! Create local copy and remove comments
    local_line = trim(line)
    pos = index(local_line, '#')
    if (pos > 0) local_line = trim(local_line(1:pos-1))
    if (len_trim(local_line) == 0) return

    ! Determine indentation and sequence status
    current_indent = count_leading_spaces(line)
    is_sequence_item = is_block_sequence(adjustl(local_line))  ! Changed to use is_block_sequence

    ! ! Memory allocation and validation checks
    ! if (.not. associated(new_node)) then
    !     call debug_print(DEBUG_ERROR, "Node pointer not associated", ERR_MEMORY)
    !     status = ERR_MEMORY
    !     return
    ! endif
    new_node => null()

    ! Create new node
    allocate(new_node, stat=io_stat)
    if (io_stat == 0) then
        call initialize_node(new_node)
        write(debug_msg, DBG_FMT_INDENT) "Created node with indent ", &
                                        trim(integer_to_string(count_leading_spaces(line)))
        call debug_print(DEBUG_INFO, debug_msg, msg_type="NEW_NODE")
    else
        call debug_print(DEBUG_ERROR, "Failed to allocate new node", ERR_MEMORY)
        status = ERR_MEMORY
        return
    endif

    ! Initialize node
    call initialize_node(new_node)
    call debug_print(DEBUG_INFO, "Successfully created and initialized new node")

    ! Validate node initialization
    if (.not. associated(new_node)) then
        call debug_print(DEBUG_ERROR, "Node initialization failed", ERR_MEMORY)
        status = ERR_MEMORY
        return
    endif

    ! Store indentation level in node
    new_node%indent = count_leading_spaces(line)

    ! Store line number in node
    new_node%line_num = line_num
    write(debug_msg, '(A,I0,A,I0)') "Created node at line ", line_num, &
                                   " with indent ", new_node%indent
    call debug_print(DEBUG_INFO, debug_msg)

    ! Record indent level
    if (len_trim(new_node%key) > 0) then
      call record_indent_level(current_indent, new_node%key, line_num)
    endif

    ! Parse sequence item
    if (is_sequence_item) then
        ! Add more detailed debug output
        write(debug_msg, '(A,A)') "Processing sequence item with indent: ", trim(adjustl(integer_to_string(current_indent)))
        call debug_print(DEBUG_INFO, debug_msg)

        ! Clean leading spaces and dashes more carefully
        local_line = adjustl(local_line)
        if (local_line(1:2) == '- ') then
            local_line = adjustl(local_line(3:))
        endif

        new_node%value = trim(local_line)
        new_node%is_sequence = .true.
        new_node%indent = current_indent ! Ensure indent is set

        ! Find parent node based on indentation
        parent_node => find_block_sequence_parent(doc%root, new_node)

        if (associated(parent_node)) then
            ! Set sequence flags
            parent_node%is_sequence = .true.

            ! Use parent's key for sequence context
            new_node%key = trim(parent_node%key)

            ! Link as child of parent
            if (.not. associated(parent_node%children)) then
                parent_node%children => new_node
            else
                ! Find end of children list
                current_node => parent_node%children
                do while (associated(current_node%next))
                    current_node => current_node%next
                end do
                current_node%next => new_node
            endif
            status = ERR_SUCCESS
        else
            ! If no parent found, try to add at root level
            if (.not. associated(doc%root)) then
                doc%root => new_node
            else
                current_node => doc%root
                do while (associated(current_node%next))
                    current_node => current_node%next
                end do
                current_node%next => new_node
            endif
            status = ERR_SUCCESS
        endif
        return
    endif

    ! Parse flow-style sequences and mappings - SINGLE BLOCK HERE
    if (index(line, '[') > 0 .or. index(line, '{') > 0) then
        pos = index(local_line, ':')
        if (pos > 0) then
            ! Set up the node
            new_node%key = trim(local_line(1:pos-1))
            new_node%value = trim(adjustl(local_line(pos+1:)))
            new_node%indent = current_indent

            ! Mark as sequence if it's a flow sequence
            new_node%is_sequence = (index(new_node%value, '[') > 0)
            if (new_node%is_sequence) then
                call debug_print(DEBUG_INFO, "Found flow sequence: "//trim(new_node%value))
            endif

            ! Find parent based on indentation
            parent_node => find_parent_by_indent(doc%root, current_indent, line_num)

            if (associated(parent_node)) then
                call debug_print(DEBUG_INFO, "Found parent for flow sequence: "//trim(parent_node%key))
                ! Link as child
                if (.not. associated(parent_node%children)) then
                    parent_node%children => new_node
                else
                    current_node => parent_node%children
                    do while (associated(current_node%next))
                        current_node => current_node%next
                    end do
                    current_node%next => new_node
                endif
                new_node%parent => parent_node
            else
                ! Root level node
                if (.not. associated(doc%root)) then
                    doc%root => new_node
                else
                    current_node => doc%root
                    do while (associated(current_node%next))
                        current_node => current_node%next
                    end do
                    current_node%next => new_node
                endif
            endif

            ! Now parse the flow sequence content
            if (new_node%is_sequence) then
                call parse_flow_form(new_node%value, new_node)
            endif
            status = ERR_SUCCESS
            return
        endif
    else
        ! Regular key-value parsing
        pos = index(local_line, ':')
        if (pos > 0) then
            write(debug_msg, '(A,A)') "Parsing key-value line: ", trim(local_line)
            call debug_print(DEBUG_INFO, debug_msg)

            new_node%key = trim(local_line(1:pos-1))
            new_node%value = trim(adjustl(local_line(pos+1:)))
            new_node%indent = current_indent

            ! Find parent based on indentation
            parent_node => find_parent_by_indent(doc%root, current_indent, line_num)

            write(debug_msg, '(A,A,A,I0,A,L1)') "Node: ", trim(new_node%key), &
                                               " at indent ", current_indent, &
                                               " is root: ", (current_indent == 0)
            call debug_print(DEBUG_INFO, debug_msg)

            if (current_indent == 0) then
                ! Root level node - append to root level
                if (.not. associated(doc%root)) then
                    doc%root => new_node
                else
                    current_node => doc%root
                    do while (associated(current_node%next))
                        current_node => current_node%next
                    end do
                    current_node%next => new_node
                endif
                nullify(new_node%parent)  ! Ensure no parent for root nodes
            else if (associated(parent_node)) then
                write(debug_msg, '(A,A,A,I0)') "Found parent '", trim(parent_node%key), &
                                              "' at indent ", parent_node%indent
                call debug_print(DEBUG_INFO, trim(debug_msg))

                ! Set bidirectional parent-child relationship
                new_node%parent => parent_node

                ! Add as child, properly handling the children list
                if (.not. associated(parent_node%children)) then
                    parent_node%children => new_node
                else
                    ! Find the last child in the chain
                    current_node => parent_node%children
                    do while (associated(current_node%next))
                        current_node => current_node%next
                    end do
                    current_node%next => new_node
                endif

                ! Added: Update sequence flags if needed
                if (parent_node%is_sequence) then
                    new_node%is_sequence = .true.
                endif
            else
                ! No valid parent found for non-root node - error
                write(error_unit,*) "ERROR: No valid parent found for node at line", line_num
                status = ERR_PARSE
                return
            endif

            ! Debug output for node hierarchy
            if (associated(new_node%parent)) then
                write(debug_msg, '(A,A,A,A)') "Node ", trim(new_node%key), &
                                           " has parent ", trim(new_node%parent%key)
            else
                write(debug_msg, '(A,A,A)') "Node ", trim(new_node%key), &
                                         " is at root level"
            endif
            call debug_print(DEBUG_INFO, debug_msg)

            status = ERR_SUCCESS
            return
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

  !> Find or create intermediate nodes to match target indentation
  !!
  !! @param[inout] parent Parent node to start from
  !! @param[in] target_indent Target indentation level
  !! @param[in] new_node Node to link at target indentation
  !! @return Last node created or found at target indentation
  function find_or_create_intermediate_nodes(parent, target_indent, new_node) result(last_node)
    type(yaml_node), pointer, intent(inout) :: parent
    integer, intent(in) :: target_indent
    type(yaml_node), pointer, intent(in) :: new_node
    type(yaml_node), pointer :: last_node, current_node, prev_node
    integer :: current_indent
    character(len=256) :: debug_msg

    nullify(last_node)
    current_indent = parent%indent + indent_width
    prev_node => parent

    do while (current_indent < target_indent)
        ! Find existing node at this indent level
        current_node => prev_node%children
        do while (associated(current_node))
            if (current_node%indent == current_indent) then
                prev_node => current_node
                exit
            endif
            current_node => current_node%next
        end do

        if (.not. associated(current_node)) then
            ! Need to create intermediate node
            allocate(current_node)
            call initialize_node(current_node)
            current_node%indent = current_indent

            ! Link to parent
            if (.not. associated(prev_node%children)) then
                prev_node%children => current_node
            else
                current_node%next => prev_node%children
                prev_node%children => current_node
            endif
            prev_node => current_node
        endif

        current_indent = current_indent + indent_width
    end do

    ! Link final node
    if (.not. associated(prev_node%children)) then
        prev_node%children => new_node
    else
        current_node => prev_node%children
        do while (associated(current_node%next))
            current_node => current_node%next
        end do
        current_node%next => new_node
    endif

    last_node => new_node
  end function find_or_create_intermediate_nodes

  !> Handle block sequence items, ensuring they're properly linked and labeled
  !!
  !! @param[in] line Input line containing sequence item
  !! @param[inout] doc Document being built
  !! @param[inout] node Node representing the sequence item
  !! @param[out] status Status code indicating success or error
  subroutine handle_block_sequence(line, doc, node, status)
    character(len=*), intent(in) :: line
    type(yaml_document), intent(inout) :: doc
    type(yaml_node), pointer, intent(inout) :: node
    integer, intent(out) :: status
    type(yaml_node), pointer :: parent

    ! Set sequence flags and get indentation
    node%is_sequence = .true.  ! Mark current node as sequence
    parent => find_sequence_parent_node(doc%root, node)

    ! Set parent sequence flags
    if (associated(parent)) then
        parent%is_sequence = .true.  ! Mark parent as sequence container
        if (associated(parent%children)) then
            parent%children%is_sequence = .true.  ! Mark children as sequence items
        endif

        ! Set key from parent if not already set
        if (len_trim(node%key) == 0) then
            node%key = trim(adjustl(parent%key))
        endif
    endif

    ! Set root sequence flags if needed
    if (.not. associated(parent) .and. associated(doc%root)) then
        doc%root%is_sequence = .true.
        if (associated(doc%root%children)) then
            doc%root%children%is_sequence = .true.
        endif
    endif

    status = ERR_SUCCESS
  end subroutine handle_block_sequence

  !> Find the last sequence item at a given indentation level
  !!
  !! @param[in] root Root node to start search from
  !! @param[in] indent Indentation level to search for
  !! @return Last sequence item found at the given indentation level
  function find_last_sequence_item(root, indent) result(last_item)
    type(yaml_node), pointer :: root, last_item
    integer, intent(in) :: indent
    type(yaml_node), pointer :: current

    last_item => null()
    current => root
    do while (associated(current))
        if (current%is_sequence .and. count_leading_spaces(current%value) == indent) then
            last_item => current
        endif
        current => current%next
    end do
  end function

  !> Check if node has a sequence parent at given indent
  !!
  !! @param[in] root Root node to start search from
  !! @param[in] indent Indentation level to check for parent
  !! @return True if a sequence parent is found at the given indent
  function has_sequence_parent(root, indent) result(has_parent)
    type(yaml_node), pointer :: root
    integer, intent(in) :: indent
    logical :: has_parent
    type(yaml_node), pointer :: current

    has_parent = .false.
    current => root
    do while (associated(current))
        if (count_leading_spaces(current%value) < indent .and. &
            len_trim(current%key) > 0) then
            has_parent = .true.
            return
        endif
        current => current%next
    end do
  end function

  !> Find the parent key for a sequence
  !!
  !! @param[in] root Root node to start search from
  !! @param[in] indent Indentation level to search for parent key
  !! @param[out] parent_key Key of the parent node found
  subroutine find_sequence_parent(root, indent, parent_key)
    type(yaml_node), pointer :: root
    integer, intent(in) :: indent
    character(len=:), allocatable, intent(out) :: parent_key
    type(yaml_node), pointer :: current
    integer :: current_indent

    parent_key = ''
    current => root
    do while (associated(current))
        current_indent = count_leading_spaces(current%value)
        if (current_indent < indent .and. len_trim(current%key) > 0) then
            parent_key = current%key
            return
        endif
        current => current%next
    end do
  end subroutine

  !> Parse flow-style YAML syntax
  !!
  !! Handles flow-style sequences [...] and mappings {...}
  !!
  !! @param[in] line Input containing flow syntax
  !! @param[inout] node Node to store parsed content
  subroutine parse_flow_form(line, node)
      character(len=*), intent(in) :: line
      type(yaml_node), pointer, intent(inout) :: node
      integer :: pos, start, end, item_start, item_end
      character(len=:), allocatable :: content, item
      type(yaml_node), pointer :: current_item, prev_item
      logical :: in_quotes, in_bracket

      ! Initialize
      in_quotes = .false.
      in_bracket = .false.
      nullify(prev_item)

      ! Handle flow form sequences
      if (index(line, '[') > 0) then
          start = index(line, '[')
          end = index(line, ']')

          if (end > start) then
              content = trim(adjustl(line(start+1:end-1)))
              call debug_print(DEBUG_INFO, "Processing sequence content: "//trim(content))

              ! Parse items
              item_start = 1
              do pos = 1, len_trim(content)
                  select case(content(pos:pos))
                      case ('"')
                          in_quotes = .not. in_quotes
                      case (',')
                          if (.not. in_quotes) then
                              ! Extract item
                              item = trim(adjustl(content(item_start:pos-1)))
                              call add_sequence_item(node, item)
                              item_start = pos + 1
                          endif
                  end select
              end do

              ! Handle last item
              if (item_start <= len_trim(content)) then
                  item = trim(adjustl(content(item_start:)))
                  call add_sequence_item(node, item)
              endif
          endif
      endif
  end subroutine parse_flow_form

  !> Add a new item to a sequence node
  !!
  !! @param[inout] parent Parent node representing the sequence
  !! @param[in] value Value of the new sequence item
  subroutine add_sequence_item(parent, value)
      type(yaml_node), pointer, intent(inout) :: parent
      character(len=*), intent(in) :: value
      type(yaml_node), pointer :: new_item, current
      character(len=:), allocatable :: clean_value

      ! Clean the value
      clean_value = trim(adjustl(value))
      if (len(clean_value) >= 2) then
          if (clean_value(1:1) == '"' .and. clean_value(len_trim(clean_value):len_trim(clean_value)) == '"') then
              clean_value = clean_value(2:len_trim(clean_value)-1)
          endif
      endif

      ! Create new item
      allocate(new_item)
      call initialize_node(new_item)
      new_item%value = clean_value
      new_item%is_sequence = .true.

      ! Add to parent's children
      if (.not. associated(parent%children)) then
          parent%children => new_item
      else
          current => parent%children
          do while (associated(current%next))
              current => current%next
          end do
          current%next => new_item
      endif
  end subroutine add_sequence_item

  !> Parse mapping elements from flow style
  !!
  !! Splits comma-separated key-value pairs into nodes
  !!
  !! @param[inout] content Mapping content string
  !! @param[inout] node Node to store mapping
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
        call debug_print(DEBUG_ERROR, "Invalid node pointer", ERR_PARSE)
        status = ERR_PARSE
        return
    endif

    ! Validate node contents
    if (node%is_sequence .and. .not. associated(node%children)) then
        call debug_print(DEBUG_INFO, "Sequence node without children")
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

  !> Check if string represents a block sequence
  !!
  !! @param[in] str String to check
  !! @return True if string is a block sequence
  function is_block_sequence(str) result(is_block)
    implicit none
    character(len=*), intent(in) :: str
    logical :: is_block

    is_block = (len_trim(str) >= 2 .and. str(1:2) == '- ')
  end function is_block_sequence

  !> Find the last non-sequence node (likely parent)
  !!
  !! @param[in] root Root node to start search from
  !! @return Last non-sequence node found
  function find_last_nonsequence_node(root) result(last_node)
    type(yaml_node), pointer :: root, last_node
    type(yaml_node), pointer :: current

    last_node => null()
    current => root
    do while (associated(current))
        if (.not. current%is_sequence .and. len_trim(current%key) > 0) then
            last_node => current
        endif
        current => current%next
    end do
  end function

  !> Find parent node for block sequence item
  !!
  !! @param[in] root Root node to start search from
  !! @param[in] item_node Node representing the sequence item
  !! @return Parent node found for the sequence item
  function find_block_sequence_parent(root, item_node) result(parent)
    type(yaml_node), pointer :: root, parent, item_node
    character(len=256) :: debug_msg
    type(yaml_node), pointer :: current, best_candidate
    type(stack_entry), allocatable :: stack(:)  ! Now stack_entry is defined
    integer :: item_indent, current_indent, indent_level, stack_top, alloc_stat
    logical :: found_match
    integer, parameter :: MAX_STACK = 100

    nullify(parent)
    nullify(best_candidate)
    found_match = .false.

    ! Allocate stack
    allocate(stack(MAX_STACK), stat=alloc_stat)
    if (alloc_stat /= 0) then
        write(debug_msg, *) "Failed to allocate stack"
        call debug_print(DEBUG_INFO, trim(debug_msg))
        return
    endif
    stack_top = 0  ! Initialize stack

    if (.not. associated(root)) then
        deallocate(stack)
        return
    endif

    item_indent = item_node%indent
    indent_level = -1  ! Track maximum indent level seen

    write(debug_msg, *) "Finding parent for sequence item at indent:", item_indent
    call debug_print(DEBUG_INFO, trim(debug_msg))

    ! Start with root node
    current => root
    do while (associated(current))
        ! Check current node
        if (len_trim(current%key) > 0) then
            current_indent = current%indent

            write(debug_msg, *) "Examining node: '", trim(current%key), &
                              "' at indent:", current_indent
            call debug_print(DEBUG_INFO, trim(debug_msg))

            ! Check if this could be a better parent
            if (current_indent < item_indent) then
                if (current_indent > indent_level) then
                    best_candidate => current
                    indent_level = current_indent
                    found_match = .true.
                    write(debug_msg, *) "New best parent: ", trim(current%key), &
                                      " at indent:", current_indent
                    call debug_print(DEBUG_INFO, trim(debug_msg))
                else if (associated(best_candidate)) then
                    if (trim(current%key) .ne. trim(best_candidate%key)) then
                        best_candidate => current
                        indent_level = current_indent
                        found_match = .true.
                        write(debug_msg, *) "New best parent (different key): ", &
                                          trim(current%key), " at indent:", current_indent
                        call debug_print(DEBUG_INFO, trim(debug_msg))
                    endif
                endif
            endif
        endif

        ! Depth-first traversal using a stack
        ! If there are children, push current to stack and go to children
        if (associated(current%children)) then
            if (stack_top < MAX_STACK) then
                stack_top = stack_top + 1
                stack(stack_top)%node => current
                current => current%children
                cycle
            endif
        endif

        ! If there's a next sibling, go to it
        if (associated(current%next)) then
            current => current%next
            cycle
        endif

        ! No children or next siblings, pop from stack and try next
        do while (stack_top > 0)
            current => stack(stack_top)%node
            stack_top = stack_top - 1
            if (associated(current%next)) then
                current => current%next
                exit
            endif
        end do

        ! If stack is empty and no more nodes to process
        if (stack_top == 0 .and. .not. associated(current%next)) exit
    end do

    ! Use the best candidate found
    if (found_match .and. associated(best_candidate)) then
        parent => best_candidate
        write(debug_msg, *) "Selected parent: ", trim(parent%key), &
                          " at indent:", parent%indent
        call debug_print(DEBUG_INFO, trim(debug_msg))
    else
        write(debug_msg, *) "No suitable parent found for sequence at indent:", item_indent
        call debug_print(DEBUG_INFO, trim(debug_msg))
    endif

    ! Clean up
    deallocate(stack)

  end function find_block_sequence_parent

  !> Detect indentation width from sequence structure
  !!
  !! @param[in] root Root node to start search from
  !! @param[in] item_indent Indentation level of the item
  !! @return Detected indentation width
  function detect_indent_width(root, item_indent) result(width)
    type(yaml_node), pointer, intent(in) :: root
    integer, intent(in) :: item_indent
    integer :: width
    type(yaml_node), pointer :: current
    logical :: found_parent

    ! Start with default
    width = indent_width
    found_parent = .false.

    ! Look for closest parent mapping with less indentation
    current => root
    do while (associated(current))
        if (len_trim(current%key) > 0 .and. &    ! Has key (is mapping)
            current%indent < item_indent .and. &  ! Less indented than item
            .not. current%is_sequence) then       ! Not a sequence item itself

            ! Found potential parent
            if (.not. found_parent) then
                width = item_indent - current%indent
                found_parent = .true.
            else if (current%indent > root%indent) then
                ! Use closest parent's indentation difference
                width = item_indent - current%indent
            endif
        endif
        current => current%next
    end do
  end function detect_indent_width

  !> Find parent node containing key for sequence
  !!
  !! @param[in] root Root node to start search from
  !! @param[in] current Node representing the sequence item
  !! @return Parent node found for the sequence item
  function find_sequence_parent_node(root, current) result(parent)
    type(yaml_node), pointer, intent(in) :: root, current
    type(yaml_node), pointer :: parent, temp
    integer :: current_indent, temp_indent
    character(len=256) :: debug_msg

    nullify(parent)
    if (.not. associated(root)) return

    current_indent = count_leading_spaces(current%value)
    temp => root

    ! Add debug output for node traversal
    write(debug_msg, '(A,A)') "Searching for parent of node with value: ", trim(current%value)
    call debug_print(DEBUG_INFO, trim(debug_msg))

    ! Add indentation level check
    if (current_indent <= 0) then
        write(debug_msg, '(A,I0)') "Warning: Invalid indentation level: ", current_indent
        call debug_print(DEBUG_INFO, trim(debug_msg))
    endif

    ! Traverse tree to find closest parent with less indentation
    do while (associated(temp))
        temp_indent = count_leading_spaces(temp%value)
        if (temp_indent < current_indent .and. len_trim(temp%key) > 0) then
            write(debug_msg, '(A,A,A,I0)') "Found potential parent: ", trim(temp%key), &
                                          " at indent: ", temp_indent
            call debug_print(DEBUG_INFO, trim(debug_msg))

            if (.not. associated(parent) .or. &
                temp_indent > count_leading_spaces(parent%value)) then
                parent => temp
                write(debug_msg, '(A,A)') "Selected as best parent: ", trim(parent%key)
                call debug_print(DEBUG_INFO, trim(debug_msg))
            endif
        endif

        ! Check children before moving to next sibling
        if (associated(temp%children)) then
            write(debug_msg, '(A,A)') "Checking children of node: ", trim(temp%key)
            call debug_print(DEBUG_INFO, trim(debug_msg))
            temp => temp%children
        else if (associated(temp%next)) then
            temp => temp%next
        else
            ! Move up and over if no more siblings
            do while (.not. associated(temp%next) .and. associated(parent))
                temp => parent
                if (associated(temp%next)) then
                    temp => temp%next
                    exit
                endif
            enddo
            if (.not. associated(temp%next)) exit
        endif
    end do

    if (.not. associated(parent)) then
        write(debug_msg, '(A)') "No suitable parent found"
        call debug_print(DEBUG_INFO, trim(debug_msg))
    endif
  end function find_sequence_parent_node

  !> Print the structure of a YAML node and its children for debugging
  !!
  !! @param[in] node Node to print
  !! @param[in] prefix Prefix string for indentation
  !! @param[in] max_depth Optional maximum depth to print
  recursive subroutine debug_print_node_structure(node, prefix, max_depth)
    type(yaml_node), pointer, intent(in) :: node
    character(len=*), intent(in) :: prefix
    integer, intent(in), optional :: max_depth
    type(yaml_node), pointer :: current
    character(len=256) :: debug_msg
    integer :: current_depth

    current_depth = 1
    if (present(max_depth)) then
      if (current_depth > max_depth) return
    endif

    current => node
    do while (associated(current))
      if (len_trim(current%key) > 0 .or. len_trim(current%value) > 0) then
        write(debug_msg, '(A,A,A,A)') prefix, trim(current%key), ": ", trim(current%value)
        call debug_print(DEBUG_INFO, debug_msg)
      endif

      if (associated(current%children)) then
        if (.not. present(max_depth) .or. current_depth < max_depth) then
          call debug_print_node_structure(current%children, trim(prefix)//"  ", current_depth + 1)
        endif
      endif

      current => current%next
    end do
  end subroutine debug_print_node_structure

  !> Find a nested node by key path
  !!
  !! @param[in] node Node to start search from
  !! @param[in] key_path Key path to search for, separated by '%'
  !! @return Found node matching the key path
  recursive function find_nested_node(node, key_path) result(found_node)
    type(yaml_node), pointer :: node, found_node
    character(len=*), intent(in) :: key_path
    integer :: delim_pos
    character(len=:), allocatable :: first_key, remaining_path
    type(yaml_node), pointer :: current

    nullify(found_node)
    if (.not. associated(node)) return

    delim_pos = index(key_path, '%')
    if (delim_pos > 0) then
      first_key = key_path(:delim_pos-1)
      remaining_path = key_path(delim_pos+1:)
    else
      first_key = key_path
      remaining_path = ''
    endif

    ! Search at current level
    current => node
    do while (associated(current))
      if (trim(adjustl(current%key)) == trim(adjustl(first_key))) then
        if (len_trim(remaining_path) == 0) then
          found_node => current
          return
        else if (associated(current%children)) then
          found_node => find_nested_node(current%children, remaining_path)
          return
        endif
      endif
      current => current%next
    end do
  end function find_nested_node

  !> Check if value is a sequence
  !!
  !! @param[in] node Node to check
  !! @return True if the node represents a sequence
  function check_sequence_node(node) result(is_seq)
    type(yaml_node), pointer, intent(in) :: node
    logical :: is_seq
    type(yaml_node), pointer :: current

    is_seq = .false.
    if (associated(node)) then
        ! Check node itself
        if (node%is_sequence) then
            is_seq = .true.
            return
        endif

        ! Check children
        if (associated(node%children)) then
            current => node%children
            ! If any child is marked as sequence, the parent is a sequence container
            do while (associated(current))
                if (current%is_sequence) then
                    is_seq = .true.
                    return
                endif
                current => current%next
            end do
        endif
    endif
  end function check_sequence_node

  !> Get sequence items as string array
  !!
  !! @param[in] node Node representing the sequence
  !! @return Array of sequence items as strings
  function get_sequence_as_strings(node) result(items)
      type(yaml_node), pointer, intent(in) :: node
      character(len=:), allocatable, dimension(:) :: items
      type(yaml_node), pointer :: current
      integer :: count, i
      character(len=256) :: debug_msg
      character(len=:), allocatable :: clean_value

      ! Count items first
      count = 0
      if (associated(node%children)) then
          current => node%children
          do while (associated(current))
              count = count + 1
              current => current%next
          end do
      endif

      ! Allocate result array
      allocate(character(len=32) :: items(count))

      ! Fill array with cleaned values
      if (count > 0) then
          current => node%children
          i = 1
          do while (associated(current))
              ! Get value, ensuring to remove any "- " prefix
              clean_value = trim(adjustl(current%value))
              if (len(clean_value) >= 2 .and. clean_value(1:2) == '- ') then
                  clean_value = trim(adjustl(clean_value(3:)))
              endif

              items(i) = clean_value
              write(debug_msg, '(A,A,A,I0,A,A)') "Node [", trim(node%key), "] Item ", i, ": ", trim(items(i))
              call debug_print(DEBUG_INFO, debug_msg)

              i = i + 1
              current => current%next
          end do
      endif
  end function get_sequence_as_strings

  !> Convert integer to string
  !!
  !! @param[in] num Integer to convert
  !! @return String representation of the integer
  function integer_to_string(num) result(str)
    integer, intent(in) :: num
    character(len=32) :: str
    write(str, '(I0)') num
  end function integer_to_string

  !> Find parent node by indentation level
  !!
  !! @param[in] root Root node to start search from
  !! @param[in] child_indent Indentation level of the child node
  !! @param[in] line_num Line number of the child node
  !! @return Parent node found at the given indentation level
  function find_parent_by_indent(root, child_indent, line_num) result(parent)
    type(yaml_node), pointer :: root, parent
    integer, intent(in) :: child_indent, line_num
    type(yaml_node), pointer :: current, best_parent, last_valid_parent
    type(stack_entry), allocatable :: node_stack(:)
    integer :: stack_top, max_stack_size
    integer :: parent_level_indent
    character(len=256) :: debug_msg
    logical :: is_root_level
    type(yaml_node), pointer :: latest_root

    ! Initialize pointers and variables
    nullify(parent)
    nullify(best_parent)
    nullify(last_valid_parent)
    nullify(latest_root)
    nullify(current)

    ! Early return if root is not associated
    if (.not. associated(root)) then
        call debug_print(DEBUG_INFO, "Root node is not associated")
        return
    endif

    ! Check if this is a root-level node (indent 0)
    is_root_level = (child_indent == 0)
    if (is_root_level) then
        write(debug_msg, '(A,I0)') "Root level node detected at line ", line_num
        call debug_print(DEBUG_INFO, debug_msg)
        nullify(parent)
        return
    endif

    ! Expected parent indent level
    parent_level_indent = child_indent - indent_width

    write(debug_msg, '(A,I0,A,I0,A,I0)') &
        "Looking for parent at indent ", parent_level_indent, &
        " for child at indent ", child_indent, &
        " at line ", line_num
    call debug_print(DEBUG_INFO, debug_msg)

    ! First find the latest root-level node before this line
    current => root
    do while (associated(current))
        if (current%line_num < line_num .and. current%indent == 0) then
            latest_root => current
            write(debug_msg, '(A,A,A,I0)') &
                "Found potential root-level node: ", trim(current%key), &
                " at line ", current%line_num
            call debug_print(DEBUG_INFO, debug_msg)
        endif
        if (.not. associated(current%next)) exit
        current => current%next
    end do

    ! If no root-level node found, search from the actual root
    if (.not. associated(latest_root)) then
        write(debug_msg, '(A,I0)') &
            "No root-level node found before line ", line_num
        call debug_print(DEBUG_INFO, debug_msg)
        latest_root => root  ! Fall back to using the actual root
    endif

    ! Now search for parent starting from latest root node
    current => latest_root
    best_parent => null()  ! Explicitly nullify best_parent
    last_valid_parent => null()  ! Explicitly nullify last_valid_parent

    ! Initialize stack for tree traversal with larger size for deep nesting
    max_stack_size = 1000
    allocate(node_stack(max_stack_size), stat=stack_top)
    if (stack_top /= 0) then
        call debug_print(DEBUG_ERROR, "Failed to allocate node stack")
        return
    endif
    stack_top = 0

    ! Depth-first search with explicit node stack
    do while (associated(current))
        ! Check current node as potential parent
        if (associated(current) .and. len_trim(current%key) > 0) then
            ! Only consider nodes before the current line
            if (current%line_num < line_num) then
                write(debug_msg, '(A,A,A,I0,A,I0)') &
                    "Checking node: ", trim(current%key), &
                    " at line ", current%line_num, &
                    " indent ", current%indent
                call debug_print(DEBUG_INFO, debug_msg)

                ! Check for exact indent match first
                if (current%indent == parent_level_indent) then
                    if (.not. associated(best_parent)) then
                        best_parent => current
                        write(debug_msg, '(A,A,A,I0,A,I0)') &
                            "Found exact indent match: ", trim(current%key), &
                            " at line ", current%line_num, &
                            " indent ", current%indent
                        call debug_print(DEBUG_INFO, debug_msg)
                    else
                        if (associated(best_parent)) then
                            if (current%line_num > best_parent%line_num) then
                                best_parent => current
                                write(debug_msg, '(A,A,A,I0,A,I0)') &
                                    "Found exact indent match: ", trim(current%key), &
                                    " at line ", current%line_num, &
                                    " indent ", current%indent
                                call debug_print(DEBUG_INFO, debug_msg)
                            endif
                        endif
                    endif
                ! Then check for closest valid parent with less indentation
                else if (current%indent < child_indent .and. &
                        current%indent >= 0) then

                    ! First check if we have no valid parent yet
                    if (.not. associated(last_valid_parent)) then
                        last_valid_parent => current
                        write(debug_msg, '(A,A,A,I0,A,I0)') &
                            "Found first valid parent: ", trim(current%key), &
                            " at line ", current%line_num, &
                            " indent ", current%indent
                        call debug_print(DEBUG_INFO, debug_msg)
                    else
                        ! Now we know last_valid_parent is associated, can safely check indent
                        if (current%indent > last_valid_parent%indent) then
                            last_valid_parent => current
                            write(debug_msg, '(A,A,A,I0,A,I0)') &
                                "Found better parent (higher indent): ", trim(current%key), &
                                " at line ", current%line_num, &
                                " indent ", current%indent
                            call debug_print(DEBUG_INFO, debug_msg)
                        else if (current%indent == last_valid_parent%indent .and. &
                                current%line_num > last_valid_parent%line_num) then
                            last_valid_parent => current
                            write(debug_msg, '(A,A,A,I0,A,I0)') &
                                "Found better parent (same indent, later line): ", trim(current%key), &
                                " at line ", current%line_num, &
                                " indent ", current%indent
                            call debug_print(DEBUG_INFO, debug_msg)
                        endif
                    endif
                endif

            endif
        endif

        ! Tree traversal logic - try to go deeper first
        if (associated(current%children)) then
            ! Push current's next sibling onto stack
            if (stack_top < max_stack_size .and. associated(current%next)) then
                stack_top = stack_top + 1
                node_stack(stack_top)%node => current%next
            endif
            ! Move to children
            current => current%children
        else if (associated(current%next)) then
            ! Move to next sibling
            current => current%next
        else if (stack_top > 0) then
            ! Pop from stack
            current => node_stack(stack_top)%node
            stack_top = stack_top - 1
        else
            ! No more nodes to process
            nullify(current)
            exit
        endif
    end do

    ! Select best parent match
    if (associated(best_parent)) then
        parent => best_parent
        write(debug_msg, '(A,A,A,I0,A,I0)') &
            "Selected exact match parent: ", trim(parent%key), &
            " at line ", parent%line_num, &
            " indent ", parent%indent
        call debug_print(DEBUG_INFO, debug_msg)
    else if (associated(last_valid_parent)) then
        parent => last_valid_parent
        write(debug_msg, '(A,A,A,I0,A,I0)') &
            "Selected closest valid parent: ", trim(parent%key), &
            " at line ", parent%line_num, &
            " indent ", parent%indent
        call debug_print(DEBUG_INFO, debug_msg)
    else
        write(debug_msg, '(A,I0,A,I0)') &
            "No suitable parent found for line ", line_num, &
            " at indent ", child_indent
        call debug_print(DEBUG_INFO, debug_msg)
    endif

    ! Clean up
    if (allocated(node_stack)) deallocate(node_stack)

  end function find_parent_by_indent

  !> Check key hierarchy for validity
  !!
  !! @param[in] current Current node to check
  !! @param[in] previous Previous node to compare with
  !! @param[in] target_indent Target indentation level
  !! @return True if the key hierarchy is valid
  function check_key_hierarchy(current, previous, target_indent) result(is_valid)
    type(yaml_node), pointer, intent(in) :: current, previous
    integer, intent(in) :: target_indent
    logical :: is_valid
    character(len=256) :: debug_msg

    is_valid = .true.

    ! If either node is null, hierarchy is invalid
    if (.not. associated(current) .or. .not. associated(previous)) then
        is_valid = .false.
        return
    endif

    ! Check if indentation makes sense
    if (current%indent >= target_indent .or. &
        previous%indent >= target_indent) then
        is_valid = .false.
        return
    endif

    ! Check if current node is at same level or higher than previous
    if (current%indent > previous%indent) then
        is_valid = .false.
        return
    endif

    ! If at same level, check if keys make sense hierarchically
    if (current%indent == previous%indent) then
        if (trim(current%key) == trim(previous%key)) then
            ! Same key at same level is invalid
            is_valid = .false.
        endif
    endif

    write(debug_msg, DBG_FMT_KEY) "Key hierarchy valid: ", is_valid
    if (is_valid) then
        call debug_print(DEBUG_INFO, debug_msg)
    endif
  end function check_key_hierarchy

  !> Record the last key at a given indentation level
  !!
  !! @param[in] indent Indentation level
  !! @param[in] key Key to record
  !! @param[in] line_num Line number of the key
  subroutine record_indent_level(indent, key, line_num)
    integer, intent(in) :: indent, line_num
    character(len=*), intent(in) :: key
    type(indent_tracker), pointer :: current, new_entry

    ! Find or create entry for this indent
    current => indent_history
    do while (associated(current))
      if (current%indent == indent) then
        current%last_key = trim(key)
        current%line_num = line_num
        return
      endif
      current => current%next
    end do

    ! Create new entry
    allocate(new_entry)
    new_entry%indent = indent
    new_entry%last_key = trim(key)
    new_entry%line_num = line_num
    new_entry%next => indent_history
    indent_history => new_entry
  end subroutine

  !> Clean up indent history when done parsing
  subroutine cleanup_indent_history()
    type(indent_tracker), pointer :: current, next

    current => indent_history
    do while (associated(current))
      next => current%next
      deallocate(current)
      current => next
    end do
    indent_history => null()
  end subroutine

end module yaml_parser

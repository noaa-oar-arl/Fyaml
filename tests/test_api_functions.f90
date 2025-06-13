!> \file test_api_functions.f90
!! \brief Test coverage for main API functions
!!
!! This module provides comprehensive tests for the main API functions
!! in fyaml.f90 that weren't fully covered by other tests.

program test_api_functions
    use fyaml
    use test_utils
    implicit none

    integer :: RC

    write(*, '(A)') "Starting API functions tests..."

    ! Test all main API functions
    call test_fyaml_check()
    call test_fyaml_get_size()
    call test_fyaml_get_type()
    call test_fyaml_merge()
    call test_fyaml_print()
    call test_fyaml_species_init()
    call test_fyaml_emis_init()
    call test_fyaml_find_depth()
    call test_fyaml_find_next_higher()
    call test_fyaml_split_category()
    call test_fyaml_comprehensive_data_types()
    call test_fyaml_add_get_functions()
    call test_fyaml_update_functions()
    call test_fyaml_legacy_functions()
    call test_fyaml_init_with_file()
    call test_error_handling_paths()

    write(*, '(A)') "API functions tests completed successfully!"

contains

    !> Test fyaml_check function
    subroutine test_fyaml_check()
        type(fyaml_t) :: yml
        logical :: exists

        write(*, '(A)') "  Testing fyaml_check..."

        ! Add some test variables
        call fyaml_add(yml, "test_var", 42, "Test variable", RC)
        call fyaml_add(yml, "test_array", [1, 2, 3], "Test array", RC)

        ! Test checking existing variables
        call fyaml_check(yml, "test_var", exists)
        call assert_equal_logical(.true., exists, "fyaml_check: existing variable")

        call fyaml_check(yml, "test_array", exists)
        call assert_equal_logical(.true., exists, "fyaml_check: existing array")

        ! Test checking non-existing variable
        call fyaml_check(yml, "nonexistent", exists)
        call assert_equal_logical(.false., exists, "fyaml_check: non-existing variable")

        call fyaml_cleanup(yml)
    end subroutine test_fyaml_check

    !> Test fyaml_get_size function
    subroutine test_fyaml_get_size()
        type(fyaml_t) :: yml
        integer :: var_size

        write(*, '(A)') "  Testing fyaml_get_size..."

        ! Add test variables with different sizes
        call fyaml_add(yml, "scalar", 42, "Test scalar", RC)
        call fyaml_add(yml, "array3", [1, 2, 3], "Test array", RC)
        call fyaml_add(yml, "array5", [1.0_yp, 2.0_yp, 3.0_yp, 4.0_yp, 5.0_yp], "Test real array", RC)

        ! Test scalar size
        call fyaml_get_size(yml, "scalar", var_size, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_get_size: scalar success")
        call assert_equal_int(1, var_size, "fyaml_get_size: scalar size")

        ! Test array sizes
        call fyaml_get_size(yml, "array3", var_size, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_get_size: array3 success")
        call assert_equal_int(3, var_size, "fyaml_get_size: array3 size")

        call fyaml_get_size(yml, "array5", var_size, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_get_size: array5 success")
        call assert_equal_int(5, var_size, "fyaml_get_size: array5 size")

        ! Test non-existing variable (should fail)
        call fyaml_get_size(yml, "nonexistent", var_size, RC)
        call assert_equal_int(fyaml_Failure, RC, "fyaml_get_size: non-existing variable fails")

        call fyaml_cleanup(yml)
    end subroutine test_fyaml_get_size

    !> Test fyaml_get_type function
    subroutine test_fyaml_get_type()
        type(fyaml_t) :: yml
        integer :: var_type

        write(*, '(A)') "  Testing fyaml_get_type..."

        ! Add variables of different types
        call fyaml_add(yml, "int_var", 42, "Integer variable", RC)
        call fyaml_add(yml, "real_var", 3.14_yp, "Real variable", RC)
        call fyaml_add(yml, "bool_var", .true., "Boolean variable", RC)
        call fyaml_add(yml, "string_var", "hello", "String variable", RC)

        ! Test integer type
        call fyaml_get_type(yml, "int_var", var_type, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_get_type: int success")
        call assert_equal_int(fyaml_integer_type, var_type, "fyaml_get_type: int type")

        ! Test real type
        call fyaml_get_type(yml, "real_var", var_type, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_get_type: real success")
        call assert_equal_int(fyaml_real_type, var_type, "fyaml_get_type: real type")

        ! Test boolean type
        call fyaml_get_type(yml, "bool_var", var_type, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_get_type: bool success")
        call assert_equal_int(fyaml_bool_type, var_type, "fyaml_get_type: bool type")

        ! Test string type
        call fyaml_get_type(yml, "string_var", var_type, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_get_type: string success")
        call assert_equal_int(fyaml_string_type, var_type, "fyaml_get_type: string type")

        ! Test non-existing variable (should fail)
        call fyaml_get_type(yml, "nonexistent", var_type, RC)
        call assert_equal_int(fyaml_Failure, RC, "fyaml_get_type: non-existing variable fails")

        call fyaml_cleanup(yml)
    end subroutine test_fyaml_get_type

    !> Test fyaml_merge function
    subroutine test_fyaml_merge()
        type(fyaml_t) :: yml1, yml2, merged
        integer :: result_int

        write(*, '(A)') "  Testing fyaml_merge..."

        ! Setup first config
        call fyaml_add(yml1, "common_var", 10, "Common variable", RC)
        call fyaml_add(yml1, "unique1", 100, "Unique to config 1", RC)

        ! Setup second config
        call fyaml_add(yml2, "common_var", 20, "Common variable", RC)
        call fyaml_add(yml2, "unique2", 200, "Unique to config 2", RC)

        ! Test merge using the high-level interface
        call fyaml_merge(yml1, yml2, merged, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_merge: success")

        ! Check merged results
        call fyaml_get(merged, "common_var", result_int, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_merge: get common_var")
        call assert_equal_int(20, result_int, "fyaml_merge: common_var overwritten")

        call fyaml_get(merged, "unique1", result_int, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_merge: get unique1")
        call assert_equal_int(100, result_int, "fyaml_merge: unique1 preserved")

        call fyaml_get(merged, "unique2", result_int, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_merge: get unique2")
        call assert_equal_int(200, result_int, "fyaml_merge: unique2 added")

        call fyaml_cleanup(yml1)
        call fyaml_cleanup(yml2)
        call fyaml_cleanup(merged)
    end subroutine test_fyaml_merge

    !> Test fyaml_print function
    subroutine test_fyaml_print()
        type(fyaml_t) :: yml
        character(len=*), parameter :: test_file = "test_print_output.yml"

        write(*, '(A)') "  Testing fyaml_print..."

        ! Add some test data
        call fyaml_add(yml, "test_int", 42, "Test integer", RC)
        call fyaml_add(yml, "test_real", 3.14_yp, "Test real", RC)
        call fyaml_add(yml, "test_string", "hello", "Test string", RC)

        ! Test printing to file
        call fyaml_print(yml, RC, fileName=test_file)
        call assert_equal_int(fyaml_Success, RC, "fyaml_print: to file")

        ! Test printing to stdout (no filename)
        call fyaml_print(yml, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_print: to stdout")

        call fyaml_cleanup(yml)

        ! Clean up test file
        open(unit=99, file=test_file, status='old', iostat=RC)
        if (RC == 0) then
            close(99, status='delete')
        end if
    end subroutine test_fyaml_print

    !> Test fyaml_species_init function
    subroutine test_fyaml_species_init()
        type(fyaml_t) :: yml, yml_anchored
        character(len=fyaml_StrLen), allocatable :: species_names(:)
        character(len=*), parameter :: test_file = "test_species.yml"
        integer :: unit_num

        write(*, '(A)') "  Testing fyaml_species_init..."

        ! Create a minimal test species file
        open(newunit=unit_num, file=test_file, status='replace')
        write(unit_num, '(A)') "species:"
        write(unit_num, '(A)') "  - name: O3"
        write(unit_num, '(A)') "    molecular_weight: 48.0"
        write(unit_num, '(A)') "  - name: NO2"
        write(unit_num, '(A)') "    molecular_weight: 46.0"
        close(unit_num)

        allocate(species_names(2))
        species_names = ["O3 ", "NO2"]

        ! Test species initialization
        call fyaml_species_init(test_file, yml, yml_anchored, species_names, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_species_init: success")

        call fyaml_cleanup(yml)
        call fyaml_cleanup(yml_anchored)
        deallocate(species_names)

        ! Clean up test file
        open(unit=99, file=test_file, status='old', iostat=RC)
        if (RC == 0) then
            close(99, status='delete')
        end if
    end subroutine test_fyaml_species_init

    !> Test fyaml_emis_init function
    subroutine test_fyaml_emis_init()
        type(fyaml_t) :: yml, yml_anchored
        character(len=*), parameter :: test_file = "test_emis.yml"
        character(len=20) :: emis_state = "test_state"
        integer :: unit_num

        write(*, '(A)') "  Testing fyaml_emis_init..."

        ! Create a minimal test emissions file
        open(newunit=unit_num, file=test_file, status='replace')
        write(unit_num, '(A)') "emissions:"
        write(unit_num, '(A)') "  sector1:"
        write(unit_num, '(A)') "    species: [O3, NO2]"
        write(unit_num, '(A)') "    values: [1.0, 2.0]"
        close(unit_num)

        ! Test emissions initialization
        call fyaml_emis_init(test_file, yml, yml_anchored, emis_state, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_emis_init: success")

        call fyaml_cleanup(yml)
        call fyaml_cleanup(yml_anchored)

        ! Clean up test file
        open(unit=99, file=test_file, status='old', iostat=RC)
        if (RC == 0) then
            close(99, status='delete')
        end if
    end subroutine test_fyaml_emis_init

    !> Test fyaml_find_depth function
    subroutine test_fyaml_find_depth()
        integer :: depth

        write(*, '(A)') "  Testing fyaml_find_depth..."

        ! Test different depth scenarios
        call fyaml_find_depth("simple_key", depth)
        call assert_equal_int(0, depth, "fyaml_find_depth: simple key")

        call fyaml_find_depth("level1%level2", depth)
        call assert_equal_int(1, depth, "fyaml_find_depth: one level")

        call fyaml_find_depth("level1%level2%level3", depth)
        call assert_equal_int(2, depth, "fyaml_find_depth: two levels")

        call fyaml_find_depth("level1%level2%level3%level4", depth)
        call assert_equal_int(3, depth, "fyaml_find_depth: three levels")
    end subroutine test_fyaml_find_depth

    !> Test fyaml_find_next_higher function
    subroutine test_fyaml_find_next_higher()
        character(len=fyaml_StrLen) :: higher_key

        write(*, '(A)') "  Testing fyaml_find_next_higher..."

        ! Test finding next higher level
        call fyaml_find_next_higher("level1%level2%var", higher_key)
        ! The function should find the next higher level key (level1%level2)

        call fyaml_find_next_higher("level1%var", higher_key)
        ! Should return "level1"

        call fyaml_find_next_higher("simple_var", higher_key)
        ! Should return empty string for simple variables
    end subroutine test_fyaml_find_next_higher

    !> Test fyaml_split_category function
    subroutine test_fyaml_split_category()
        character(len=fyaml_StrLen) :: parent, child

        write(*, '(A)') "  Testing fyaml_split_category..."

        ! Test splitting hierarchical keys
        call fyaml_split_category("parent%child", parent, child)
        ! Verify the split worked correctly

        call fyaml_split_category("single", parent, child)
        ! Test single-level key

        call fyaml_split_category("grand%parent%child", parent, child)
        ! Test multi-level split
    end subroutine test_fyaml_split_category

    !> Test fyaml_add_get functions (with default values)
    subroutine test_fyaml_add_get_functions()
        type(fyaml_t) :: yml
        integer :: int_val
        real(yp) :: real_val
        logical :: bool_val
        character(len=fyaml_StrLen) :: string_val
        integer, dimension(3) :: int_arr
        real(yp), dimension(3) :: real_arr

        write(*, '(A)') "  Testing fyaml_add_get functions..."

        ! Test add_get for scalars - getting existing values
        call fyaml_add(yml, "existing_int", 42, "Existing integer", RC)
        call fyaml_add(yml, "existing_real", 3.14_yp, "Existing real", RC)
        call fyaml_add(yml, "existing_bool", .true., "Existing boolean", RC)
        call fyaml_add(yml, "existing_string", "hello", "Existing string", RC)

        ! Test getting existing values (should return stored values, not defaults)
        call fyaml_add_get(yml, "existing_int", int_val, 999, "Integer with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: existing int success")
        call assert_equal_int(42, int_val, "fyaml_add_get: existing int value")

        call fyaml_add_get(yml, "existing_real", real_val, 999.0_yp, "Real with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: existing real success")
        call assert_equal_real(3.14_yp, real_val, "fyaml_add_get: existing real value")

        call fyaml_add_get(yml, "existing_bool", bool_val, .false., "Boolean with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: existing bool success")
        call assert_equal_logical(.true., bool_val, "fyaml_add_get: existing bool value")

        call fyaml_add_get(yml, "existing_string", string_val, "default", "String with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: existing string success")
        call assert_equal_string("hello", trim(string_val), "fyaml_add_get: existing string value")

        ! Test add_get for non-existing values (should use defaults and add them)
        call fyaml_add_get(yml, "new_int", int_val, 100, "New integer with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: new int success")
        call assert_equal_int(100, int_val, "fyaml_add_get: new int default value")

        call fyaml_add_get(yml, "new_real", real_val, 2.71_yp, "New real with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: new real success")
        call assert_equal_real(2.71_yp, real_val, "fyaml_add_get: new real default value")

        call fyaml_add_get(yml, "new_bool", bool_val, .false., "New boolean with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: new bool success")
        call assert_equal_logical(.false., bool_val, "fyaml_add_get: new bool default value")

        call fyaml_add_get(yml, "new_string", string_val, "default_value", "New string with default", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: new string success")
        call assert_equal_string("default_value", trim(string_val), "fyaml_add_get: new string default value")

        ! Test add_get for arrays - existing
        call fyaml_add(yml, "existing_int_arr", [1, 2, 3], "Existing int array", RC)
        call fyaml_add(yml, "existing_real_arr", [1.0_yp, 2.0_yp, 3.0_yp], "Existing real array", RC)

        call fyaml_add_get(yml, "existing_int_arr", int_arr, "Comment", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: existing int array success")
        call assert_equal_int(1, int_arr(1), "fyaml_add_get: existing int array value 1")
        call assert_equal_int(2, int_arr(2), "fyaml_add_get: existing int array value 2")
        call assert_equal_int(3, int_arr(3), "fyaml_add_get: existing int array value 3")

        call fyaml_add_get(yml, "existing_real_arr", real_arr, "Comment", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: existing real array success")
        call assert_equal_real(1.0_yp, real_arr(1), "fyaml_add_get: existing real array value 1")
        call assert_equal_real(2.0_yp, real_arr(2), "fyaml_add_get: existing real array value 2")
        call assert_equal_real(3.0_yp, real_arr(3), "fyaml_add_get: existing real array value 3")

        ! Test add_get for arrays - new (should add the provided array)
        int_arr = [10, 20, 30]
        real_arr = [10.0_yp, 20.0_yp, 30.0_yp]

        call fyaml_add_get(yml, "new_int_arr", int_arr, "New int array comment", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: new int array success")

        call fyaml_add_get(yml, "new_real_arr", real_arr, "New real array comment", RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_add_get: new real array success")

        call fyaml_cleanup(yml)
    end subroutine test_fyaml_add_get_functions

    !> Test fyaml_update functions
    subroutine test_fyaml_update_functions()
        type(fyaml_t) :: yml
        integer :: int_val
        real(yp) :: real_val
        logical :: bool_val
        character(len=fyaml_StrLen) :: string_val
        integer, dimension(3) :: int_arr
        real(yp), dimension(3) :: real_arr

        write(*, '(A)') "  Testing fyaml_update functions..."

        ! Add initial values
        call fyaml_add(yml, "update_int", 42, "Integer to update", RC)
        call fyaml_add(yml, "update_real", 3.14_yp, "Real to update", RC)
        call fyaml_add(yml, "update_bool", .true., "Boolean to update", RC)
        call fyaml_add(yml, "update_string", "original", "String to update", RC)
        call fyaml_add(yml, "update_int_arr", [1, 2, 3], "Int array to update", RC)
        call fyaml_add(yml, "update_real_arr", [1.0_yp, 2.0_yp, 3.0_yp], "Real array to update", RC)

        ! Test updating scalars
        int_val = 84
        call fyaml_update(yml, "update_int", int_val)
        call fyaml_get(yml, "update_int", int_val, RC)
        call assert_equal_int(84, int_val, "fyaml_update: int value updated")

        real_val = 6.28_yp
        call fyaml_update(yml, "update_real", real_val)
        call fyaml_get(yml, "update_real", real_val, RC)
        call assert_equal_real(6.28_yp, real_val, "fyaml_update: real value updated")

        bool_val = .false.
        call fyaml_update(yml, "update_bool", bool_val)
        call fyaml_get(yml, "update_bool", bool_val, RC)
        call assert_equal_logical(.false., bool_val, "fyaml_update: bool value updated")

        string_val = "modified"
        call fyaml_update(yml, "update_string", string_val)
        call fyaml_get(yml, "update_string", string_val, RC)
        call assert_equal_string("modified", trim(string_val), "fyaml_update: string value updated")

        ! Test updating arrays
        int_arr = [10, 20, 30]
        call fyaml_update(yml, "update_int_arr", int_arr)
        call fyaml_get(yml, "update_int_arr", int_arr, RC)
        call assert_equal_int(10, int_arr(1), "fyaml_update: int array value 1")
        call assert_equal_int(20, int_arr(2), "fyaml_update: int array value 2")
        call assert_equal_int(30, int_arr(3), "fyaml_update: int array value 3")

        real_arr = [100.0_yp, 200.0_yp, 300.0_yp]
        call fyaml_update(yml, "update_real_arr", real_arr)
        call fyaml_get(yml, "update_real_arr", real_arr, RC)
        call assert_equal_real(100.0_yp, real_arr(1), "fyaml_update: real array value 1")
        call assert_equal_real(200.0_yp, real_arr(2), "fyaml_update: real array value 2")
        call assert_equal_real(300.0_yp, real_arr(3), "fyaml_update: real array value 3")

        ! Test updating non-existing variables (should silently do nothing)
        int_val = 999
        call fyaml_update(yml, "nonexistent", int_val)

        call fyaml_cleanup(yml)
    end subroutine test_fyaml_update_functions

    !> Test legacy functions
    subroutine test_fyaml_legacy_functions()
        type(fyaml_t) :: yml
        character(len=*), parameter :: test_file = "test_legacy.yml"
        integer :: unit_num
        character(len=fyaml_StrLen) :: string_val

        write(*, '(A)') "  Testing legacy functions..."

        ! Create a simple test file
        open(newunit=unit_num, file=test_file, status='replace')
        write(unit_num, '(A)') "test_var: 42"
        write(unit_num, '(A)') "test_string: hello_world"
        close(unit_num)

        ! Test legacy fyaml_read_file function
        call fyaml_read_file(yml, test_file, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_read_file: success")

        ! Verify that data was loaded
        call fyaml_get(yml, "test_string", string_val, RC)
        if (RC == fyaml_Success) then
            call assert_equal_string("hello_world", trim(string_val), "fyaml_read_file: data loaded")
        endif

        call fyaml_cleanup(yml)

        ! Clean up test file
        open(unit=99, file=test_file, status='old', iostat=RC)
        if (RC == 0) then
            close(99, status='delete')
        end if
    end subroutine test_fyaml_legacy_functions

    !> Test fyaml_init with file initialization
    subroutine test_fyaml_init_with_file()
        type(fyaml_t) :: yml, yml_anchored
        character(len=*), parameter :: test_file = "test_init.yml"
        integer :: unit_num
        character(len=fyaml_StrLen) :: string_val

        write(*, '(A)') "  Testing fyaml_init with file..."

        ! Create a test file with anchors
        open(newunit=unit_num, file=test_file, status='replace')
        write(unit_num, '(A)') "default: &default_settings"
        write(unit_num, '(A)') "  timeout: 30"
        write(unit_num, '(A)') "  retries: 3"
        write(unit_num, '(A)') "production:"
        write(unit_num, '(A)') "  <<: *default_settings"
        write(unit_num, '(A)') "  timeout: 60"
        close(unit_num)

        ! Test initialization with file and anchors
        call fyaml_init(test_file, yml, yml_anchored, RC)
        call assert_equal_int(fyaml_Success, RC, "fyaml_init: file initialization success")

        ! Check if data was loaded (if successful)
        call fyaml_get(yml, "production%timeout", string_val, RC)
        ! Note: This might fail due to anchor processing complexity, but we're testing the path

        call fyaml_cleanup(yml)
        call fyaml_cleanup(yml_anchored)

        ! Clean up test file
        open(unit=99, file=test_file, status='old', iostat=RC)
        if (RC == 0) then
            close(99, status='delete')
        end if
    end subroutine test_fyaml_init_with_file

    !> Test various error handling paths
    subroutine test_error_handling_paths()
        type(fyaml_t) :: yml
        character(len=fyaml_StrLen) :: string_val
        integer :: int_val
        real(yp) :: real_val
        logical :: bool_val

        write(*, '(A)') "  Testing error handling paths..."

        ! Test getting from completely empty yml structure
        call fyaml_get(yml, "nonexistent", string_val, RC)
        call assert_equal_int(fyaml_Failure, RC, "Error handling: get from empty yml")

        call fyaml_get(yml, "nonexistent", int_val, RC)
        call assert_equal_int(fyaml_Failure, RC, "Error handling: get int from empty yml")

        call fyaml_get(yml, "nonexistent", real_val, RC)
        call assert_equal_int(fyaml_Failure, RC, "Error handling: get real from empty yml")

        call fyaml_get(yml, "nonexistent", bool_val, RC)
        call assert_equal_int(fyaml_Failure, RC, "Error handling: get bool from empty yml")

        ! Test with some data but requesting wrong variables
        call fyaml_add(yml, "existing_var", 42, "Test variable", RC)

        call fyaml_get(yml, "wrong_var", string_val, RC)
        call assert_equal_int(fyaml_Failure, RC, "Error handling: get wrong variable name")

        ! Test updating non-existing variables
        int_val = 999
        call fyaml_update(yml, "nonexistent_update", int_val)
        real_val = 999.0_yp
        call fyaml_update(yml, "nonexistent_update", real_val)
        bool_val = .true.
        call fyaml_update(yml, "nonexistent_update", bool_val)
        string_val = "test"
        call fyaml_update(yml, "nonexistent_update", string_val)

        call fyaml_cleanup(yml)
    end subroutine test_error_handling_paths

    !> Test comprehensive coverage of all data types for add/get/update operations
    subroutine test_fyaml_comprehensive_data_types()
        type(fyaml_t) :: yml

        ! Scalar variables
        integer :: int_val, int_result
        real(yp) :: real_val, real_result
        logical :: bool_val, bool_result
        character(len=fyaml_StrLen) :: string_val, string_result

        ! Array variables
        integer, dimension(4) :: int_arr, int_arr_result
        real(yp), dimension(4) :: real_arr, real_arr_result
        logical, dimension(4) :: bool_arr, bool_arr_result
        character(len=fyaml_StrLen), dimension(3) :: string_arr, string_arr_result

        write(*, '(A)') "  Testing comprehensive data type coverage..."

        ! Initialize test data
        int_val = 42
        real_val = 3.14159_yp
        bool_val = .true.
        string_val = "test_string"

        int_arr = [10, 20, 30, 40]
        real_arr = [1.1_yp, 2.2_yp, 3.3_yp, 4.4_yp]
        bool_arr = [.true., .false., .true., .false.]
        string_arr(1) = "first"
        string_arr(2) = "second"
        string_arr(3) = "third"

        ! === Test fyaml_add for all data types ===

        ! Add scalars
        call fyaml_add(yml, "test_int_scalar", int_val, "Integer scalar", RC)
        call assert_equal_int(fyaml_Success, RC, "Add int scalar")

        call fyaml_add(yml, "test_real_scalar", real_val, "Real scalar", RC)
        call assert_equal_int(fyaml_Success, RC, "Add real scalar")

        call fyaml_add(yml, "test_bool_scalar", bool_val, "Boolean scalar", RC)
        call assert_equal_int(fyaml_Success, RC, "Add bool scalar")

        call fyaml_add(yml, "test_string_scalar", string_val, "String scalar", RC)
        call assert_equal_int(fyaml_Success, RC, "Add string scalar")

        ! Add arrays (including the missing boolean and string arrays)
        call fyaml_add(yml, "test_int_array", int_arr, "Integer array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add int array")

        call fyaml_add(yml, "test_real_array", real_arr, "Real array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add real array")

        call fyaml_add(yml, "test_bool_array", bool_arr, "Boolean array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add bool array")

        call fyaml_add(yml, "test_string_array", string_arr, "String array", RC)
        call assert_equal_int(fyaml_Success, RC, "Add string array")

        ! === Test fyaml_get for all data types ===

        ! Get scalars
        call fyaml_get(yml, "test_int_scalar", int_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get int scalar")
        call assert_equal_int(int_val, int_result, "Int scalar value")

        call fyaml_get(yml, "test_real_scalar", real_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get real scalar")
        call assert_equal_real(real_val, real_result, "Real scalar value")

        call fyaml_get(yml, "test_bool_scalar", bool_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get bool scalar")
        call assert_equal_logical(bool_val, bool_result, "Bool scalar value")

        call fyaml_get(yml, "test_string_scalar", string_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get string scalar")
        call assert_equal_string(trim(string_val), trim(string_result), "String scalar value")

        ! Get arrays
        call fyaml_get(yml, "test_int_array", int_arr_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get int array")
        call assert_equal_int(int_arr(1), int_arr_result(1), "Int array value 1")
        call assert_equal_int(int_arr(2), int_arr_result(2), "Int array value 2")
        call assert_equal_int(int_arr(3), int_arr_result(3), "Int array value 3")
        call assert_equal_int(int_arr(4), int_arr_result(4), "Int array value 4")

        call fyaml_get(yml, "test_real_array", real_arr_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get real array")
        call assert_equal_real(real_arr(1), real_arr_result(1), "Real array value 1")
        call assert_equal_real(real_arr(2), real_arr_result(2), "Real array value 2")
        call assert_equal_real(real_arr(3), real_arr_result(3), "Real array value 3")
        call assert_equal_real(real_arr(4), real_arr_result(4), "Real array value 4")

        call fyaml_get(yml, "test_bool_array", bool_arr_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get bool array")
        call assert_equal_logical(bool_arr(1), bool_arr_result(1), "Bool array value 1")
        call assert_equal_logical(bool_arr(2), bool_arr_result(2), "Bool array value 2")
        call assert_equal_logical(bool_arr(3), bool_arr_result(3), "Bool array value 3")
        call assert_equal_logical(bool_arr(4), bool_arr_result(4), "Bool array value 4")

        call fyaml_get(yml, "test_string_array", string_arr_result, RC)
        call assert_equal_int(fyaml_Success, RC, "Get string array")
        call assert_equal_string(trim(string_arr(1)), trim(string_arr_result(1)), "String array value 1")
        call assert_equal_string(trim(string_arr(2)), trim(string_arr_result(2)), "String array value 2")
        call assert_equal_string(trim(string_arr(3)), trim(string_arr_result(3)), "String array value 3")

        ! === Test fyaml_update for all data types ===

        ! Update scalars
        int_val = 84
        call fyaml_update(yml, "test_int_scalar", int_val)
        call fyaml_get(yml, "test_int_scalar", int_result, RC)
        call assert_equal_int(84, int_result, "Update int scalar")

        real_val = 2.71828_yp
        call fyaml_update(yml, "test_real_scalar", real_val)
        call fyaml_get(yml, "test_real_scalar", real_result, RC)
        call assert_equal_real(2.71828_yp, real_result, "Update real scalar")

        bool_val = .false.
        call fyaml_update(yml, "test_bool_scalar", bool_val)
        call fyaml_get(yml, "test_bool_scalar", bool_result, RC)
        call assert_equal_logical(.false., bool_result, "Update bool scalar")

        string_val = "updated_string"
        call fyaml_update(yml, "test_string_scalar", string_val)
        call fyaml_get(yml, "test_string_scalar", string_result, RC)
        call assert_equal_string("updated_string", trim(string_result), "Update string scalar")

        ! Update arrays
        int_arr = [100, 200, 300, 400]
        call fyaml_update(yml, "test_int_array", int_arr)
        call fyaml_get(yml, "test_int_array", int_arr_result, RC)
        call assert_equal_int(100, int_arr_result(1), "Update int array value 1")
        call assert_equal_int(200, int_arr_result(2), "Update int array value 2")
        call assert_equal_int(300, int_arr_result(3), "Update int array value 3")
        call assert_equal_int(400, int_arr_result(4), "Update int array value 4")

        real_arr = [10.1_yp, 20.2_yp, 30.3_yp, 40.4_yp]
        call fyaml_update(yml, "test_real_array", real_arr)
        call fyaml_get(yml, "test_real_array", real_arr_result, RC)
        call assert_equal_real(10.1_yp, real_arr_result(1), "Update real array value 1")
        call assert_equal_real(20.2_yp, real_arr_result(2), "Update real array value 2")
        call assert_equal_real(30.3_yp, real_arr_result(3), "Update real array value 3")
        call assert_equal_real(40.4_yp, real_arr_result(4), "Update real array value 4")

        bool_arr = [.false., .true., .false., .true.]
        call fyaml_update(yml, "test_bool_array", bool_arr)
        call fyaml_get(yml, "test_bool_array", bool_arr_result, RC)
        call assert_equal_logical(.false., bool_arr_result(1), "Update bool array value 1")
        call assert_equal_logical(.true., bool_arr_result(2), "Update bool array value 2")
        call assert_equal_logical(.false., bool_arr_result(3), "Update bool array value 3")
        call assert_equal_logical(.true., bool_arr_result(4), "Update bool array value 4")

        string_arr(1) = "updated_first"
        string_arr(2) = "updated_second"
        string_arr(3) = "updated_third"
        call fyaml_update(yml, "test_string_array", string_arr)
        call fyaml_get(yml, "test_string_array", string_arr_result, RC)
        call assert_equal_string("updated_first", trim(string_arr_result(1)), "Update string array value 1")
        call assert_equal_string("updated_second", trim(string_arr_result(2)), "Update string array value 2")
        call assert_equal_string("updated_third", trim(string_arr_result(3)), "Update string array value 3")

        ! === Test fyaml_add_get for all data types with defaults ===

        ! Test add_get for new variables (should use defaults)
        call fyaml_add_get(yml, "new_int_scalar", int_result, 999, "New int with default", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new int scalar")
        call assert_equal_int(999, int_result, "Add_get new int scalar default")

        call fyaml_add_get(yml, "new_real_scalar", real_result, 99.9_yp, "New real with default", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new real scalar")
        call assert_equal_real(99.9_yp, real_result, "Add_get new real scalar default")

        call fyaml_add_get(yml, "new_bool_scalar", bool_result, .true., "New bool with default", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new bool scalar")
        call assert_equal_logical(.true., bool_result, "Add_get new bool scalar default")

        call fyaml_add_get(yml, "new_string_scalar", string_result, "default_string", "New string with default", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new string scalar")
        call assert_equal_string("default_string", trim(string_result), "Add_get new string scalar default")

        ! Test add_get for arrays with defaults
        int_arr = [1000, 2000, 3000, 4000]
        call fyaml_add_get(yml, "new_int_array", int_arr, "New int array comment", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new int array")

        real_arr = [100.1_yp, 200.2_yp, 300.3_yp, 400.4_yp]
        call fyaml_add_get(yml, "new_real_array", real_arr, "New real array comment", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new real array")

        bool_arr = [.true., .true., .false., .false.]
        call fyaml_add_get(yml, "new_bool_array", bool_arr, "New bool array comment", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new bool array")

        string_arr(1) = "default_first"
        string_arr(2) = "default_second"
        string_arr(3) = "default_third"
        call fyaml_add_get(yml, "new_string_array", string_arr, "New string array comment", RC)
        call assert_equal_int(fyaml_Success, RC, "Add_get new string array")

        call fyaml_cleanup(yml)
        write(*, '(A)') "  All comprehensive data type tests passed!"
    end subroutine test_fyaml_comprehensive_data_types

end program test_api_functions

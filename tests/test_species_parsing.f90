!> \file test_species_parsing.f90
!! \brief Test species parsing functionality

program test_species_parsing
    use fyaml
    use test_utils
    implicit none

    character(len=512) :: config_file

    call print_test_header("Species Parsing")

    ! Get the test data path
    config_file = trim(get_test_data_path()) // "/example_config.yml"

    call test_species_extraction(config_file)
    call test_species_uniqueness()

    call print_test_result()

    ! Exit with error code if tests failed
    if (tests_failed > 0) stop 1

contains

    subroutine test_species_extraction(filename)
        character(len=*), intent(in) :: filename
        character(len=fyaml_NamLen), allocatable :: species(:)
        type(fyaml_t) :: yml, yml_anchored
        integer :: RC

        ! Test species parsing using the correct interface
        call fyaml_parse_species_file(filename, yml, yml_anchored, species, RC)
        call assert_equal_int(fyaml_Success, RC, "Species parsing return code")

        ! Check that species were extracted
        call assert_true(allocated(species), "Species array allocated")
        if (allocated(species)) then
            call assert_true(size(species) > 0, "Species extracted from file")

            write(*,'(A,I0,A)') "Extracted ", size(species), " unique species from config file"

            ! Check some expected species
            if (size(species) > 0) then
                call assert_true(len_trim(species(1)) > 0, "First species has content")

                ! Print extracted species for debugging
                write(*,'(A)') "Extracted species:"
                do RC = 1, min(size(species), 10)  ! Print first 10
                    write(*,'(A,I0,A,A)') "  ", RC, ": ", trim(species(RC))
                end do
            endif
        endif

        ! Clean up
        call fyaml_cleanup(yml)
        call fyaml_cleanup(yml_anchored)
        if (allocated(species)) deallocate(species)
    end subroutine test_species_extraction

    subroutine test_species_uniqueness()
        character(len=fyaml_NamLen), allocatable :: species(:)
        type(fyaml_t) :: yml, yml_anchored
        integer :: RC, i, j
        logical :: unique_found

        ! Create a temporary YAML file with duplicate species
        call create_test_species_file()

        ! Parse the test file
        call fyaml_parse_species_file("test_species.yml", yml, yml_anchored, species, RC)
        call assert_equal_int(fyaml_Success, RC, "Test species file parsing")

        ! Check for uniqueness
        unique_found = .true.
        if (allocated(species) .and. size(species) > 1) then
            do i = 1, size(species) - 1
                do j = i + 1, size(species)
                    if (trim(species(i)) == trim(species(j))) then
                        unique_found = .false.
                        exit
                    endif
                end do
                if (.not. unique_found) exit
            end do
        endif

        call assert_true(unique_found, "Species uniqueness check")

        ! Clean up
        call fyaml_cleanup(yml)
        call fyaml_cleanup(yml_anchored)
        if (allocated(species)) deallocate(species)

        ! Clean up test file
        call execute_command_line("rm -f test_species.yml")
    end subroutine test_species_uniqueness

    subroutine create_test_species_file()
        integer :: unit

        open(newunit=unit, file="test_species.yml", status="replace")
        write(unit, '(A)') "chemistry:"
        write(unit, '(A)') "  species:"
        write(unit, '(A)') "    - NO2"
        write(unit, '(A)') "    - O3"
        write(unit, '(A)') "    - NO"
        write(unit, '(A)') "    - NO2"  ! Duplicate
        write(unit, '(A)') "    - CO"
        write(unit, '(A)') "    - O3"   ! Duplicate
        write(unit, '(A)') "atmospheric_chemistry:"
        write(unit, '(A)') "  species_list:"
        write(unit, '(A)') "    - SO2"
        write(unit, '(A)') "    - NH3"
        write(unit, '(A)') "    - NO2"  ! Duplicate from above
        close(unit)
    end subroutine create_test_species_file

end program test_species_parsing

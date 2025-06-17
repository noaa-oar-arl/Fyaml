!> \file fyaml_error.f90
!! \brief Error handling utilities for FYAML
!!
!! This module provides centralized error handling functionality
!! for the FYAML library.
!!
!! \author FYAML Development Team
!! \date 2025
!! \version 1.0

module fyaml_error
    use fyaml_constants, only: fyaml_Failure
    implicit none
    private

    public :: fyaml_handle_error

contains

    !> \brief Handle an error condition
    !!
    !! This subroutine provides centralized error handling with
    !! formatted output and return code setting.
    !!
    !! \param[in] errMsg The error message to display
    !! \param[out] RC Return code (set to fyaml_Failure)
    !! \param[in] thisLoc Optional location information
    subroutine fyaml_handle_error(errMsg, RC, thisLoc)
        character(len=*), intent(in)  :: errMsg    ! Error message
        integer,          intent(out) :: RC        ! Return code
        character(len=*), optional, intent(in) :: thisLoc

        ! Write formatted error message
        write(6, "(a)") repeat("=", 79)
        write(6, "(a)") "fyaml ERROR: " // trim(errMsg)
        if (present(thisLoc)) write(6, '(a)') trim(thisLoc)
        write(6, "(a)") repeat("=", 79)
        write(6, "(a)")

        ! Return failure
        RC = fyaml_Failure

    end subroutine fyaml_handle_error

end module fyaml_error

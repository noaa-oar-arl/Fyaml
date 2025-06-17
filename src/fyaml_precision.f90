!> \file fyaml_precision.f90
!! \brief Precision kind parameters for FYAML
!!
!! This module defines the precision kind parameters used throughout
!! the FYAML library for consistent floating-point precision.
!!
!! \author FYAML Development Team
!! \date 2025
!! \version 1.0

module fyaml_precision
    implicit none
    private

    public :: yp

    !> \brief The precision kind-parameter (4-byte real)
    !! Using selected_real_kind for portability
    integer, parameter :: yp = selected_real_kind(6, 37)

end module fyaml_precision

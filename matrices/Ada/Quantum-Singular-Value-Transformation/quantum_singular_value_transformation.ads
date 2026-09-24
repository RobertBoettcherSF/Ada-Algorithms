--  ========================================================================
--  Package: Quantum_Singular_Value_Transformation
--  Description: Comprehensive Ada 2023 implementation of Quantum Singular
--               Value Transformation (QSVT) framework, including block
--               encoding validation, Chebyshev polynomial evaluation,
--               quantum signal processing (QSP) phase simulation, and
--               singular value/eigenvalue transformation variants.
--  ========================================================================

package Quantum_Singular_Value_Transformation is

   -- High-precision floating point type for amplitudes and phase angles
   type Real is digits 12;

   -- Polynomial degree range
   subtype Polynomial_Degree is Natural range 0 .. 64;

   -- Array of polynomial coefficients (from degree 0 upwards)
   type Coefficient_Array is array (Polynomial_Degree range <>) of Real;

   -- Array of phase angles for QSP/QSVT circuit simulation
   type Phase_Array is array (Positive range <>) of Real;

   -- Parity classification for QSVT polynomials
   type Polynomial_Parity is (Odd, Even, Mixed);

   -- 2x2 matrix representation for block encoding validation and demonstrations
   type Matrix_2x2 is array (1 .. 2, 1 .. 2) of Real;

   -- Custom Exceptions
   Invalid_Polynomial_Degree : exception;
   Invalid_Block_Encoding    : exception;
   Invalid_Phase_Sequence    : exception;
   Domain_Error              : exception;

   -- Computes the n-th Chebyshev polynomial of the first kind T_n(x) for x in [-1, 1]
   function Chebyshev_T (N : Natural; X : Real) return Real
     with Pre  => X >= -1.0 and X <= 1.0,
          Post => Chebyshev_T'Result >= -1.0 and Chebyshev_T'Result <= 1.0;

   -- Evaluates a general polynomial given coefficients at point X
   function Evaluate_Polynomial (Coeffs : Coefficient_Array; X : Real) return Real
     with Pre => Coeffs'Length > 0;

   -- Validates whether a 2x2 matrix is a valid block encoding (top-left submatrix norm <= 1.0)
   function Validate_Block_Encoding (Block : Matrix_2x2) return Boolean;

   -- Simulates QSVT polynomial transformation on singular value X respecting polynomial parity
   function Apply_QSVT_Polynomial 
     (X      : Real; 
      Coeffs : Coefficient_Array; 
      Parity : Polynomial_Parity) return Real
     with Pre => X >= -1.0 and X <= 1.0 and Coeffs'Length > 0;

   -- Simulates Quantum Signal Processing (QSP) phase sequence transformation on input X
   function Simulate_Quantum_Signal_Processing 
     (X      : Real; 
      Phases : Phase_Array) return Real
     with Pre => X >= -1.0 and X <= 1.0 and Phases'Length > 0;

   -- Singular Value Transformation variant for singular value sigma in [0, 1]
   function Singular_Value_Transform 
     (Sigma  : Real; 
      Coeffs : Coefficient_Array; 
      Parity : Polynomial_Parity) return Real
     with Pre => Sigma >= 0.0 and Sigma <= 1.0 and Coeffs'Length > 0;

   -- Eigenvalue Transformation variant for Hermitian matrix eigenvalue in [-1, 1]
   function Eigenvalue_Transform 
     (Lambda : Real; 
      Coeffs : Coefficient_Array; 
      Parity : Polynomial_Parity) return Real
     with Pre => Lambda >= -1.0 and Lambda <= 1.0 and Coeffs'Length > 0;

   -- Specialized matrix inversion transform using regularized polynomial approximation
   function Matrix_Inversion_Transform (Sigma : Real; Epsilon : Real) return Real
     with Pre => Sigma >= -1.0 and Sigma <= 1.0 and Epsilon > 0.0;

   -- Simulates projector operations (2*Pi - I) on encoded state value
   function Projector_Project (Val : Real; Is_Controlled : Boolean) return Real
     with Pre => Val >= -1.0 and Val <= 1.0;

end Quantum_Singular_Value_Transformation;

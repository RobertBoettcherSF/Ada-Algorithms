--------------------------------------------------------------------------------
-- Package: Hadamard_Transform
-- Description: Implementation of the Hadamard transform (Walsh-Hadamard transform)
--              in Ada 2023, supporting unnormalized FWHT, normalized FWHT,
--              inverse FWHT, and sequency-ordered FWHT.
--------------------------------------------------------------------------------

package Hadamard_Transform is

   -- Custom types for data domains
   type Element_Float is digits 6;
   type Vector_Float is array (Positive range <>) of Element_Float;

   type Element_Integer is range -100_000_000 .. 100_000_000;
   type Vector_Integer is array (Positive range <>) of Element_Integer;

   -- Named exceptions for error conditions
   Invalid_Length_Exception : exception;
   Null_Input_Exception     : exception;

   -- Checks whether a given natural number is a positive power of two.
   function Is_Power_Of_Two (N : Natural) return Boolean
     with Post   => (if Is_Power_Of_Two'Result then N > 0),
          Global => null;

   -- Computes the unnormalized Fast Walsh-Hadamard Transform (FWHT) for integers.
   -- Input length must be a power of two and greater than zero.
   function Fast_Walsh_Hadamard_Transform (Input : Vector_Integer) return Vector_Integer
     with Pre    => Input'Length > 0 and then Is_Power_Of_Two (Input'Length),
          Post   => Fast_Walsh_Hadamard_Transform'Result'Length = Input'Length,
          Global => null;

   -- Computes the normalized Fast Walsh-Hadamard Transform for floating-point vectors,
   -- scaling output by 1 / sqrt(N).
   function Normalized_FWHT (Input : Vector_Float) return Vector_Float
     with Pre    => Input'Length > 0 and then Is_Power_Of_Two (Input'Length),
          Post   => Normalized_FWHT'Result'Length = Input'Length,
          Global => null;

   -- Computes the inverse Fast Walsh-Hadamard Transform for floating-point vectors.
   function Inverse_FWHT (Input : Vector_Float) return Vector_Float
     with Pre    => Input'Length > 0 and then Is_Power_Of_Two (Input'Length),
          Post   => Inverse_FWHT'Result'Length = Input'Length,
          Global => null;

   -- Computes the sequency-ordered Fast Walsh-Hadamard Transform (Walsh transform)
   -- for integer vectors.
   function Sequency_Ordered_FWHT (Input : Vector_Integer) return Vector_Integer
     with Pre    => Input'Length > 0 and then Is_Power_Of_Two (Input'Length),
          Post   => Sequency_Ordered_FWHT'Result'Length = Input'Length,
          Global => null;

end Hadamard_Transform;

pragma Ada_2022;
package Squares_Of_A_Sorted_Array with SPARK_Mode => On is
   --  the predicate of Sorted_Array rejects bad input; keep it checked without -gnata too
   pragma Assertion_Policy (Dynamic_Predicate => Check);
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -32 .. 32;
   subtype Square_Value is Integer range 0 .. 1024;
   type Int_Array is array (Index) of Value;
   type Square_Array is array (Index) of Square_Value;

   --  The input of the exercise is sorted (non-decreasing): the type says so.
   subtype Sorted_Array is Int_Array
     with Dynamic_Predicate =>
       (for all I in Index => (for all J in I .. Length => Sorted_Array (I) <= Sorted_Array (J)));

   --  The squares of A in non-decreasing order (two pointers from both ends, largest square first).
   function Squares (A : Sorted_Array) return Square_Array
     with Global => null,
          Post   => (for all I in 2 .. Length => Squares'Result (I - 1) <= Squares'Result (I));
end Squares_Of_A_Sorted_Array;

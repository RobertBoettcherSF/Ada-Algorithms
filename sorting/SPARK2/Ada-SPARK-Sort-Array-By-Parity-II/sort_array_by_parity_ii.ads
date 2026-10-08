pragma Ada_2022;
package Sort_Array_By_Parity_II with SPARK_Mode => On is
   --  the predicate of Parity_Balanced rejects bad input; keep it checked without -gnata too
   pragma Assertion_Policy (Dynamic_Predicate => Check);
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 9;
   type Int_Array is array (Index) of Value;

   function Even (V : Value) return Natural is (if V mod 2 = 0 then 1 else 0);
   --  number of even values among A (1 .. N), written out for the 8 positions (no recursion)
   function Evens_Up_To (A : Int_Array; N : Natural) return Natural is
     ((if N >= 1 then Even (A (1)) else 0) + (if N >= 2 then Even (A (2)) else 0)
      + (if N >= 3 then Even (A (3)) else 0) + (if N >= 4 then Even (A (4)) else 0)
      + (if N >= 5 then Even (A (5)) else 0) + (if N >= 6 then Even (A (6)) else 0)
      + (if N >= 7 then Even (A (7)) else 0) + (if N >= 8 then Even (A (8)) else 0))
     with Pre => N <= 8;

   --  The exercise needs as many even as odd values: the input type says so.
   subtype Parity_Balanced is Int_Array with Dynamic_Predicate => Evens_Up_To (Parity_Balanced, 8) = 4;

   --  Odd values go to the odd positions 1, 3, 5, 7 and even values to 2, 4, 6, 8, each in input order.
   procedure Sort_By_Parity (Input : in Parity_Balanced; Output : out Int_Array)
     with Post => (for all K in Index => Output (K) mod 2 = K mod 2);
end Sort_Array_By_Parity_II;

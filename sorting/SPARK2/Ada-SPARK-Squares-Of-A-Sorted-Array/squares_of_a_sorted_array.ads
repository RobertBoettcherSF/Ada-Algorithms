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
   --  How many K in Lo .. Hi have A (K) * A (K) = V
   function Sq_Count (A : Int_Array; Lo, Hi : Integer; V : Square_Value) return Natural
     with Ghost,
          Pre  => Lo in 1 .. Length + 1 and then Hi in Lo - 1 .. Length,
          Post => Sq_Count'Result <= Hi - Lo + 1,
          Subprogram_Variant => (Decreases => Hi);

   --  How many K in Lo .. Hi have R (K) = V
   function Count_Of (R : Square_Array; Lo, Hi : Integer; V : Square_Value) return Natural
     with Ghost,
          Pre  => Lo in 1 .. Length + 1 and then Hi in Lo - 1 .. Length,
          Post => Count_Of'Result <= Hi - Lo + 1,
          Subprogram_Variant => (Decreases => Hi - Lo);

   --  The squares of A in ascending order: sorted, and every value occurs
   --  in the result exactly as often as it is the square of an element of A
   function Squares (A : Sorted_Array) return Square_Array
     with Global => null,
          Post   => (for all I in 2 .. Length => Squares'Result (I - 1) <= Squares'Result (I))
                    and then (for all V in Square_Value =>
                                Count_Of (Squares'Result, 1, Length, V) = Sq_Count (A, 1, Length, V));
private
   function Sq_Count (A : Int_Array; Lo, Hi : Integer; V : Square_Value) return Natural is
     (if Hi < Lo then 0
      else Sq_Count (A, Lo, Hi - 1, V) + (if A (Hi) * A (Hi) = V then 1 else 0));

   function Count_Of (R : Square_Array; Lo, Hi : Integer; V : Square_Value) return Natural is
     (if Hi < Lo then 0
      else (if R (Lo) = V then 1 else 0) + Count_Of (R, Lo + 1, Hi, V));
end Squares_Of_A_Sorted_Array;

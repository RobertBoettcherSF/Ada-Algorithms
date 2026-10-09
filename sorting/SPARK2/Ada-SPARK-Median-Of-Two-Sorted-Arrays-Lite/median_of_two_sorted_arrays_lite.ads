pragma Ada_2022;

--  Median of two sorted arrays of equal length without merging them:
--  binary search for how many of the lower half come from Left.
package Median_Of_Two_Sorted_Arrays_Lite with SPARK_Mode => On is
   Length : constant := 16;
   subtype Index is Positive range 1 .. Length;
   subtype Cut is Natural range 0 .. Length;   --  elements taken from one array
   subtype Value is Integer range 0 .. 100;
   type Input_Array is array (Index) of Value;

   subtype Sorted_Array is Input_Array
     with Dynamic_Predicate =>
       (for all K in 1 .. Length - 1 => Sorted_Array (K) <= Sorted_Array (K + 1));

   --  Elements of A (1 .. I) that are < X, and that are <= X.
   function Count_Lt (A : Input_Array; X : Integer; I : Cut) return Natural
   with Ghost, Post => Count_Lt'Result <= I, Subprogram_Variant => (Decreases => I);
   function Count_Le (A : Input_Array; X : Integer; I : Cut) return Natural
   with Ghost, Post => Count_Le'Result <= I, Subprogram_Variant => (Decreases => I);

   --  Elements of both arrays that are < X, and that are <= X.
   function Below (L, R : Input_Array; X : Integer) return Natural is
     (Count_Lt (L, X, Length) + Count_Lt (R, X, Length))
   with Ghost;
   function Up_To (L, R : Input_Array; X : Integer) return Natural is
     (Count_Le (L, X, Length) + Count_Le (R, X, Length))
   with Ghost;

   --  At most 5 comparisons find the cut (17 possible cuts) and 2 more
   --  pick the two middle values.
   subtype Probe_Count is Natural range 0 .. 7;
   type Median_Result is record
      Lower  : Value;         --  the Length-th smallest of the 2 * Length values
      Upper  : Value;         --  the (Length + 1)-th smallest
      Median : Value;         --  (Lower + Upper) / 2, rounded down
      Probes : Probe_Count;   --  comparisons of two values
   end record;

   --  X is the K-th smallest: fewer than K values are below it and at
   --  least K are <= it.
   function Median (Left : Sorted_Array; Right : Sorted_Array) return Median_Result
   with
     Global => null,
     Post   => Below (Left, Right, Median'Result.Lower) < Length
               and then Length <= Up_To (Left, Right, Median'Result.Lower)
               and then Below (Left, Right, Median'Result.Upper) < Length + 1
               and then Length + 1 <= Up_To (Left, Right, Median'Result.Upper)
               and then Median'Result.Median = (Median'Result.Lower + Median'Result.Upper) / 2;

private
   function Count_Lt (A : Input_Array; X : Integer; I : Cut) return Natural is
     (if I = 0 then 0 else Count_Lt (A, X, I - 1) + (if A (I) < X then 1 else 0));
   function Count_Le (A : Input_Array; X : Integer; I : Cut) return Natural is
     (if I = 0 then 0 else Count_Le (A, X, I - 1) + (if A (I) <= X then 1 else 0));
end Median_Of_Two_Sorted_Arrays_Lite;

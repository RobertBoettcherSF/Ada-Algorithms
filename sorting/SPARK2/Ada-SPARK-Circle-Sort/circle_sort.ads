pragma Ada_2022;

--  Circle sort of 8 values. A pass on Lo .. Hi compares the mirrored pairs
--  (Lo + I, Hi - I), exchanging when out of order (smaller value to the
--  lower index), then recurses on both halves; for 8 values one pass is the
--  12 comparisons of Circle_Pass. Passes repeat until one makes no
--  exchange. Every exchange removes at least one inversion, so there are at
--  most Inversions (Input) + 1 <= 29 passes.
package Circle_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   type Comparator is record
      Lo, Hi : Index;
   end record;
   type Network is array (Positive range <>) of Comparator;

   Pass_Size  : constant := 12;
   Max_Passes : constant := 29;
   Max_Trace  : constant := Pass_Size * Max_Passes;

   --  One pass, in the order the comparisons run.
   Circle_Pass : constant Network (1 .. Pass_Size) :=
     [(1, 8), (2, 7), (3, 6), (4, 5), (1, 4), (2, 3), (1, 2), (3, 4),
      (5, 8), (6, 7), (5, 6), (7, 8)];

   --  Pairs I < J with A (I) > A (J).
   function Inversions (A : Input_Array) return Natural is
       ((if A (1) > A (2) then 1 else 0) +
        (if A (1) > A (3) then 1 else 0) +
        (if A (1) > A (4) then 1 else 0) +
        (if A (1) > A (5) then 1 else 0) +
        (if A (1) > A (6) then 1 else 0) +
        (if A (1) > A (7) then 1 else 0) +
        (if A (1) > A (8) then 1 else 0) +
        (if A (2) > A (3) then 1 else 0) +
        (if A (2) > A (4) then 1 else 0) +
        (if A (2) > A (5) then 1 else 0) +
        (if A (2) > A (6) then 1 else 0) +
        (if A (2) > A (7) then 1 else 0) +
        (if A (2) > A (8) then 1 else 0) +
        (if A (3) > A (4) then 1 else 0) +
        (if A (3) > A (5) then 1 else 0) +
        (if A (3) > A (6) then 1 else 0) +
        (if A (3) > A (7) then 1 else 0) +
        (if A (3) > A (8) then 1 else 0) +
        (if A (4) > A (5) then 1 else 0) +
        (if A (4) > A (6) then 1 else 0) +
        (if A (4) > A (7) then 1 else 0) +
        (if A (4) > A (8) then 1 else 0) +
        (if A (5) > A (6) then 1 else 0) +
        (if A (5) > A (7) then 1 else 0) +
        (if A (5) > A (8) then 1 else 0) +
        (if A (6) > A (7) then 1 else 0) +
        (if A (6) > A (8) then 1 else 0) +
        (if A (7) > A (8) then 1 else 0))
   with Global => null, Post => Inversions'Result <= 28;

   --  How many of A (1 .. Last) equal V.
   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural
   with Global             => null,
        Pre                => Last <= Index'Last,
        Post               => Occ'Result <= Last,
        Subprogram_Variant => (Decreases => Last);

   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural is
     (if Last = 0 then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   --  A and B hold the same values, each equally often (Value has 32
   --  elements, so this is cheap to check at run time).
   function Is_Perm (A, B : Input_Array) return Boolean is
     (for all V in Value => Occ (A, V, Index'Last) = Occ (B, V, Index'Last))
   with Global => null;

   function Is_Sorted (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1))
   with Global => null;

   --  Sort, also returning the comparisons in the order they ran
   --  (Trace (1 .. Length), pass after pass) and the number of passes.
   procedure Sort_Traced
     (Input  : Input_Array; Output : out Input_Array; Trace : out Network;
      Length : out Natural; Passes : out Natural)
     with Global => null,
          Pre    => Trace'First = 1 and then Trace'Last = Max_Trace,
          Post   => Is_Sorted (Output) and then Is_Perm (Output, Input)
                    and then Passes in 1 .. Inversions (Input) + 1
                    and then Length = Pass_Size * Passes
                    and then (for all P in 0 .. Passes - 1 =>
                                (for all J in 1 .. Pass_Size =>
                                   Trace (Pass_Size * P + J) = Circle_Pass (J)));

   function Sort (Input : Input_Array) return Input_Array
     with Global => null,
          Post   => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input);
end Circle_Sort;

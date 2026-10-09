pragma Ada_2022;

--  Bitonic sort (Batcher) of 8 values: the 24-comparator bitonic network.
--  Blocks of 2, then 4, then 8 are sorted; each step first compares the
--  two halves of a block mirror-wise (B + I with B + K - 1 - I), then the
--  half-cleaners (I with I + J for J = K / 4, .., 1). Every comparator puts
--  the smaller value at the lower index.
package Bitonic_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   Network_Size : constant := 24;
   type Comparator is record
      Lo, Hi : Index;
   end record;
   type Network is array (Positive range <>) of Comparator;

   --  The network, in the order the comparators run.
   Bitonic_Network : constant Network (1 .. Network_Size) :=
     [(1, 2), (3, 4), (5, 6), (7, 8),
      (1, 4), (2, 3), (5, 8), (6, 7), (1, 2), (3, 4), (5, 6), (7, 8),
      (1, 8), (2, 7), (3, 6), (4, 5), (1, 3), (2, 4), (5, 7), (6, 8),
      (1, 2), (3, 4), (5, 6), (7, 8)];

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

   --  Sort, also returning the comparators in the order they ran.
   procedure Sort_Traced
     (Input : Input_Array; Output : out Input_Array; Trace : out Network)
     with Global => null,
          Pre    => Trace'First = 1 and then Trace'Last = Network_Size,
          Post   => Is_Sorted (Output) and then Is_Perm (Output, Input)
                    and then (for all K in Trace'Range => Trace (K) = Bitonic_Network (K));

   function Sort (Input : Input_Array) return Input_Array
     with Global => null,
          Post   => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input);
end Bitonic_Sort;

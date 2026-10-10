pragma Ada_2022;

--  Timsort of 8 values, as CPython's listsort does it for n < 64 (see
--  Objects/listsort.txt): the min-run is then n itself, so the sort is one
--  run: count_run finds the longest ascending (A (K) <= A (K + 1)) or
--  strictly descending start, a descending start is reversed in place
--  (strictness keeps this stable), and binarysort inserts the remaining
--  values one by one at the place found by binary search after any equal
--  keys (bisect right, stable). No merge happens at this size.
package Tim_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   type Comparator is record
      Lo, Hi : Index;
   end record;
   type Network is array (Positive range <>) of Comparator;

   Max_Trace : constant := 64;

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

   --  Sort, also returning the comparisons in the order they ran (as
   --  position pairs: (R, R + 1) while counting the run, (Mid, I) for each
   --  binary-search probe), the first run's length and whether it was
   --  reversed.
   procedure Sort_Traced
     (Input  : Input_Array; Output : out Input_Array; Trace : out Network;
      Length : out Natural; Run : out Natural; Reversed : out Boolean)
     with Global => null,
          Pre    => Trace'First = 1 and then Trace'Last = Max_Trace,
          Post   => Is_Sorted (Output) and then Is_Perm (Output, Input)
                    and then Length in 1 .. Max_Trace and then Trace (1) = (1, 2) and then Run in 2 .. Index'Last
                    and then Reversed = (Input (2) < Input (1))
                    and then (if Reversed
                              then (for all K in 1 .. Run - 1 => Input (K + 1) < Input (K))
                              else (for all K in 1 .. Run - 1 => Input (K) <= Input (K + 1)));

   function Sort (Input : Input_Array) return Input_Array
     with Global => null,
          Post   => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input);
end Tim_Sort;

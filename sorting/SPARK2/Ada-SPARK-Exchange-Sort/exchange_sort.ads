--  PLACEHOLDER: the README calls this a stub / bounded kernel, not a full Exchange-Sort implementation; see tools/readme_stubs.txt
pragma Ada_2022;

--  Exchange sort on a bounded array: for each position I, compare A (I)
--  with every later A (J) and exchange them when A (I) > A (J). After
--  position I is done it holds the smallest value of A (I .. 8).
--  Reference: https://en.wikipedia.org/wiki/Sorting_algorithm#Exchange_sort
package Exchange_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 31;
   type Input_Array is array (Index) of Value;

   --  How many of A (1 .. Last) equal V.
   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural
   with Global             => null,
        Pre                => Last <= Index'Last,
        Post               => Occ'Result <= Last,
        Subprogram_Variant => (Decreases => Last);

   function Occ (A : Input_Array; V : Value; Last : Natural) return Natural is
     (if Last = 0 then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   --  A and B hold the same values, each equally often. Value has 32
   --  elements, so this is also cheap to check at run time.
   function Is_Perm (A, B : Input_Array) return Boolean is
     (for all V in Value => Occ (A, V, Index'Last) = Occ (B, V, Index'Last))
   with Global => null;

   function Is_Sorted (A : Input_Array) return Boolean is
     (for all I in Index'First .. Index'Last - 1 => A (I) <= A (I + 1))
   with Global => null;

   function Sort (Input : Input_Array) return Input_Array
     with Global => null,
          Post   => Is_Sorted (Sort'Result) and then Is_Perm (Sort'Result, Input);
end Exchange_Sort;

--  Radix_Sort: Ada/SPARK Level 4 LSD (least-significant-digit) radix sort
--  of up to Max_N keys in 0 .. 255, in base 16: two digit passes, the low
--  digit first, then the high digit. Each pass is a stable distribution by
--  its digit (equal digits keep their order from the previous pass), which
--  is what makes the second pass finish the sort.
--
--  SPARK port of Ada-Radix-Sort: hard Max_N bound, keys capped to
--  0 .. Max_Key, no exceptions; In_Bounds / Is_Sorted / Is_Perm contracts.
--  The non-SPARK sibling allows arbitrary nonnegative Integer keys and a
--  chosen base 2 .. 256.
--
--  Reference: https://en.wikipedia.org/wiki/Radix_sort (LSD); Knuth,
--  TAOCP vol. 3, 5.2.5.

package Radix_Sort
  with SPARK_Mode => On
is
   --  Hard bound on array length (static buffers, Level 4 proof).
   Max_N : constant Positive := 64;

   --  Keys are two base-16 digits.
   Max_Key    : constant Natural := 255;
   Digit_Base : constant Positive := 16;
   Pass_Count : constant Positive := 2;

   subtype Index is Natural range 0 .. Max_N;
   subtype Element is Natural range 0 .. Max_Key;
   subtype Live_Index is Positive range 1 .. Max_N;
   type Element_Array is array (Live_Index range <>) of Element;

   subtype Pass_Index is Positive range 1 .. Pass_Count;
   subtype Digit is Natural range 0 .. Digit_Base - 1;

   --  Digit P of a key: P = 1 the low digit, P = 2 the high digit.
   function Digit_Of (Key : Element; P : Pass_Index) return Digit is
     (if P = 1 then Key mod Digit_Base else Key / Digit_Base)
   with Global => null;

   --  Src (J): the position in the pass input that B (J) came from.
   type Source_Map is array (Live_Index range <>) of Live_Index;

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N
      and then A'First in 1 .. Max_N
      and then A'Last in 0 .. Max_N)
   with Global => null;

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               =>
       Occ'Result <= Last
       and then (if Last < A'First then Occ'Result = 0
                 else Occ'Result <= Last - A'First + 1),
     Subprogram_Variant => (Decreases => Last);
   --  How many of A (A'First .. Last) equal V.

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural is
     (if Last < A'First then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'Last) = Occ (B, A (I), B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'Last) = Occ (B, B (I), B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);

   --  One LSD pass: B is A stably distributed by digit P (all keys with
   --  digit 0 in their order in A, then digit 1, ..). Post: B (J) =
   --  A (Src (J)); digits are nondecreasing along B; equal digits keep
   --  the order of their sources (stability); same keys, equally often.
   procedure Pass
     (A : Element_Array; P : Pass_Index; B : out Element_Array; Src : out Source_Map)
     with
       Global => null,
       Pre    => In_Bounds (A) and then B'First = A'First and then B'Last = A'Last
                 and then Src'First = A'First and then Src'Last = A'Last,
       Post   =>
         (for all J in B'Range => Src (J) in A'Range and then B (J) = A (Src (J)))
         and then (for all J1 in B'Range =>
                     (for all J2 in J1 + 1 .. B'Last =>
                        Digit_Of (B (J1), P) <= Digit_Of (B (J2), P)
                        and then (if Digit_Of (B (J1), P) = Digit_Of (B (J2), P)
                                  then Src (J1) < Src (J2))))
         and then (for all V in Element => Occ (B, V, B'Last) = Occ (A, V, A'Last));

   --  LSD radix sort: Pass 1 (low digit), then Pass 2 (high digit).
   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   =>
         In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);

end Radix_Sort;

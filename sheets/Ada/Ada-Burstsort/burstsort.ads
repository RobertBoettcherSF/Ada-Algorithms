--  Burstsort — Ada 2023 educational package for Wikipedia "Burstsort".
--  Cache-friendly radix / trie hybrid for sorting strings: a burst trie
--  stores shared prefixes in trie nodes and unsorted suffixes in buckets;
--  when a bucket exceeds Burst_Threshold it is "burst" into a child trie
--  node. Small buckets are finished with insertion sort.
--  Reference: https://en.wikipedia.org/wiki/Burstsort

pragma Ada_2022;

package Burstsort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Educational capacity bounds
   ---------------------------------------------------------------------------

   --  Maximum number of strings accepted by Sort.
   Max_N : constant Positive := 256;

   --  Maximum character length of any single string.
   Max_String_Len : constant Positive := 64;

   --  Bucket size that triggers a burst into a child trie node.
   --  Kept small so educational demos burst often.
   Burst_Threshold : constant Positive := 8;

   --  Full Latin-1 / 8-bit Character alphabet.
   Alphabet_Size : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Bounded_String is record
      Length : Natural range 0 .. Max_String_Len := 0;
      Data   : String (1 .. Max_String_Len) := [others => ' '];
   end record;

   type String_Array is array (Positive range <>) of Bounded_String;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N, or when Make receives a String longer
   --  than Max_String_Len.

   ---------------------------------------------------------------------------
   -- Construction / conversion / ordering
   ---------------------------------------------------------------------------

   function Make (S : String) return Bounded_String;
   --  Copy S into a Bounded_String. Raises Invalid_Argument when
   --  S'Length > Max_String_Len.

   function To_String (B : Bounded_String) return String;
   --  Return B.Data (1 .. B.Length).

   function "<"  (Left, Right : Bounded_String) return Boolean;
   function "<=" (Left, Right : Bounded_String) return Boolean;
   --  Lexicographic order on the significant prefixes (Ada String rules:
   --  after a common prefix the shorter string is smaller).

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out String_Array);
   --  Lexicographic ascending burstsort.
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.
   --  Asymptotically O(w n) like MSD radix sort (w = Max_String_Len);
   --  the burst trie improves cache locality on common real-world strings.

   function Is_Sorted (A : String_Array) return Boolean;
   --  True iff A is nondecreasing under "<=". Empty / singleton => True.

end Burstsort;

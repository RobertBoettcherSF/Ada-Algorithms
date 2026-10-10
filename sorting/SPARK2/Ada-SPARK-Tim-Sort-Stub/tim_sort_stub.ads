pragma Ada_2022;

--  Timsort (CPython's listsort, Objects/listsort.txt) of up to Max_Len
--  values with any Positive index range, without galloping. Runs are the
--  longest ascending (A (K) <= A (K + 1)) or strictly descending stretch
--  (reversed in place), extended to Min_Run (N) by binary insertion and
--  pushed on a run stack; after each push merge_collapse merges adjacent
--  runs until the stack lengths satisfy the Timsort invariants (with the
--  corrected check of the third run from the top); at the end the stack
--  is merged down to one run. A merge copies the left run to a buffer and
--  merges forward (merge_lo). Galloping (exponential search inside a
--  merge) is an optimisation of how a merge copies and is not done here.
package Tim_Sort_Stub with SPARK_Mode => On is
   Max_Len : constant := 10_000;
   subtype Value is Integer;
   type Value_Array is array (Positive range <>) of Value;

   --  Pairwise form: every earlier element is <= every later one.
   function Sorted (A : Value_Array; Lo, Hi : Integer) return Boolean is
     (for all I in Lo .. Hi =>
        (for all J in I .. Hi => A (I) <= A (J)))
   with Ghost,
        Pre => (if Lo <= Hi then Lo in A'Range and then Hi in A'Range);

   --  How many of A (First .. Last) equal V (0 for an empty range).
   function Occ (A : Value_Array; V : Value; First, Last : Integer) return Natural
     with Global             => null,
          Pre                => (if First <= Last then First >= A'First and then Last <= A'Last),
          Post               => Occ'Result <= (if First <= Last then Last - First + 1 else 0),
          Subprogram_Variant => (Decreases => Last);

   function Occ (A : Value_Array; V : Value; First, Last : Integer) return Natural is
     (if Last < First then 0
      else Occ (A, V, First, Last - 1) + (if A (Last) = V then 1 else 0));

   --  A and B have the same bounds and hold the same values, each equally
   --  often. A value found in neither array counts 0 in both, so comparing
   --  the counts of the values of A and of B covers every value.
   function Is_Perm (A, B : Value_Array) return Boolean is
     (A'First = B'First and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'First, A'Last) = Occ (B, A (I), B'First, B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'First, A'Last) = Occ (B, B (I), B'First, B'Last)))
   with Global => null;

   --  listsort's min-run: the six most significant bits of N, plus 1 if
   --  any of the remaining bits is set (N itself below 64).
   function Min_Run (N : Natural) return Natural
     with Global => null,
          Post   => (if N < 64 then Min_Run'Result = N else Min_Run'Result in 32 .. 64);

   --  Run lengths on a run stack, bottom first.
   type Length_Array is array (Positive range <>) of Natural;

   --  Timsort's run-length rule over the WHOLE stack L (L'First .. Top):
   --  every run is longer than the next one, and longer than the next two
   --  together (listsort.txt; de Gouw et al. 2015 showed that checking
   --  only the top three runs lets the rule break further down).
   function Runs_Rule (L : Length_Array; Top : Integer) return Boolean is
     (for all X in L'First .. Top =>
        (if X < Top then L (X) > L (X + 1))
        and then (if X < Top - 1 then L (X) - L (X + 1) > L (X + 2)))
   with Global => null,
        Pre    => Top <= L'Last;

   type Event_Kind is (Push, Merge);
   --  Push: a run (A = base, B = length); Merge: stack runs A and A + 1.
   type Event is record
      Kind : Event_Kind;
      A, B : Natural;
   end record;
   type Event_Log is array (Positive range <>) of Event;

   procedure Sort_Traced
     (Input : Value_Array; Output : out Value_Array; Log : out Event_Log; Count : out Natural)
     with Global => null,
          Pre    => Input'Length <= Max_Len and then Input'Last < Positive'Last
                    and then Output'First = Input'First and then Output'Last = Input'Last
                    and then Log'First = 1 and then Log'Last >= 2 * Input'Length + 1,
          Post   => Count <= 2 * Input'Length and then Sorted (Output, Output'First, Output'Last)
                    and then Is_Perm (Output, Input)
                    and then (if Input'Length > 0
                              then Count >= 1 and then Log (1).Kind = Push and then Log (1).A = Input'First);

   function Sort (Input : Value_Array) return Value_Array
     with Global => null,
          Pre    => Input'Length <= Max_Len
                    and then Input'Last < Positive'Last,
          Post   => Sort'Result'First = Input'First
                    and then Sort'Result'Last = Input'Last
                    and then Sorted (Sort'Result, Sort'Result'First,
                                     Sort'Result'Last)
                    and then Is_Perm (Sort'Result, Input);
end Tim_Sort_Stub;

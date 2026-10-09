--  PLACEHOLDER: insertion sort under a Timsort name (no runs, no merging); the Post states sortedness only; see H109
pragma Ada_2022;

--  Insertion-sort kernel of Timsort (the step Timsort uses inside each
--  min-run), generalised from the old fixed 8-element stub to any array
--  of up to Max_Len values with any Positive index range.
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

   function Sort (Input : Value_Array) return Value_Array
     with Global => null,
          Pre    => Input'Length <= Max_Len
                    and then Input'Last < Positive'Last,
          Post   => Sort'Result'First = Input'First
                    and then Sort'Result'Last = Input'Last
                    and then Sorted (Sort'Result, Sort'Result'First,
                                     Sort'Result'Last);
end Tim_Sort_Stub;

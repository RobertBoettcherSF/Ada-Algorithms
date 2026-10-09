pragma Ada_2022;

package Longest_Repeating_Character_Replacement with SPARK_Mode => On is
   Max_Length : constant := 1_000_000;
   subtype Index is Positive range 1 .. Max_Length;
   subtype Result is Natural range 0 .. Max_Length;
   type Text_Array is array (Index range <>) of Character;

   --  Occurrences of C in A (Lo .. Hi)
   function Occ (A : Text_Array; Lo, Hi : Integer; C : Character) return Natural
     with Ghost,
          Pre  => Lo in A'Range and then Hi in Lo - 1 .. A'Last,
          Post => Occ'Result <= Hi - Lo + 1,
          Subprogram_Variant => (Decreases => Hi);

   --  The window A (S .. S + L - 1) becomes a run of one character after
   --  at most K replacements: some character of the window fills all but
   --  at most K of its places.
   function Fixable (A : Text_Array; S : Index; L : Positive; K : Result) return Boolean is
     (for some P in S .. S + L - 1 => L - Occ (A, S, S + L - 1, A (P)) <= K)
     with Ghost,
          Pre => S in A'Range and then L <= A'Last - S + 1;

   --  Length of the longest window of Input that can be made a run of one
   --  character by replacing at most K of its characters: some window of
   --  that length is fixable and no window one longer is. Fixability is
   --  downward closed (dropping one end character lowers the length by 1
   --  and any count by at most 1), so no longer window is fixable either.
   function Longest (Input : Text_Array; K : Result) return Result
     with Global => null,
          Post   =>
            (if Input'Length = 0 then Longest'Result = 0
             else Longest'Result in 1 .. Input'Length
               and then (for some S in Input'First .. Input'Last - Longest'Result + 1 =>
                           Fixable (Input, S, Longest'Result, K))
               and then (Longest'Result = Input'Length
                         or else (for all S in Input'First .. Input'Last - Longest'Result =>
                                    not Fixable (Input, S, Longest'Result + 1, K))));
private
   function Occ (A : Text_Array; Lo, Hi : Integer; C : Character) return Natural is
     (if Hi < Lo then 0 else Occ (A, Lo, Hi - 1, C) + (if A (Hi) = C then 1 else 0));
end Longest_Repeating_Character_Replacement;

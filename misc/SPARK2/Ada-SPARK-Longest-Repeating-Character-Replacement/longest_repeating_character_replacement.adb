pragma Ada_2022;
--  The ghost occurrence counts and the loop invariants/assertions that use
--  them are proved by gnatprove; executing them would make each call
--  O(n * n * 256), so they are not evaluated at run time.
pragma Assertion_Policy (Ghost => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

package body Longest_Repeating_Character_Replacement with SPARK_Mode => On is

   --  Occurrences of C in A (Lo .. Hi)
   function Occ (A : Text_Array; Lo, Hi : Integer; C : Character) return Natural is
     (if Hi < Lo then 0 else Occ (A, Lo, Hi - 1, C) + (if A (Hi) = C then 1 else 0))
     with Ghost,
          Pre  => Lo in A'Range and then Hi in Lo - 1 .. A'Last,
          Post => Occ'Result <= Hi - Lo + 1,
          Subprogram_Variant => (Decreases => Hi);

   --  Occ can also be split at the low end
   procedure Occ_Left (A : Text_Array; Lo, Hi : Integer)
     with Ghost,
          Pre  => Lo in A'Range and then Hi in Lo .. A'Last,
          Post => (if Lo < A'Last then
                     (for all C in Character =>
                        Occ (A, Lo, Hi, C) = (if A (Lo) = C then 1 else 0) + Occ (A, Lo + 1, Hi, C))),
          Subprogram_Variant => (Decreases => Hi - Lo)
   is
   begin
      if Lo < Hi then
         Occ_Left (A, Lo, Hi - 1);
      end if;
   end Occ_Left;

   --  Sliding window Input (Left .. Right) with per-character counts.
   --  Most is the highest count any character has reached in a window so
   --  far. The window only grows while length - Most <= K; otherwise it
   --  slides one place (Left and Right both advance), so its length never
   --  shrinks and at the end equals the best length found. Most may be
   --  stale (above the current window's maximum), but a longer answer
   --  needs a count above Most, so a stale Most never hides one.
   function Longest (Input : Text_Array; K : Result) return Result is
      type Count_Array is array (Character) of Natural;
      Count : Count_Array := [others => 0];
      Most  : Natural := 0;
      Left  : Integer := Input'First;
   begin
      if Input'Length = 0 then
         return 0;
      end if;
      for Right in Input'Range loop
         pragma Loop_Invariant (Left in Input'First .. Right);
         pragma Loop_Invariant (Most <= Right - Left);
         pragma Loop_Invariant
           (for all C in Character => Count (C) = Occ (Input, Left, Right - 1, C));
         pragma Loop_Invariant
           (Right - Left >= Natural'Min (Right - Input'First, K + 1));
         Count (Input (Right)) := Count (Input (Right)) + 1;
         pragma Assert
           (for all C in Character => Count (C) = Occ (Input, Left, Right, C));
         Most := Natural'Max (Most, Count (Input (Right)));
         if Right - Left + 1 - Most > K then
            Occ_Left (Input, Left, Right);
            Count (Input (Left)) := Count (Input (Left)) - 1;
            Left := Left + 1;
         end if;
      end loop;
      return Input'Last - Left + 1;
   end Longest;
end Longest_Repeating_Character_Replacement;

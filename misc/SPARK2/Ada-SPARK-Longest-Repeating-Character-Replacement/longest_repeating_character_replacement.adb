pragma Ada_2022;
--  The loop invariants, assertions and the lemmas' Pre/Post in this body
--  are proved by gnatprove; checking them would make each call
--  O(n * n * 256), so they are not evaluated at run time. (Ghost code
--  still runs under -gnata: the witness updates and the lemma calls, at
--  most O(n * n) cheap steps.) The functional Post of Longest, declared in
--  the spec, is still checked on every call.

package body Longest_Repeating_Character_Replacement with SPARK_Mode => On is
   pragma Assertion_Policy
     (Pre => Ignore, Post => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

   --  Some character fills all but at most K places of A (S .. S + L - 1)
   --  (Fixable restricted to characters of the window is the same thing,
   --  see the final assertions in Longest)
   function Fixable_Any (A : Text_Array; S : Index; L : Natural; K : Result) return Boolean is
     (for some C in Character => L - Occ (A, S, S + L - 1, C) <= K)
     with Ghost,
          Pre => S in A'Range and then L <= A'Last - S + 1;

   --  No window of length L starting before Left is fixable
   function None_Before (A : Text_Array; Left : Index; L : Positive; K : Result) return Boolean is
     (Left = A'First
      or else (for all S in A'First .. Left - 1 => not Fixable_Any (A, S, L, K)))
     with Ghost,
          Pre => Left in A'Range and then L <= A'Last - Left + 2;

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

   --  Downward closure: a window that is not fixable stays not fixable
   --  when it is extended by one place (its length grows by 1, any count
   --  by at most 1). Contrapositive: dropping the last character of a
   --  fixable window leaves a fixable window.
   procedure Lemma_Down (A : Text_Array; S : Index; L : Result; K : Result)
     with Ghost,
          Pre  => S in A'Range and then L + 1 <= A'Last - S + 1,
          Post => (if not Fixable_Any (A, S, L, K) then not Fixable_Any (A, S, L + 1, K))
   is
   begin
      pragma Assert
        (for all C in Character =>
           Occ (A, S, S + L, C) <= Occ (A, S, S + L - 1, C) + 1);
   end Lemma_Down;

   --  A window fixable by one of its own characters is fixable
   procedure Lemma_Any (A : Text_Array; S : Index; L : Positive; K : Result)
     with Ghost,
          Pre  => S in A'Range and then L <= A'Last - S + 1,
          Post => (if Fixable (A, S, L, K) then Fixable_Any (A, S, L, K))
   is
   begin
      pragma Assert
        (for all P in S .. S + L - 1 =>
           (if L - Occ (A, S, S + L - 1, A (P)) <= K then Fixable_Any (A, S, L, K)));
   end Lemma_Any;

   --  Sliding window Input (Left .. Right) with per-character counts.
   --  Most is the highest count any character has reached in a window so
   --  far. The window only grows while length - Most <= K; otherwise it
   --  slides one place (Left and Right both advance), so its length never
   --  shrinks and at the end equals the best length found. Most may be
   --  stale (above the current window's maximum), but every current count
   --  is <= Most, so a window one longer than the current one, whose
   --  length - count would be <= K, is never missed; and some earlier
   --  window of the current length does reach Most (ghost Wit_S, Wit_P).
   function Longest (Input : Text_Array; K : Result) return Result is
      type Count_Array is array (Character) of Natural;
      Count : Count_Array := [others => 0];
      Most  : Natural := 0;
      Left  : Integer := Input'First;
      Wit_S : Integer := Input'First with Ghost;  --  window of the current
      Wit_P : Integer := Input'First with Ghost;  --  length where Input (Wit_P)
                                                  --  occurs >= Most times
   begin
      if Input'Length = 0 then
         return 0;
      end if;
      for Right in Input'Range loop
         declare
            Old_Most : constant Natural := Most with Ghost;
            Old_Len  : constant Natural := Right - Left with Ghost;  --  window Left .. Right - 1
         begin
            Count (Input (Right)) := Count (Input (Right)) + 1;
            pragma Assert
              (for all C in Character => Count (C) = Occ (Input, Left, Right, C));
            if Count (Input (Right)) > Most then
               Most := Count (Input (Right));
               Wit_S := Left;
               Wit_P := Right;
               pragma Assert (Most = Old_Most + 1);
               pragma Assert (Most <= Occ (Input, Wit_S, Right, Input (Wit_P)));
            end if;
            if Right - Left + 1 - Most > K then
               --  The window Input (Left .. Right) is one longer than the
               --  best so far and not fixable (every count <= Most); slide
               pragma Assert (Most = Old_Most);
               pragma Assert
                 (for all C in Character => Occ (Input, Left, Right, C) <= Most);
               pragma Assert (not Fixable_Any (Input, Left, Old_Len + 1, K));
               Occ_Left (Input, Left, Right);
               Count (Input (Left)) := Count (Input (Left)) - 1;
               Left := Left + 1;
               pragma Assert
                 (for all S in Input'First .. Left - 1 =>
                    not Fixable_Any (Input, S, Old_Len + 1, K));
               pragma Assert (Right - Left + 2 = Old_Len + 1);
               pragma Assert (None_Before (Input, Left, Right - Left + 2, K));
            else
               --  Grow: a window one longer than the new length starting
               --  before Left extends a window of the old length plus one,
               --  none of which is fixable (downward closure)
               pragma Assert
                 (if Most = Old_Most then
                    Occ (Input, Wit_S, Wit_S + Old_Len, Input (Wit_P))
                    >= Occ (Input, Wit_S, Wit_S + Old_Len - 1, Input (Wit_P)));
               for S in Input'First .. Left - 1 loop
                  Lemma_Down (Input, S, Old_Len + 1, K);
                  pragma Loop_Invariant
                    (for all T in Input'First .. S =>
                       not Fixable_Any (Input, T, Old_Len + 2, K));
               end loop;
               pragma Assert (Right - Left + 2 = Old_Len + 2);
               pragma Assert (None_Before (Input, Left, Right - Left + 2, K));
            end if;
         end;
                  pragma Loop_Invariant (Left in Input'First .. Right);
         pragma Loop_Invariant (Most <= Right - Left + 1);
         pragma Loop_Invariant
           (for all C in Character => Count (C) = Occ (Input, Left, Right, C));
         pragma Loop_Invariant (for all C in Character => Count (C) <= Most);
         pragma Loop_Invariant (Right - Left + 1 - Most <= K);
         pragma Loop_Invariant
           (Wit_S in Input'First .. Left
            and then Wit_P in Wit_S .. Wit_S + (Right - Left)
            and then Most <= Occ (Input, Wit_S, Wit_S + (Right - Left), Input (Wit_P)));
         pragma Loop_Invariant (None_Before (Input, Left, Right - Left + 2, K));
      end loop;
      pragma Assert (Fixable (Input, Wit_S, Input'Last - Left + 1, K));
      if Left > Input'First then
         for S in Input'First .. Left - 1 loop
            Lemma_Any (Input, S, Input'Last - Left + 2, K);
            pragma Loop_Invariant
              (for all T in Input'First .. S =>
                 not Fixable (Input, T, Input'Last - Left + 2, K));
         end loop;
      end if;
      return Input'Last - Left + 1;
   end Longest;
end Longest_Repeating_Character_Replacement;

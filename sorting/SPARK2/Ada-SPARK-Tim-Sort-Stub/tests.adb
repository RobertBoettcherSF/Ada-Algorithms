pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Tim_Sort_Stub; use Tim_Sort_Stub;
with Own_Checks;
procedure Tests is
   Failures : Natural := 0;

   procedure Check (Ok : Boolean; Name : String) is
   begin
      if Ok then
         Put_Line ("PASS " & Name);
      else
         Put_Line ("FAIL " & Name);
         Failures := Failures + 1;
      end if;
   end Check;

   function Is_Sorted (A : Value_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1));

   function Count (A : Value_Array; X : Value) return Natural is
      N : Natural := 0;
   begin
      for Y of A loop
         if Y = X then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count;

   --  Same multiset: every value occurs equally often in both arrays.
   function Same_Values (A, B : Value_Array) return Boolean is
     (A'Length = B'Length
      and then (for all X of A => Count (A, X) = Count (B, X)));

   procedure Case_Of (Input : Value_Array; Name : String) is
      Result : constant Value_Array := Sort (Input);
   begin
      Check (Result'First = Input'First and then Result'Last = Input'Last
             and then Is_Sorted (Result) and then Same_Values (Input, Result),
             Name);
   end Case_Of;

   --  Sorted-copy reference: insertion sort of a copy.
   function Ref_Sort (A : Value_Array) return Value_Array is
      R : Value_Array := A;
      T : Value;
      J : Integer;
   begin
      for I in R'First + 1 .. R'Last loop
         T := R (I);
         J := I - 1;
         while J >= R'First and then R (J) > T loop
            R (J + 1) := R (J);
            J := J - 1;
         end loop;
         R (J + 1) := T;
      end loop;
      return R;
   end Ref_Sort;

   --  Permutation by sorted copies (independent of Occ / Is_Perm).
   function Is_Permutation (A, B : Value_Array) return Boolean is
     (A'First = B'First and then A'Last = B'Last and then Ref_Sort (A) = Ref_Sort (B));

   --  LCG for the permutation checks (seed 20261009).
   P_Seed : Long_Long_Integer := 20_261_009;
   function P_Next (M : Positive) return Natural is
   begin
      P_Seed := (P_Seed * 1_103_515_245 + 12_345) mod 2_147_483_648;
      return Natural ((P_Seed / 65_536) mod Long_Long_Integer (M));
   end P_Next;

   procedure Perm_Checks is
      Bad   : Natural := 0;
      Cases : Natural := 0;
      procedure Run (Src : Value_Array) is
         R : constant Value_Array := Sort (Src);
      begin
         Cases := Cases + 1;
         if not (Is_Perm (R, Src) and then R = Ref_Sort (Src)) then
            Bad := Bad + 1;
         end if;
      end Run;
   begin
      --  Is_Perm (Post) against sorted copies: every pair of arrays of
      --  length 0 .. 4 over -1 .. 1.
      for Len in 0 .. 4 loop
         for CA in 0 .. 3 ** Len - 1 loop
            for CB in 0 .. 3 ** Len - 1 loop
               declare
                  A, B : Value_Array (1 .. Len);
                  X    : Natural := CA;
                  Y    : Natural := CB;
               begin
                  for I in A'Range loop
                     A (I) := X mod 3 - 1;
                     B (I) := Y mod 3 - 1;
                     X := X / 3;
                     Y := Y / 3;
                  end loop;
                  Cases := Cases + 1;
                  if Is_Perm (A, B) /= Is_Permutation (A, B) then
                     Bad := Bad + 1;
                  end if;
               end;
            end loop;
         end loop;
      end loop;
      Check (Bad = 0 and then Cases = 7_381,
             "Is_Perm = sorted-copy comparison on" & Cases'Image & " pairs");
      Check (not Is_Perm (Value_Array'([3, 1, 2]), Value_Array'([0, 0, 0])),
             "Is_Perm rejects an all-zeros result");
      Check (not Is_Perm (Value_Array'([1, 1, 2]), Value_Array'([1, 2, 2])),
             "Is_Perm compares counts, not just values");
      Check (not Is_Perm (Value_Array'([1, 2, 3]), Value_Array'([1, 1, 1])),
             "Is_Perm rejects the all-first trivial body");
      Check (Occ (Value_Array'([2, 5, 2, 2]), 2, 1, 4) = 3
             and then Occ (Value_Array'([2, 5, 2, 2]), 2, 2, 3) = 1
             and then Occ (Value_Array'([2, 5, 2, 2]), 7, 1, 4) = 0
             and then Occ (Value_Array'([2, 5, 2, 2]), 2, 3, 2) = 0,
             "Occ counts A (First .. Last)");
      --  Sort result: Is_Perm (Result, Input) and = reference on every
      --  array of length 0 .. 6 over -1 .. 1 at origins 1 and 7, and
      --  2,000 random arrays (lengths 0 .. 300, seed 20261009).
      Bad := 0;
      Cases := 0;
      for O in 0 .. 1 loop
         for Len in 0 .. 6 loop
            for C in 0 .. 3 ** Len - 1 loop
               declare
                  A : Value_Array (1 + 6 * O .. 6 * O + Len);
                  X : Natural := C;
               begin
                  for I in A'Range loop
                     A (I) := X mod 3 - 1;
                     X := X / 3;
                  end loop;
                  Run (A);
               end;
            end loop;
         end loop;
      end loop;
      for K in 1 .. 2_000 loop
         declare
            Len : constant Natural := P_Next (301);
            A   : Value_Array (1 .. Len);
         begin
            for I in A'Range loop
               A (I) := (if K mod 2 = 0 then P_Next (11) - 5 else P_Next (2_000_001) - 1_000_000);
            end loop;
            Run (A);
         end;
      end loop;
      Check (Bad = 0 and then Cases = 2 * 1_093 + 2_000,
             "Sort result Is_Perm of input and = reference on" & Cases'Image & " arrays");
   end Perm_Checks;

   --  H174: the Timsort run-length rule over the WHOLE stack after every
   --  merge_collapse, replayed from the Sort_Traced event log.
   procedure Stack_Rule_Checks is
      type Nat_Arr is array (Positive range <>) of Natural;

      --  Whole-stack rule after every merge_collapse: checked on the
      --  stack replayed from the event log just before every Push (the
      --  stack then is the one the previous merge_collapse left). Pushes
      --  lists the pushed lengths.
      procedure Replay (Input : Value_Array; Ok : out Boolean; Pushes : out Nat_Arr; NP : out Natural) is
         Output : Value_Array (Input'Range);
         Log    : Event_Log (1 .. 2 * Input'Length + 1);
         Count  : Natural;
         St     : Length_Array (1 .. Input'Length + 1) := [others => 0];
         Top    : Natural := 0;
      begin
         Sort_Traced (Input, Output, Log, Count);
         Ok := True;
         NP := 0;
         for E in 1 .. Count loop
            case Log (E).Kind is
               when Push =>
                  if not Runs_Rule (St, Top) then
                     Ok := False;
                  end if;
                  Top := Top + 1;
                  St (Top) := Log (E).B;
                  NP := NP + 1;
                  if NP <= Pushes'Last then
                     Pushes (NP) := Log (E).B;
                  end if;
               when Merge =>
                  St (Log (E).A) := St (Log (E).A) + St (Log (E).A + 1);
                  for X in Log (E).A + 1 .. Top - 1 loop
                     St (X) := St (X + 1);
                  end loop;
                  Top := Top - 1;
            end case;
         end loop;
      end Replay;

      --  Own model of merge_collapse with the ORIGINAL top-three-only
      --  check (no Len (n - 2) test), on given run lengths: True when the
      --  whole-stack rule is broken after some collapse.
      function Top_Three_Breaks (Runs : Nat_Arr) return Boolean is
         St  : Length_Array (1 .. Runs'Length + 1) := [others => 0];
         Top : Natural := 0;
         N   : Natural;
         Bad : Boolean := False;
         procedure Merge_At (I : Positive) is
         begin
            St (I) := St (I) + St (I + 1);
            for X in I + 1 .. Top - 1 loop
               St (X) := St (X + 1);
            end loop;
            Top := Top - 1;
         end Merge_At;
      begin
         for R of Runs loop
            Top := Top + 1;
            St (Top) := R;
            while Top > 1 loop
               N := Top - 1;
               if N > 1 and then St (N - 1) <= St (N) + St (N + 1) then
                  if St (N - 1) < St (N + 1) then
                     N := N - 1;
                  end if;
                  Merge_At (N);
               elsif St (N) <= St (N + 1) then
                  Merge_At (N);
               else
                  exit;
               end if;
            end loop;
            if not Runs_Rule (St, Top) then
               Bad := True;
            end if;
         end loop;
         return Bad;
      end Top_Three_Breaks;

      --  Ascending blocks of the given lengths, each block starting below
      --  the end of the previous one: count_run finds exactly these runs.
      function Blocks (Runs : Nat_Arr) return Value_Array is
         Total : Natural := 0;
      begin
         for R of Runs loop
            Total := Total + R;
         end loop;
         declare
            A : Value_Array (1 .. Total);
            P : Positive := 1;
         begin
            for B in Runs'Range loop
               for I in 1 .. Runs (B) loop
                  A (P) := 100_000 - 1_000 * B + I;
                  P := P + 1;
               end loop;
            end loop;
            return A;
         end;
      end Blocks;

      --  de Gouw et al.'s example 120, 80, 25, 20, 30 scaled by 2 so every
      --  run is at least Min_Run (585) = 37 and count_run pushes it as is,
      --  plus a last run of 35, so the stack the collapse after the push
      --  of 60 leaves is checked before a Push (the collapse after the
      --  last Push is followed by the forced merges in the log).
      Gouw : constant Nat_Arr := [240, 160, 50, 40, 60, 35];
      Ok   : Boolean;
      Ps   : Nat_Arr (1 .. 10) := [others => 0];
      NP   : Natural;
      Bad  : Natural := 0;
   begin
      Check (Runs_Rule (Length_Array'([10, 6, 3, 2]), 4)
             and then not Runs_Rule (Length_Array'([10, 6, 4, 2]), 4)
             and then not Runs_Rule (Length_Array'([10, 6, 3, 3]), 4)
             and then Runs_Rule (Length_Array'([1, 5]), 1)
             and then Runs_Rule (Length_Array'(1 .. 0 => 0), 0)
             and then not Runs_Rule (Length_Array'([120, 80, 45, 30]), 4),
             "Runs_Rule: each run longer than the next and than the next two together, over the whole stack");
      Check (Min_Run (585) = 37 and then Top_Three_Breaks (Gouw (1 .. 5)),
             "a top-three-only merge_collapse breaks the whole-stack rule on runs 240, 160, 50, 40, 60");
      Replay (Blocks (Gouw), Ok, Ps, NP);
      Check (NP = 6 and then Ps (1 .. 6) = Gouw and then Ok,
             "Sort_Traced pushes 240, 160, 50, 40, 60, 35 and keeps the whole-stack rule after every merge_collapse");
      for K in 1 .. 300 loop
         declare
            Len : constant Natural := P_Next (5_001);
            A   : Value_Array (1 .. Len);
         begin
            for I in A'Range loop
               A (I) := (if K mod 3 = 0 then P_Next (4) else P_Next (1_000_000));
            end loop;
            --  Natural runs: sort random stretches so pushes vary.
            if K mod 3 = 1 then
               declare
                  P : Natural := 1;
                  W : Natural;
               begin
                  while P <= Len loop
                     W := Natural'Min (1 + P_Next (400), Len - P + 1);
                     A (P .. P + W - 1) := Ref_Sort (A (P .. P + W - 1));
                     P := P + W;
                  end loop;
               end;
            end if;
            Replay (A, Ok, Ps, NP);
            if not Ok then
               Bad := Bad + 1;
            end if;
         end;
      end loop;
      Check (Bad = 0, "whole-stack run-length rule after every merge_collapse on 300 random inputs up to 5,000 (seed 20261009)");
   end Stack_Rule_Checks;

   Old_Stub : constant Value_Array :=
     [1 => 4, 2 => 1, 3 => 7, 4 => 3, 5 => 2, 6 => 8, 7 => 5, 8 => 6];
   Empty    : constant Value_Array (1 .. 0) := [others => 0];
   Big      : Value_Array (1 .. 120);
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Natural) return Natural is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Natural := Default;
   begin
      if V /= "" then
         S := Natural (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Natural'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Natural := AA_Seed (12_345);
begin
   Case_Of (Old_Stub, "old 8-element case");
   Check (Sort (Old_Stub) = [1, 2, 3, 4, 5, 6, 7, 8], "old case exact");
   Case_Of (Empty, "empty");
   Case_Of ([1 => 42], "one element");
   Case_Of ([10 => 3, 11 => 3, 12 => -1, 13 => 3], "duplicates, offset index");
   Case_Of ([5, 4, 3, 2, 1, 0, -1, -2, -3, -4], "reverse order");
   Case_Of ([Integer'Last, Integer'First, 0, Integer'Last], "extreme values");
   for K in Big'Range loop
      Seed := (Seed * 1_103 + 12_345) mod 65_536;
      Big (K) := Seed - 32_768;
   end loop;
   Case_Of (Big, "120 pseudo-random values");
   Perm_Checks;
   Stack_Rule_Checks;
   if Failures = 0 then
      Put_Line ("PASS Tim_Sort_Stub");
   else
      Put_Line ("FAIL" & Failures'Image & " checks");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
   Own_Checks;
end Tests;

--  Own tests for Tim_Sort_Stub (see tests/SOURCES.txt).
--  Sort must return the same bounds, sorted, and a permutation of Input.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Tim_Sort_Stub; use Tim_Sort_Stub;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20_261_008);
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;

   procedure Check_One (First : Positive; N : Natural; Lo, Hi : Integer; Label : String) is
      A : Value_Array (First .. First + N - 1);
      E : IArr (First .. First + N - 1);
   begin
      for I in A'Range loop
         A (I) := Next (Lo, Hi);
         E (I) := A (I);
      end loop;
      Ins_Sort (E);
      declare
         R : constant Value_Array := Sort (A);
         Ok : Boolean := R'First = A'First and then R'Last = A'Last;
      begin
         if Ok then
            for I in A'Range loop
               Ok := Ok and then R (I) = E (I);
            end loop;
         end if;
         Report (Ok, Label);
      end;
   end Check_One;
   --  Own model of CPython's listsort (Objects/listsort.txt), without
   --  galloping (galloping changes how a merge copies, not which runs are
   --  merged): min-run from the six most significant bits of N (+ 1 if
   --  any lower bit is set); runs = longest ascending or strictly
   --  descending stretch (the latter reversed), extended to min-run by
   --  binary insertion; after each push merge_collapse (the corrected rule
   --  that also looks at the third run from the top), at the end
   --  merge_force_collapse. Logs Push (base, length) and Merge (stack
   --  position I: runs I and I + 1).
   function Model_Min_Run (N : Natural) return Natural is
      Bits : Natural := 0;
      X    : Natural := N;
      Low  : Boolean := False;
   begin
      while X >= 64 loop
         if X mod 2 = 1 then
            Low := True;
         end if;
         X := X / 2;
         Bits := Bits + 1;
      end loop;
      return X + (if Low then 1 else 0);
   end Model_Min_Run;

   type Model_Log is array (Positive range <>) of Event;

   procedure Run_Model (A : in out IArr; Log : out Model_Log; Count : out Natural) is
      Base, Len : array (1 .. A'Length + 1) of Natural := [others => 0];
      Top : Natural := 0;
      Lo  : Positive := A'First;
      Min : constant Natural := Model_Min_Run (A'Length);
      procedure Add (E : Event) is
      begin
         Count := Count + 1;
         Log (Count) := E;
      end Add;
      procedure Merge_At (I : Positive) is
         T : IArr := A (Base (I) .. Base (I) + Len (I) + Len (I + 1) - 1);
      begin
         Ins_Sort (T);
         A (T'Range) := T;
         Len (I) := Len (I) + Len (I + 1);
         for K in I + 1 .. Top - 1 loop
            Base (K) := Base (K + 1);
            Len (K) := Len (K + 1);
         end loop;
         Top := Top - 1;
         Add ((Merge, I, 0));
      end Merge_At;
      N : Natural;
      R, Force : Natural;
   begin
      Log := [others => (Push, 0, 0)];
      Count := 0;
      while Lo <= A'Last loop
         R := 1;
         if Lo < A'Last then
            if A (Lo + 1) < A (Lo) then
               R := 2;
               while Lo + R <= A'Last and then A (Lo + R) < A (Lo + R - 1) loop
                  R := R + 1;
               end loop;
               declare
                  T : constant IArr := A (Lo .. Lo + R - 1);
               begin
                  for K in 0 .. R - 1 loop
                     A (Lo + K) := T (Lo + R - 1 - K);
                  end loop;
               end;
            else
               R := 2;
               while Lo + R <= A'Last and then not (A (Lo + R) < A (Lo + R - 1)) loop
                  R := R + 1;
               end loop;
            end if;
         end if;
         Force := Natural'Min (Min, A'Last - Lo + 1);
         if R < Force then
            Ins_Sort (A (Lo .. Lo + Force - 1));
            R := Force;
         end if;
         Top := Top + 1;
         Base (Top) := Lo;
         Len (Top) := R;
         Add ((Push, Lo, R));
         Lo := Lo + R;
         --  merge_collapse
         while Top > 1 loop
            N := Top - 1;
            if (N > 1 and then Len (N - 1) <= Len (N) + Len (N + 1))
              or else (N > 2 and then Len (N - 2) <= Len (N - 1) + Len (N))
            then
               if Len (N - 1) < Len (N + 1) then
                  N := N - 1;
               end if;
               Merge_At (N);
            elsif Len (N) <= Len (N + 1) then
               Merge_At (N);
            else
               exit;
            end if;
         end loop;
      end loop;
      while Top > 1 loop
         N := Top - 1;
         if N > 1 and then Len (N - 1) < Len (N + 1) then
            N := N - 1;
         end if;
         Merge_At (N);
      end loop;
   end Run_Model;

   procedure Check_Trace (First : Positive; N : Natural; Lo, Hi : Integer; Label : String) is
      A : Value_Array (First .. First + N - 1);
      E : IArr (First .. First + N - 1);
      O : Value_Array (A'Range);
      L : Event_Log (1 .. 2 * N + 1);
      ML : Model_Log (1 .. 2 * N + 1);
      C, MC : Natural;
      Ok : Boolean;
   begin
      for I in A'Range loop
         A (I) := Next (Lo, Hi);
         E (I) := A (I);
      end loop;
      Run_Model (E, ML, MC);
      Sort_Traced (A, O, L, C);
      Ok := C = MC;
      if Ok then
         for K in 1 .. C loop
            Ok := Ok and then L (K) = ML (K);
         end loop;
         for I in A'Range loop
            Ok := Ok and then O (I) = E (I);
         end loop;
      end if;
      Report (Ok, Label & ": runs / merges / result differ from the Timsort model");
   end Check_Trace;

   --  Inputs made of K ascending runs of the given lengths (each run
   --  shifted up), so natural runs are found and merged.
   procedure Check_Runs (Lens : IArr; Label : String) is
      N : Natural := 0;
   begin
      for X of Lens loop
         N := N + X;
      end loop;
      declare
         A : Value_Array (1 .. N);
         E : IArr (1 .. N);
         O : Value_Array (A'Range);
         L : Event_Log (1 .. 2 * N + 1);
         ML : Model_Log (1 .. 2 * N + 1);
         C, MC : Natural;
         P : Natural := 0;
         Ok : Boolean;
      begin
         for R in Lens'Range loop
            for K in 1 .. Lens (R) loop
               P := P + 1;
               A (P) := K * 7 + (R mod 3);
               E (P) := A (P);
            end loop;
         end loop;
         Run_Model (E, ML, MC);
         Sort_Traced (A, O, L, C);
         Ok := C = MC;
         if Ok then
            for K in 1 .. C loop
               Ok := Ok and then L (K) = ML (K);
            end loop;
            for I in A'Range loop
               Ok := Ok and then O (I) = E (I);
            end loop;
         end if;
         Report (Ok, Label);
      end;
   end Check_Runs;
begin
   --  0. Timsort itself (H109): min-run values from listsort.txt, the
   --     runs pushed and merges made equal the model; the old insertion
   --     sort under the name fails here (no runs, no merges).
   Report (Min_Run (63) = 63 and then Min_Run (64) = 32 and then Min_Run (65) = 33
           and then Min_Run (2048) = 32 and then Min_Run (2112) = 33 and then Min_Run (0) = 0,
           "min-run (listsort.txt values)");
   for N in 0 .. 70 loop
      Report (Min_Run (N) = Model_Min_Run (N), "min-run model N =" & N'Image);
   end loop;
   for N of IArr'[0, 1, 2, 5, 63, 64, 65, 100, 200, 500, 1000, 2112, 5000] loop
      for K in 1 .. 5 loop
         Check_Trace (1, N, -1_000_000, 1_000_000, "trace random N =" & N'Image);
         Check_Trace (1, N, 0, 3, "trace duplicates N =" & N'Image);
      end loop;
   end loop;
   Check_Runs ([200, 100, 50, 300, 40, 40, 40, 500], "natural runs merged");
   Check_Runs ([1000, 900, 800, 700, 600, 500, 400, 300], "decreasing run lengths");
   Check_Runs ([64, 64, 64, 64, 64, 64, 64, 64, 64, 64], "equal run lengths");
   for N in 0 .. 40 loop
      for K in 1 .. 50 loop
         Check_One (1, N, -1_000, 1_000, "random N=" & N'Image);
         Check_One (100, N, 0, 3, "duplicates N=" & N'Image);
      end loop;
   end loop;
   Check_One (1, 64, Integer'First, Integer'Last, "full Integer range");
   Check_One (Positive'Last - 100, 60, -5, 5, "high index bounds");
   Check_One (1, 200, -1_000_000, 1_000_000, "long array");
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (bounds, own insertion-sort reference)");
end Own_Checks;

--  Own tests for Minimum_Number_Of_Days_To_Make_M_Bouquets (written for
--  this repository; see tests/SOURCES.txt). Assumption: Minimum_Day
--  returns a day that is not the first day with enough bouquets, or gets
--  Possible wrong; or the greedy Count of the spec is not the largest
--  number of bouquets.
--  Reference: Best, a dynamic program over window placements (from the
--  right: flower I either starts no bouquet, or starts one when flowers
--  I .. I + Size - 1 have all bloomed), and the first day found by
--  trying every day from 1 up to the latest bloom day.
--  Inputs: all 6,561 arrays with bloom days in 1 .. 3, for every
--  Bouquets and Size in 1 .. 8; 3,000 random arrays with bloom days in
--  1 .. 1000 and random Bouquets and Size. Count is also compared with
--  Best on every bloom day and the day before it, and Lemma_Monotone
--  (ghost; its Pre, Post and the checks in its body run under -gnata) on
--  random day pairs, on equal days and from each bloom day onwards.
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Minimum_Number_Of_Days_To_Make_M_Bouquets;
use Minimum_Number_Of_Days_To_Make_M_Bouquets;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures : Natural := 0;
   Checked  : Natural := 0;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646;
      end if;
      Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (20261008);

   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Image (B : Bloom_Array) return String is
      (B (1)'Image & B (2)'Image & B (3)'Image & B (4)'Image
       & B (5)'Image & B (6)'Image & B (7)'Image & B (8)'Image);

   --  Most bouquets of Size neighbouring flowers open on day D.
   function Best (B : Bloom_Array; D : Natural; Size : Positive) return Natural is
      Most : array (1 .. Length + 1) of Natural := [others => 0];
   begin
      for I in reverse 1 .. Length loop
         Most (I) := Most (I + 1);
         if I + Size - 1 <= Length then
            declare
               Open : Boolean := True;
            begin
               for J in I .. I + Size - 1 loop
                  Open := Open and then B (J) <= D;
               end loop;
               if Open then
                  Most (I) := Natural'Max (Most (I), 1 + (if I + Size <= Length then Most (I + Size) else 0));
               end if;
            end;
         end if;
      end loop;
      return Most (1);
   end Best;

   procedure Check (B : Bloom_Array; M : Bouquet_Count; Size : Bouquet_Size) is
      Latest : Natural := 0;
      First  : Natural := 0;   --  0: no day works
      R      : constant Day_Result := Minimum_Day (B, M, Size);
      Tag    : constant String := "bloom" & Image (B) & " M" & M'Image & " Size" & Size'Image;
   begin
      for I in Index loop
         Latest := Natural'Max (Latest, B (I));
      end loop;
      for D in 1 .. Latest loop
         if Best (B, D, Size) >= M then
            First := D;
            exit;
         end if;
      end loop;
      Report (R.Possible = (First > 0), "Possible " & Tag);
      Report (R.Possible = (M * Size <= Length), "Possible vs M * Size " & Tag);
      if First > 0 then
         Report (R.First_Day = First, "first day " & Tag & " got" & R.First_Day'Image
                 & " want" & First'Image);
      else
         Report (R.First_Day = Day'Last, "impossible day " & Tag);
      end if;
   end Check;

   procedure Check_Count (B : Bloom_Array; D : Day; Size : Bouquet_Size) is
   begin
      Report (Count (B, D, Size) = Best (B, D, Size),
              "Count bloom" & Image (B) & " day" & D'Image & " Size" & Size'Image);
   end Check_Count;

   B : Bloom_Array;
begin
   --  Every array with bloom days 1 .. 3.
   for Code in 0 .. 3 ** Length - 1 loop
      declare
         C : Natural := Code;
      begin
         for I in Index loop
            B (I) := 1 + C mod 3;
            C := C / 3;
         end loop;
      end;
      for Size in Bouquet_Size loop
         for D in 1 .. 3 loop
            Check_Count (B, D, Size);
         end loop;
         for M in Bouquet_Count loop
            Check (B, M, Size);
         end loop;
      end loop;
   end loop;
   --  Random arrays with bloom days 1 .. 1000.
   for Run in 1 .. 3000 loop
      B := [for I in Index => Next (1, Day'Last)];
      declare
         Size : constant Bouquet_Size := Next (1, Length);
         M    : constant Bouquet_Count := Next (1, Length / Size);
         D1   : constant Day := Next (1, Day'Last);
         D2   : constant Day := Next (D1, Day'Last);
      begin
         Check (B, M, Size);
         Check (B, Next (1, Length), Size);
         for I in Index loop
            Check_Count (B, B (I), Size);
            if B (I) > 1 then
               Check_Count (B, B (I) - 1, Size);
            end if;
            --  The lemma on equal days and from a bloom day onwards:
            --  flower I opens exactly on the first of the two days.
            Lemma_Monotone (B, B (I), B (I), Size);
            Lemma_Monotone (B, B (I), Day'Last, Size);
         end loop;
         Lemma_Monotone (B, D1, D2, Size);   --  ghost; its Post runs under -gnata
         Report (Count (B, D1, Size) <= Count (B, D2, Size), "monotone Count" & Image (B));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (all 6561 arrays with days 1 .. 3 and 3000 random arrays: first day and Possible vs DP over placements; Count vs DP)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;

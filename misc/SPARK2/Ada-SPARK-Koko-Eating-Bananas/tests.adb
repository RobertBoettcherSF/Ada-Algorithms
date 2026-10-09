pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Koko_Eating_Bananas; use Koko_Eating_Bananas;
with Own_Checks;

procedure Tests is
   P    : constant Pile_Array := [3, 6, 7, 11, 2, 4, 5, 8];   --  46 bananas
   Full : constant Pile_Array := [others => 100];

   --  Speeds 1 .. 100: a halving search tries at most ceil (log2 100) = 7;
   --  the bound asserted here is floor (log2 100) + 2 = 8.
   function Floor_Log2 (N : Positive) return Natural is
      K : Natural := 0;
      M : Positive := N;
   begin
      while M > 1 loop
         M := M / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   Bound : constant Natural := Floor_Log2 (Speed'Last) + 2;

   procedure Expect (Piles : Pile_Array; Hours : Hour_Count; Want : Speed; Label : String) is
      R : constant Speed_Result := Minimum_Speed (Piles, Hours);
   begin
      if R.Minimum /= Want then
         raise Program_Error with Label & ": speed" & R.Minimum'Image & ", expected" & Want'Image;
      end if;
      if R.Probes > Bound then
         raise Program_Error with Label & ":" & R.Probes'Image
           & " speeds tried, more than floor (log2 100) + 2 =" & Bound'Image;
      end if;
   end Expect;
begin
   Expect (P, 8, 11, "one hour per pile");            --  the largest pile
   Expect (P, 9, 8, "9 hours");                       --  speed 7 needs 10
   Expect (P, 16, 4, "16 hours");
   Expect (P, 45, 2, "45 hours");                     --  speed 1 needs 46
   Expect (P, 46, 1, "46 hours");
   Expect (Full, 8, 100, "eight piles of 100 in 8 hours");
   Expect (Full, 100, 9, "eight piles of 100 in 100 hours");   --  speed 8 needs 104
   Put_Line ("Koko_Eating_Bananas: PASS");
   Own_Checks;
end Tests;

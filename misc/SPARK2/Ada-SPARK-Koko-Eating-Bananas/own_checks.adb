--  Own tests for Koko_Eating_Bananas (written for this repository; see
--  tests/SOURCES.txt). Assumption: Minimum_Speed returns a speed that
--  is too slow or not the slowest one for some piles and hours, tries
--  more than floor (log2 100) + 2 speeds, or Hours_Needed counts hours
--  wrongly.
--  Reference: hours simulated by eating S bananas at a time until the
--  pile is gone (no division), and the slowest speed by trying every
--  speed from 1 upward.
--  Inputs: all-equal piles for every size; 1,000 random pile arrays
--  (half of them from narrow size ranges), each with every Hours
--  8 .. 100; Hours_Needed against the simulation at every speed on 100
--  of them.
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Koko_Eating_Bananas; use Koko_Eating_Bananas;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures   : Natural := 0;
   Checked    : Natural := 0;
   Max_Probes : Natural := 0;

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

   function Simulated_Hours (Piles : Pile_Array; S : Speed) return Natural is
      Total : Natural := 0;
   begin
      for I in Index loop
         declare
            Left : Integer := Piles (I);
         begin
            while Left > 0 loop
               Left := Left - S;
               Total := Total + 1;
            end loop;
         end;
      end loop;
      return Total;
   end Simulated_Hours;

   procedure Check_All_Hours (Piles : Pile_Array; Label : String; Speeds : Boolean) is
      Sim : constant array (Speed) of Natural := [for S in Speed => Simulated_Hours (Piles, S)];
   begin
      if Speeds then
         for S in Speed loop
            Report (Hours_Needed (Piles, S) = Sim (S), Label & " Hours_Needed at speed" & S'Image);
         end loop;
      end if;
      for H in Hour_Count loop
         declare
            R    : constant Speed_Result := Minimum_Speed (Piles, H);
            Want : Speed := Speed'Last;
         begin
            for S in reverse Speed loop
               if Sim (S) <= H then
                  Want := S;
               end if;
            end loop;
            Report (R.Minimum = Want, Label & " hours" & H'Image & " got" & R.Minimum'Image
                    & " want" & Want'Image);
            Report (R.Probes <= Bound, Label & " hours" & H'Image & R.Probes'Image & " tries");
            Max_Probes := Natural'Max (Max_Probes, R.Probes);
         end;
      end loop;
   end Check_All_Hours;
begin
   for P in Pile_Size loop
      Check_All_Hours ([others => P], "all" & P'Image, Speeds => P mod 10 = 0);
   end loop;
   for Run in 1 .. 1000 loop
      declare
         Lo : constant Pile_Size := Next (1, 100);
         Hi : constant Pile_Size := (if Run mod 2 = 0 then Integer'Min (100, Lo + 3) else 100);
         L  : constant Pile_Size := Integer'Min (Lo, Hi);
         A  : constant Pile_Array := [for I in Index => Next (L, Hi)];
      begin
         Check_All_Hours (A, "random" & Run'Image, Speeds => Run mod 10 = 0);
      end;
   end loop;
   --  100 speeds need 7 tries in the worst case.
   Report (Max_Probes = 7, "worst case tries" & Max_Probes'Image & ", expected 7");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (1,100 pile arrays x 93 hours vs a no-division simulation; tries <= floor (log2 100) + 2, worst case 7)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;

with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Capacity_To_Ship_Packages; use Capacity_To_Ship_Packages;
with Own_Checks;

procedure Tests is
   W : constant Weight_Array := [1, 2, 3, 4, 5, 6, 7, 8];

   --  Capacities tried, exactly. A binary search on the answer over
   --  Lo = heaviest package .. Hi = Capacity'Last = 800 (always enough:
   --  8 packages of at most 100) halves Hi - Lo <= 799 each try, so it
   --  tries at most ceil (log2 800) = 10. Counts below are by hand:
   --  Mid = Lo + (Hi - Lo) / 2; feasible -> Hi := Mid, else Lo := Mid + 1.
   Max_Probes : constant := 10;
   procedure Expect
     (V : Weight_Array; D : Day_Count; Want, Probes : Natural; Label : String)
   is
      R : constant Capacity_Result := Minimum_Capacity_Counted (V, D);
   begin
      if R.Minimum /= Want then
         raise Program_Error with Label & ": capacity" & R.Minimum'Image
           & ", expected" & Want'Image;
      end if;
      --  R.Probes <= Max_Probes is now the range of Probe_Count (a
      --  constraint check under -gnata); the old scan's Natural count
      --  failed it here (14 tries for weights 1 .. 8 in 2 days).
      pragma Assert (Probe_Count'Last = Max_Probes);
      if R.Probes /= Probes then
         raise Program_Error with Label & ":" & R.Probes'Image
           & " capacities tried, expected exactly" & Probes'Image;
      end if;
      if Minimum_Capacity (V, D) /= R.Minimum then
         raise Program_Error with Label & ": Minimum_Capacity disagrees";
      end if;
   end Expect;
begin
   Assert (Minimum_Capacity (W, 2) = 21);
   Assert (Minimum_Capacity (W, 8) = 8);
   --  Lo .. Hi = 8 .. 800. Mids 404, 206, 107, 57, 32 fit in two days
   --  (Hi := Mid); 20 does not (1+..+5 = 15, 6+7 = 13, 8: three days),
   --  Lo := 21; then 26, 23, 22, 21 fit: ten tries.
   Expect (W, 2, 21, 10, "weights 1 .. 8 in 2 days");
   Expect ([others => 100], 1, 800, 9, "eight 100s in one day (answer is Hi)");
   Expect ([others => 100], 3, 300, 9, "eight 100s in three days");
   Expect ([others => 100], 8, 100, 10, "eight 100s in eight days (answer is Lo)");
   Expect ([others => 1], 1, 8, 10, "eight 1s in one day");
   Own_Checks;
   Put_Line ("PASS Capacity_To_Ship_Packages");
end Tests;

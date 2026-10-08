--  Own tests for Capacity_To_Ship_Packages (see tests/SOURCES.txt).
--  Minimum_Capacity (W, D) = min over every split of the 8 packages (in order) into at most D
--  consecutive groups of the heaviest group; reference: own enumeration of all 2**7 cut sets.
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Capacity_To_Ship_Packages; use Capacity_To_Ship_Packages;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
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
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Brute (W : Weight_Array; D : Day_Count) return Natural is
      Best : Natural := Natural'Last;
   begin
      for Cuts in 0 .. 2**(Length - 1) - 1 loop   --  bit I set: a new day starts after package I
         declare
            Groups : Natural := 1;
            Load, Heaviest : Natural := 0;
         begin
            for I in Index loop
               Load := Load + W (I);
               Heaviest := Natural'Max (Heaviest, Load);
               if I < Length and then (Cuts / 2**(I - 1)) mod 2 = 1 then
                  Groups := Groups + 1; Load := 0;
               end if;
            end loop;
            if Groups <= D then Best := Natural'Min (Best, Heaviest); end if;
         end;
      end loop;
      return Best;
   end Brute;
   W : Weight_Array;
begin
   for Trial in 1 .. 3_000 loop
      for I in Index loop
         W (I) := (if Trial mod 3 = 0 then Next (1, 5) else Next (1, 100));
      end loop;
      for D in Day_Count loop
         Report (Minimum_Capacity (W, D) = Brute (W, D), "weights trial" & Integer'Image (Trial) & " days" & Integer'Image (D));
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

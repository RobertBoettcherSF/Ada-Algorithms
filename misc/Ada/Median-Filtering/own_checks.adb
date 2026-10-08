pragma Ada_2022;
--  Own tests for Median_Filter (see tests/SOURCES.txt).
--  Process_1D with an odd kernel K: output I is the median of Input (I - K/2 .. I + K/2), where
--  indices outside the array take the nearest edge value (replication, as the spec states).
with Ada.Environment_Variables;
with Ada.Text_IO; use Ada.Text_IO;
with Median_Filter; use Median_Filter;

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
   function Ref (A : Data_1D; I, K : Positive) return Integer is
      W : array (1 .. K) of Integer;
      T, J : Integer;
   begin
      for P in 1 .. K loop
         J := Integer'Max (A'First, Integer'Min (A'Last, I - K / 2 + P - 1));
         W (P) := A (J);
      end loop;
      for P in 2 .. K loop   --  own insertion sort
         T := W (P); J := P - 1;
         while J >= 1 and then W (J) > T loop W (J + 1) := W (J); J := J - 1; end loop;
         W (J + 1) := T;
      end loop;
      return W ((K + 1) / 2);
   end Ref;
begin
   for Run in 1 .. 5000 loop
      declare
         First : constant Positive := Next (1, 4);
         A : Data_1D (First .. First + Next (1, 20) - 1);
         K : constant Positive := 2 * Next (0, 4) + 1;
         Hi : constant Integer := (if Run mod 2 = 0 then 3 else 1000);
         Ok : Boolean := True;
      begin
         for X of A loop X := Next (-Hi, Hi); end loop;
         declare
            R : constant Data_1D := Process_1D (A, K);
         begin
            Ok := R'Length = A'Length;
            if Ok then
               for I in A'Range loop
                  Ok := Ok and then R (R'First + (I - A'First)) = Ref (A, I, K);
               end loop;
            end if;
         end;
         Report (Ok, "run" & Integer'Image (Run) & " K =" & Integer'Image (K));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

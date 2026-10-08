pragma Ada_2022;
--  Own tests for Nth_Ugly_Number (see tests/SOURCES.txt).
--  Is_Ugly / Compute: ugly numbers have no prime factor other than 2, 3, 5; Compute (N) is the N-th (1 is the first).
with Ada.Text_IO; use Ada.Text_IO;
with Nth_Ugly_Number; use Nth_Ugly_Number;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Ugly (N : Positive) return Boolean is
      V : Positive := N;
   begin
      for P in 2 .. 5 loop
         while V mod P = 0 loop V := V / P; end loop;   --  P = 4 never divides here
      end loop;
      return V = 1;
   end Ugly;
begin
   for N in Number loop
      Report (Is_Ugly (N) = Ugly (N), "Is_Ugly" & Integer'Image (N));
   end loop;
   declare
      Seen : Natural := 0;
   begin
      for C in 1 .. 1_000 loop
         if Ugly (C) and then Seen < 32 then
            Seen := Seen + 1;
            Report (Compute (Seen) = C, "Compute" & Integer'Image (Seen));
         end if;
      end loop;
      Report (Seen = 32, "fewer than 32 ugly numbers below 1000");
   end;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

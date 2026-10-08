--  Own tests for Bulb_Switcher (see tests/SOURCES.txt).
--  Switched_On (N) = number of perfect squares in 1 .. N = the K with K*K <= N < (K+1)*(K+1).
with Ada.Text_IO; use Ada.Text_IO;
with Bulb_Switcher; use Bulb_Switcher;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   Seed : Long_Long_Integer := 20261008;
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
   procedure Check (N : Bulbs) is
      K : constant Long_Long_Integer := Long_Long_Integer (Switched_On (N));
   begin
      Report (K * K <= Long_Long_Integer (N) and then Long_Long_Integer (N) < (K + 1) * (K + 1),
              "bulbs" & Integer'Image (N));
   end Check;
   On : array (1 .. 3_000) of Boolean;
begin
   --  direct simulation of the toggling rounds for small N
   for N in 1 .. 3_000 loop
      On := [others => False];
      for Round in 1 .. N loop
         declare
            B : Positive := Round;
         begin
            while B <= N loop
               On (B) := not On (B);
               B := B + Round;
            end loop;
         end;
      end loop;
      declare
         Lit : Natural := 0;
      begin
         for I in 1 .. N loop
            if On (I) then Lit := Lit + 1; end if;
         end loop;
         Report (Switched_On (N) = Lit, "simulation" & Integer'Image (N));
      end;
   end loop;
   Check (0);
   for N in 0 .. 1_000_000 loop
      Check (N);
   end loop;
   for K in 1 .. 31_622 loop
      Check (Bulbs (K * K - 1)); Check (Bulbs (K * K));
   end loop;
   for Trial in 1 .. 100_000 loop
      Check (Next (0, Bulbs'Last));
   end loop;
   Check (Bulbs'Last);
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

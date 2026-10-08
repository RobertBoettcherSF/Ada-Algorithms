--  Own tests for Count_Odd_Numbers (see tests/SOURCES.txt).
--  Count_Odd_Numbers.Count (Low, High) = number of odd integers in Low .. High.
with Ada.Text_IO; use Ada.Text_IO;
with Count_Odd_Numbers; use Count_Odd_Numbers;

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
   function Brute (L, H : Natural) return Natural is
      N : Natural := 0;
   begin
      for I in L .. H loop
         if I mod 2 = 1 then N := N + 1; end if;
      end loop;
      return N;
   end Brute;
begin
   for L in 0 .. 400 loop
      for H in L .. 400 loop
         Report (Count_Odd_Numbers.Count (L, H) = Brute (L, H), "small" & Integer'Image (L) & Integer'Image (H));
      end loop;
   end loop;
   --  large intervals: split at a random point (additivity) and brute-force the short ends
   for Trial in 1 .. 50_000 loop
      declare
         L : constant Endpoint := Next (0, Endpoint'Last);
         H : constant Endpoint := Next (L, Endpoint'Last);
         M : constant Endpoint := Next (L, H);
      begin
         Report (M = H or else Count_Odd_Numbers.Count (L, H) = Count_Odd_Numbers.Count (L, M) + Count_Odd_Numbers.Count (M + 1, H), "split");
         Report (H - L > 50 or else Count_Odd_Numbers.Count (L, H) = Brute (L, H), "short");
         Report (abs (2 * Long_Long_Integer (Count_Odd_Numbers.Count (L, H)) - Long_Long_Integer (H - L + 1)) <= 1, "half");
      end;
   end loop;
   Report (Count_Odd_Numbers.Count (Endpoint'Last, Endpoint'Last) = 0 and then Count_Odd_Numbers.Count (0, 0) = 0, "ends");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

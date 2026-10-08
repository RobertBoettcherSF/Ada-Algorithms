pragma Ada_2022;
--  Own tests for Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown (see tests/SOURCES.txt).
--  Own brute force over every day-by-day choice (buy, sell, rest): at most one share held,
--  and no buy on the day right after a sale.
with Ada.Text_IO; use Ada.Text_IO;
with Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown; use Best_Time_To_Buy_And_Sell_Stock_With_Cooldownoldown;

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
   function Best (P : Input_Array; Day : Positive; Holding : Boolean; Bought : Integer;
                  Cool : Boolean) return Integer is
      R : Integer;
   begin
      if Day > Length then return 0; end if;
      R := Best (P, Day + 1, Holding, Bought, False);   --  rest
      if Holding then
         R := Integer'Max (R, P (Day) - Bought + Best (P, Day + 1, False, 0, True));   --  sell
      elsif not Cool then
         R := Integer'Max (R, Best (P, Day + 1, True, P (Day), False));   --  buy
      end if;
      return R;
   end Best;
begin
   for Run in 1 .. 3000 loop
      declare
         A : Input_Array;
         Hi : constant Natural := (if Run mod 2 = 0 then 10 else 100);
      begin
         for I in Index loop A (I) := Next (0, Hi); end loop;
         Report (Max_Profit (A) = Best (A, 1, False, 0, False), "run" & Integer'Image (Run));
      end;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

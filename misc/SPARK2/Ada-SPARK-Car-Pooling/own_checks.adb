--  Own tests for Car_Pooling (see tests/SOURCES.txt).
--  Feasible (T, Limit): at no stop does the car carry more than Limit people, where a trip carries
--  its people from Pickup up to (not including) Dropoff - the standard car-pooling statement.
with Ada.Text_IO; use Ada.Text_IO;
with Car_Pooling; use Car_Pooling;

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
   function Brute (T : Trips; Limit : Capacity) return Boolean is
   begin
      for Stop in Index loop
         declare
            On_Board : Natural := 0;
         begin
            for Tr of T loop
               if Tr.Pickup <= Stop and then Stop < Tr.Dropoff then On_Board := On_Board + Tr.People; end if;
            end loop;
            if On_Board > Limit then return False; end if;
         end;
      end loop;
      return True;
   end Brute;
   T : Trips;
begin
   for Trial in 1 .. 20_000 loop
      for I in Index loop
         declare
            P : constant Index := Next (1, Size - 1);
         begin
            T (I) := (People => Next (0, 4), Pickup => P, Dropoff => Next (P + 1, Size));
         end;
      end loop;
      for Limit in 0 .. 12 loop
         Report (Feasible (T, Limit) = Brute (T, Limit), "trial" & Integer'Image (Trial) & " limit" & Integer'Image (Limit));
      end loop;
   end loop;
   --  back-to-back trips: the first group leaves at stop 3 where the second boards
   T := [others => (People => 0, Pickup => 1, Dropoff => 2)];
   T (1) := (People => 2, Pickup => 1, Dropoff => 3);
   T (2) := (People => 2, Pickup => 3, Dropoff => 5);
   Report (Feasible (T, 2), "back-to-back trips fit two seats");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

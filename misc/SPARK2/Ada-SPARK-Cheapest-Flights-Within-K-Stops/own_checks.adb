--  Own tests for Cheapest_Flights_Within_K_Stops (see tests/SOURCES.txt).
--  Compute: cheapest route from Source to Destination using at most K + 1 flights (K stops);
--  Infinity when there is none. Reference: own depth-first enumeration of every route.
with Ada.Text_IO; use Ada.Text_IO;
with Cheapest_Flights_Within_K_Stops; use Cheapest_Flights_Within_K_Stops;

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
   E : Edge_Array;
   function Brute (At_Node, Dest : Node; Flights_Left : Natural) return Natural is
      Best : Natural := (if At_Node = Dest then 0 else Infinity);
   begin
      if Flights_Left = 0 then return Best; end if;
      for I in Edge_Index loop
         if E (I).U = At_Node then
            declare
               Rest : constant Natural := Brute (E (I).V, Dest, Flights_Left - 1);
            begin
               if Rest < Infinity then Best := Natural'Min (Best, E (I).Price + Rest); end if;
            end;
         end if;
      end loop;
      return Best;
   end Brute;
begin
   for Trial in 1 .. 1_500 loop
      for I in Edge_Index loop
         E (I) := (U => Next (1, Capacity), V => Next (1, Capacity), Price => Next (0, 100));
      end loop;
      for S in Node loop
         for D in Node loop
            for K in 0 .. 3 loop
               declare
                  R : Cost;
               begin
                  Compute (E, S, D, K, R);
                  Report (R = Brute (S, D, K + 1), "trial" & Integer'Image (Trial));
               end;
            end loop;
         end loop;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

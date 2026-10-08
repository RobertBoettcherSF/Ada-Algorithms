--  Own tests for Unique_Paths_With_Obstacles (see tests/SOURCES.txt).
--  Count = number of right/down paths from (1, 1) to (4, 4) avoiding True cells.
pragma Ada_2022;
with Ada.Text_IO;
with Unique_Paths_With_Obstacles; use Unique_Paths_With_Obstacles;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;
   pragma Warnings (Off, Next);

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Own reference: straight insertion sort.
   type IArr is array (Positive range <>) of Integer;
   procedure Ins_Sort (A : in out IArr) is
      T : Integer;
      J : Positive;
   begin
      for I in A'First + 1 .. A'Last loop
         T := A (I);
         J := I;
         while J > A'First and then A (J - 1) > T loop
            A (J) := A (J - 1);
            J := J - 1;
         end loop;
         A (J) := T;
      end loop;
   end Ins_Sort;
   pragma Warnings (Off, Ins_Sort);

   G : Grid;
   function Paths (R, C : Coordinate) return Natural is
   begin
      if G (R, C) then
         return 0;
      elsif R = Grid_Size and then C = Grid_Size then
         return 1;
      end if;
      return (if R < Grid_Size then Paths (R + 1, C) else 0) + (if C < Grid_Size then Paths (R, C + 1) else 0);
   end Paths;
begin
   for K in 0 .. 65_535 loop                --  every obstacle pattern on the 4 x 4 grid
      declare
         X : Natural := K;
      begin
         for R in Coordinate loop
            for C in Coordinate loop
               G (R, C) := X mod 2 = 1;
               X := X / 2;
            end loop;
         end loop;
         Report (Count (G) = Paths (1, 1), "case" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own recursive path enumeration, exhaustive)");
end Own_Checks;

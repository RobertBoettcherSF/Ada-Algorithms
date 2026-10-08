--  Own tests for Minimum_Path_Sum (see tests/SOURCES.txt).
--  Minimum must be the cheapest right/down path from the top-left to the bottom-right cell, both included.
pragma Ada_2022;
with Ada.Text_IO;
with Minimum_Path_Sum; use Minimum_Path_Sum;

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
   function Ref (R, C : Coordinate) return Natural is
   begin
      if R = Grid_Size and then C = Grid_Size then return G (R, C); end if;
      if R = Grid_Size then return G (R, C) + Ref (R, C + 1); end if;
      if C = Grid_Size then return G (R, C) + Ref (R + 1, C); end if;
      return G (R, C) + Natural'Min (Ref (R + 1, C), Ref (R, C + 1));
   end Ref;
begin
   for Iter in 1 .. 6_000 loop
      for R in Coordinate loop
         for C in Coordinate loop
            G (R, C) := Next (0, (if Iter mod 2 = 0 then 2 else 9));
         end loop;
      end loop;
      Report (Minimum (G) = Ref (1, 1), "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own path-recursion reference)");
end Own_Checks;

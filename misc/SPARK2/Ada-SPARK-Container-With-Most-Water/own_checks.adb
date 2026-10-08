--  Own tests for Container_With_Most_Water (see tests/SOURCES.txt).
--  Max_Area must be the best (J - I) * min (H (I), H (J)) over pairs, by all pairs.
pragma Ada_2022;
with Ada.Text_IO;
with Container_With_Most_Water; use Container_With_Most_Water;

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
   D : Heights;
   function Ref (N : Natural) return Natural is
      Best : Natural := 0;
   begin
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            Best := Natural'Max (Best, (J - I) * Natural'Min (D (I), D (J)));
         end loop;
      end loop;
      return Best;
   end Ref;
begin
   for Iter in 1 .. 6_000 loop
      declare
         N : constant Natural := Next (0, 32);
         Hi : constant Natural := (if Iter mod 2 = 0 then 5 else 1_000);
      begin
         D := [others => Next (0, 1_000)];
         for I in 1 .. N loop
            D (I) := Next (0, Hi);
         end loop;
         Report (Max_Area (D, N) = Ref (N), "random" & Iter'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-pairs reference)");
end Own_Checks;

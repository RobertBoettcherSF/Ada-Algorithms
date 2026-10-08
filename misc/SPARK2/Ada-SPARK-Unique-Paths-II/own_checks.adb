--  Own tests for Unique_Paths_II (see tests/SOURCES.txt).
--  Count must be the number of right/down paths from (1, 1) to (Rows, Cols) that avoid blocked cells.
pragma Ada_2022;
with Ada.Text_IO;
with Unique_Paths_II; use Unique_Paths_II;

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

   B : Grid;
   function Ref (R, C, Rows, Cols : Positive) return Natural is
   begin
      if B (R, C) then return 0; end if;
      if R = Rows and then C = Cols then return 1; end if;
      return (if R < Rows then Ref (R + 1, C, Rows, Cols) else 0)
           + (if C < Cols then Ref (R, C + 1, Rows, Cols) else 0);
   end Ref;
begin
   for Iter in 1 .. 3_000 loop
      declare
         Rows : constant Dimension := Next (1, 8);
         Cols : constant Dimension := Next (1, 8);
         P : constant Natural := (case Iter mod 3 is when 0 => 0, when 1 => 10, when others => 25);
      begin
         for R in Dimension loop
            for C in Dimension loop
               B (R, C) := Next (0, 99) < P;
            end loop;
         end loop;
         Report (Count (Rows, Cols, B) = Ref (1, 1, Rows, Cols), "random" & Iter'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own path-recursion reference)");
end Own_Checks;

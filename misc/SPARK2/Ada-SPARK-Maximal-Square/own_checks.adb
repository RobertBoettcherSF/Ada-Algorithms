--  Own tests for Maximal_Square (see tests/SOURCES.txt).
--  Largest_Side must be the side of the largest all-one square, for every 4 x 4 0/1 matrix.
pragma Ada_2022;
with Ada.Text_IO;
with Maximal_Square; use Maximal_Square;

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
   A : Matrix;
   function Ref return Natural is
      Best : Natural := 0;
      Ok : Boolean;
   begin
      for S in 1 .. 4 loop
         for R in 1 .. 5 - S loop
            for C in 1 .. 5 - S loop
               Ok := True;
               for I in R .. R + S - 1 loop
                  for J in C .. C + S - 1 loop
                     if A (I, J) = 0 then Ok := False; end if;
                  end loop;
               end loop;
               if Ok then Best := S; end if;
            end loop;
         end loop;
      end loop;
      return Best;
   end Ref;
begin
   for Code in 0 .. 2 ** 16 - 1 loop
      for K in 0 .. 15 loop
         A (K / 4 + 1, K mod 4 + 1) := (Code / 2 ** K) mod 2;
      end loop;
      Report (Largest_Side (A) = Ref, "matrix");
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own all-squares reference, exhaustive)");
end Own_Checks;

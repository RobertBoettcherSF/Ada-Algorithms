--  Own tests for Pascal_Triangle (see tests/SOURCES.txt).
--  Row_Total (R) must be the sum of row R of Pascal's triangle, built by additions in
--  the test, for every row whose total fits Result (rows 0 .. 30).
pragma Ada_2022;
with Ada.Text_IO;
with Pascal_Triangle; use Pascal_Triangle;

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
   type Row_T is array (0 .. 32) of Long_Long_Integer;
   Row, Prev : Row_T := [others => 0];
   S : Long_Long_Integer;
begin
   Row (0) := 1;
   for R in Row_Index loop   --  every row the input type allows must give the exact total
      if R > 0 then
         Prev := Row;
         for K in 1 .. R loop
            Row (K) := Prev (K - 1) + Prev (K);
         end loop;
      end if;
      S := 0;
      for K in 0 .. R loop
         S := S + Row (K);
      end loop;
      Report (Long_Long_Integer (Row_Total (R)) = S, "row" & R'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own Pascal triangle built by additions)");
end Own_Checks;

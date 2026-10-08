--  Own tests for Sort_Colors (see tests/SOURCES.txt).
--  Sort (Data, Length) must sort Data (1 .. Length) and leave the rest unchanged.
pragma Ada_2022;
with Ada.Text_IO;
with Sort_Colors; use Sort_Colors;

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

   procedure Check_One (D : Colors; L : Length_Type; Label : String) is
      R : Colors := D;
      E : IArr (1 .. Index'Last);
      Ok : Boolean := True;
   begin
      Sort (R, L);
      for I in Index loop
         E (I) := D (I);
      end loop;
      Ins_Sort (E (1 .. L));
      for I in Index loop
         Ok := Ok and then R (I) = E (I);
      end loop;
      Report (Ok, Label);
   end Check_One;
   D : Colors;
begin
   for L in Length_Type loop
      Check_One ([for I in Index => 2 - (I mod 3)], L, "pattern L=" & L'Image);
      Check_One ([others => 2], L, "all 2 L=" & L'Image);
   end loop;
   for K in 1 .. 3_000 loop
      for I in Index loop
         D (I) := Next (0, 2);
      end loop;
      Check_One (D, Next (0, Length_Type'Last), "random" & K'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own insertion-sort reference on the prefix; tail unchanged)");
end Own_Checks;

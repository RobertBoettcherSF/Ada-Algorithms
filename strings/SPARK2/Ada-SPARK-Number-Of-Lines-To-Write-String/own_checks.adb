--  Own tests for Write_String_Lines (see tests/SOURCES.txt).
--  Lines_For: characters are placed on lines of width 100; a character that does
--  not fit starts a new line.
pragma Ada_2022;
with Ada.Text_IO;
with Write_String_Lines; use Write_String_Lines;

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


   W : Width_Table;
   T : Text := [others => 'a'];
   N : Length_Type;
   L : Line_Count_Type;
   LW : Width_Type;
begin
   for K in 1 .. 4_000 loop
      for C in W'Range loop
         W (C) := Next (1, (if K mod 2 = 0 then 100 else 10));
      end loop;
      N := Next (0, 32);
      for I in 1 .. N loop
         T (I) := Character'Val (Character'Pos ('a') + Next (0, 25));
      end loop;
      declare
         EL : Positive := 1;
         EW : Natural := 0;
      begin
         for I in 1 .. N loop
            if EW + W (T (I)) > 100 then
               EL := EL + 1;
               EW := W (T (I));
            else
               EW := EW + W (T (I));
            end if;
         end loop;
         Lines_For (W, T, N, L, LW);
         Report (L = EL and then LW = EW, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own line-filling simulation)");
end Own_Checks;

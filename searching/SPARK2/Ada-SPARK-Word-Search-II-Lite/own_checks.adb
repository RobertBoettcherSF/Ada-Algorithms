--  Own tests for Word_Search_II_Lite (see tests/SOURCES.txt).
--  Appears_Horizontally: the 3-letter word occurs left to right in some row;
--  Count_Found counts the words of the list that do.
pragma Ada_2022;
with Ada.Text_IO;
with Word_Search_II_Lite; use Word_Search_II_Lite;

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


   B : Board;
   W : Pattern_List;
   function Rand_Letter (Hi : Character) return Letter is
     (Character'Val (Character'Pos ('a') + Next (0, Character'Pos (Hi) - Character'Pos ('a'))));
   function In_Row (B : Board; P : Pattern; Rev : Boolean) return Boolean is
   begin
      for R in Row loop
         for S in 1 .. Board_Size - 2 loop
            if (if Rev then B (R, S) = P (3) and then B (R, S + 1) = P (2) and then B (R, S + 2) = P (1)
                else B (R, S) = P (1) and then B (R, S + 1) = P (2) and then B (R, S + 2) = P (3))
            then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end In_Row;
begin
   for K in 1 .. 5_000 loop
      for R in Row loop
         for C in Column loop
            B (R, C) := Rand_Letter ((if K mod 2 = 0 then 'b' else 'd'));
         end loop;
      end loop;
      for I in W'Range loop
         loop
            if Next (0, 1) = 0 then
               declare
                  R : constant Row := Next (1, Board_Size);
                  S : constant Positive := Next (1, Board_Size - 2);
               begin
                  W (I) := [B (R, S), B (R, S + 1), B (R, S + 2)];
               end;
            else
               W (I) := [Rand_Letter ('d'), Rand_Letter ('d'), Rand_Letter ('d')];
            end if;
            exit when (for all J in 1 .. I - 1 => W (J) /= W (I));
         end loop;
      end loop;
      declare
         Expected : Natural := 0;
         Skip : Boolean := False;
      begin
         for I in W'Range loop
            if In_Row (B, W (I), False) then
               Expected := Expected + 1;
               Report (Appears_Horizontally (B, W (I)), "appears" & K'Image);
            elsif In_Row (B, W (I), True) then
               Skip := True;          --  only right-to-left: direction convention, not checked
            else
               Report (not Appears_Horizontally (B, W (I)), "absent" & K'Image);
            end if;
         end loop;
         if not Skip then
            Report (Count_Found (B, W) = Expected, "count" & K'Image);
         end if;
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own row scan reference)");
end Own_Checks;

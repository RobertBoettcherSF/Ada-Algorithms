--  Own tests for Reverse_Words_In_A_String_III (see tests/SOURCES.txt).
--  Every maximal run of non-space characters is reversed in place; spaces stay.
pragma Ada_2022;
with Ada.Text_IO;
with Reverse_Words_In_A_String_III; use Reverse_Words_In_A_String_III;

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

   T, O : Text := [others => ' '];
   N, M : Length_Type;
begin
   for K in 1 .. 4_000 loop
      N := Next (0, 32);
      for I in 1 .. N loop
         T (I) := (if Next (0, 3) = 0 then ' ' else Character'Val (Character'Pos ('a') + Next (0, 25)));
      end loop;
      Reverse_Words (T, N, O, M);
      declare
         E : String (1 .. N);
         I : Natural := 1;
         J : Natural;
      begin
         while I <= N loop
            if T (I) = ' ' then
               E (I) := ' ';
               I := I + 1;
            else
               J := I;
               while J < N and then T (J + 1) /= ' ' loop
                  J := J + 1;
               end loop;
               for P in I .. J loop
                  E (P) := T (I + J - P);
               end loop;
               I := J + 1;
            end if;
         end loop;
         Report (M = N and then String (O (1 .. M)) = E, "random" & K'Image);
      end;
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own word-reversal reference)");
end Own_Checks;

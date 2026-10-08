--  Own tests for Valid_Parentheses (see tests/SOURCES.txt).
--  Is_Valid must accept exactly the properly nested strings over ()[]{}, for every 6-character string.
pragma Ada_2022;
with Ada.Text_IO;
with Valid_Parentheses; use Valid_Parentheses;

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
   Sym : constant String := "()[]{}";
   X : Text_Array;
   function Ref return Boolean is
      Stack : String (1 .. Length);
      Top : Natural := 0;
   begin
      for I in Index loop
         case X (I) is
            when '(' | '[' | '{' =>
               Top := Top + 1; Stack (Top) := X (I);
            when others =>
               if Top = 0 then return False; end if;
               if (X (I) = ')' and then Stack (Top) /= '(')
                 or else (X (I) = ']' and then Stack (Top) /= '[')
                 or else (X (I) = '}' and then Stack (Top) /= '{')
               then
                  return False;
               end if;
               Top := Top - 1;
         end case;
      end loop;
      return Top = 0;
   end Ref;
begin
   for Code in 0 .. 6 ** Length - 1 loop
      declare
         C : Natural := Code;
      begin
         for I in Index loop
            X (I) := Sym (C mod 6 + 1);
            C := C / 6;
         end loop;
      end;
      Report (Is_Valid (X) = Ref, "string");
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own stack reference, exhaustive)");
end Own_Checks;

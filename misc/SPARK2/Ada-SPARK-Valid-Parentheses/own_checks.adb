--  Own tests for Valid_Parentheses (see tests/SOURCES.txt).
--  Is_Valid must accept exactly the properly nested strings over ()[]{}, for every 6-character string.
pragma Ada_2022;
with Ada.Text_IO;
with Valid_Parentheses; use Valid_Parentheses;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).

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

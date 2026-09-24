pragma Ada_2022;

package body Valid_Parentheses with SPARK_Mode => On is
   subtype Stack_Index is Positive range 1 .. Length / 2;
   type Stack_Array is array (Stack_Index) of Character;

   function Matches (Open : Character; Close : Character) return Boolean is
   begin
      return (Open = '(' and then Close = ')')
        or else (Open = '[' and then Close = ']')
        or else (Open = '{' and then Close = '}');
   end Matches;

   function Is_Valid (Input : Text_Array) return Boolean is
      Stack : Stack_Array := (others => ' ');
      Top : Natural range 0 .. Length / 2 := 0;
   begin
      for I in Index loop
         if Input (I) = '(' or else Input (I) = '[' or else Input (I) = '{' then
            if Top = Length / 2 then
               return False;
            end if;
            Top := Top + 1;
            Stack (Stack_Index (Top)) := Input (I);
         elsif Input (I) = ')' or else Input (I) = ']' or else Input (I) = '}' then
            if Top = 0 then
               return False;
            end if;
            if not Matches (Stack (Stack_Index (Top)), Input (I)) then
               return False;
            end if;
            Top := Top - 1;
         else
            return False;
         end if;
      end loop;
      return Top = 0;
   end Is_Valid;
end Valid_Parentheses;

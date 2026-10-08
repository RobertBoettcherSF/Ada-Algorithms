pragma Ada_2022;

package body Regular_Expression_Matching_Lite with SPARK_Mode => On is
   type Grid is array (Position, Position) of Boolean;

   function Same (Pattern_Character, Input_Character : Character)
     return Boolean
   is
   begin
      return Pattern_Character = '.' or else Pattern_Character = Input_Character;
   end Same;

   function Matches
     (Input, Pattern : Text; NI, NP : Length) return Boolean
   is
      D : Grid := (others => (others => False));
   begin
      if NI = 0 and then NP = 0 then
         return True;
      elsif NI = 0 then
         return False;
      elsif NP = 0 then
         return False;
      end if;
      D (NP + 1, NI + 1) := True;
      for I in reverse 1 .. NP loop
         if I < NP and then Pattern (I + 1) = '*' then
            D (I, NI + 1) := D (I + 2, NI + 1);
         end if;
         for J in reverse 1 .. NI loop
            if I < NP and then Pattern (I + 1) = '*' then
               D (I, J) := D (I + 2, J)
                 or else (Same (Pattern (I), Input (J)) and then D (I, J + 1));
            elsif Same (Pattern (I), Input (J)) then
               D (I, J) := D (I + 1, J + 1);
            end if;
         end loop;
      end loop;
      return D (1, 1);
   end Matches;
end Regular_Expression_Matching_Lite;

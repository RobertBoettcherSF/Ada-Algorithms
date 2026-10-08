pragma Ada_2022;

package body Wildcard_Matching_Lite with SPARK_Mode => On is
   type Grid is array (Length, Length) of Boolean;

   function Matches
     (Input, Pattern : Text; NI, NP : Length) return Boolean
   is
      D : Grid := (others => (others => False));
   begin
      D (0, 0) := True;
      for I in 1 .. NP loop
         if Pattern (I) = '*' then
            D (I, 0) := D (I - 1, 0);
         end if;
         for J in 1 .. NI loop
            if Pattern (I) = '*' then
               D (I, J) := D (I - 1, J) or else D (I, J - 1);
            elsif Pattern (I) = '?'
              or else Pattern (I) = Input (J)
            then
               D (I, J) := D (I - 1, J - 1);
            end if;
         end loop;
      end loop;
      return D (NP, NI);
   end Matches;
end Wildcard_Matching_Lite;

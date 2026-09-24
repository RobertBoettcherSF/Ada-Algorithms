pragma SPARK_Mode (On);

package body Interleaving_String is
   type Grid is array (Length, Length) of Boolean;

   function Is_Interleaving
     (A, B, C : Word; NA, NB, NC : Length) return Boolean
   is
      D : Grid := (others => (others => False));
      K : Natural;
   begin
      D (0, 0) := True;
      for I in 0 .. NA loop
         for J in 0 .. NB loop
            K := I + J;
            if K > 0 and then K <= NC then
               if I > 0 and then D (I - 1, J) and then A (I) = C (K) then
                  D (I, J) := True;
               elsif J > 0 and then D (I, J - 1) and then B (J) = C (K) then
                  D (I, J) := True;
               end if;
            end if;
         end loop;
      end loop;
      return D (NA, NB) and then NA + NB = NC;
   end Is_Interleaving;
end Interleaving_String;

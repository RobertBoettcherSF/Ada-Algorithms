pragma Ada_2022;

package body Search_A_2D_Matrix_II with SPARK_Mode => On is
   function Contains (Grid : Matrix; Target : Value) return Search_Result is
      Found  : Boolean := False;
      Probes : Natural := 0;
   begin
      for I in Row loop
         for J in Column loop
            Probes := Probes + 1;
            if Grid (I, J) = Target then
               Found := True;
            end if;
         end loop;
      end loop;
      return (Found => Found, Probes => Probes);
   end Contains;
end Search_A_2D_Matrix_II;

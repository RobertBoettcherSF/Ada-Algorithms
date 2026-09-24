pragma Ada_2022;

package body Peak_Index_In_Mountain_Array with SPARK_Mode => On is
   function Peak_Index (Input : Mountain_Array) return Index is
      Best : Index := Index'First;
   begin
      for I in Index range Index'Succ (Index'First) .. Index'Last loop
         if Input (I) > Input (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Peak_Index;
end Peak_Index_In_Mountain_Array;

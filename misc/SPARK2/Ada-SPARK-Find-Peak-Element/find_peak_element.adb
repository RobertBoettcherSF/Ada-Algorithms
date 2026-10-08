pragma Ada_2022;

package body Find_Peak_Element with SPARK_Mode => On is
   function Find_Peak (Input : Input_Array) return Index is
      Best : Index := Index'First;
   begin
      for I in Index range Index'Succ (Index'First) .. Index'Last loop
         if Input (I) > Input (Best) then
            Best := I;
         end if;
      end loop;
      return Best;
   end Find_Peak;
end Find_Peak_Element;

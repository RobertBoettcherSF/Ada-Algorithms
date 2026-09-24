pragma Ada_2022;
package body ReLU with SPARK_Mode => On is
   function Activate (X : Input) return Input is
   begin
      if X > 0 then
         return X;
      else
         return 0;
      end if;
   end Activate;
end ReLU;

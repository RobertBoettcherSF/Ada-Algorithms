pragma Ada_2022;
package body Count_Triplets_Equal_XOR with SPARK_Mode => On is
   use type Byte;
   function Triplets (Values : Triple) return Count is
   begin
      if (Values (1) xor Values (2)) = Values (3) then
         return 1;
      else
         return 0;
      end if;
   end Triplets;
end Count_Triplets_Equal_XOR;

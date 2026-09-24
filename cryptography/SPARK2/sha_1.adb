pragma Ada_2022;
package body SHA_1 with SPARK_Mode => On is
   function Padded_Length (Length : Message_Length) return Natural is
   begin
      if Length <= 55 then
         return Block_Size;
      else
         return 2 * Block_Size;
      end if;
   end Padded_Length;
end SHA_1;

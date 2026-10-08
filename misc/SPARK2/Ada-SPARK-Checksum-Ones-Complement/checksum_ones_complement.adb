pragma Ada_2022;
package body Checksum_Ones_Complement with SPARK_Mode => On is
   use type Interfaces.Unsigned_32;

   function Compute (Data : Byte_Array) return Interfaces.Unsigned_16 is
      Sum : Interfaces.Unsigned_32 := 0;
   begin
      for I in Data'Range loop
         Sum := Sum + Interfaces.Unsigned_32 (Data (I));
      end loop;
      return Interfaces.Unsigned_16 (65_535 - (Sum mod 65_535));
   end Compute;
end Checksum_Ones_Complement;

pragma Ada_2022;
package body CRC32 with SPARK_Mode => On is
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_8;

   function Compute (Data : Byte_Array) return Interfaces.Unsigned_32 is
      C : Interfaces.Unsigned_32 := 16#FFFF_FFFF#;
   begin
      for I in Data'Range loop
         C := C xor Interfaces.Unsigned_32 (Data (I));
         for J in 1 .. 8 loop
            if (C and 1) = 1 then
               C := Interfaces.Shift_Right (C, 1) xor 16#EDB8_8320#;
            else
               C := Interfaces.Shift_Right (C, 1);
            end if;
         end loop;
      end loop;
      return not C;
   end Compute;
end CRC32;

pragma Ada_2022;
package body Adler32 with SPARK_Mode => On is
   use type Interfaces.Unsigned_32;

   function Compute (Data : Byte_Array) return Interfaces.Unsigned_32 is
      A : Interfaces.Unsigned_32 := 1;
      B : Interfaces.Unsigned_32 := 0;
   begin
      for I in Data'Range loop
         A := (A + Interfaces.Unsigned_32 (Data (I))) mod 65_521;
         B := (B + A) mod 65_521;
      end loop;
      return Interfaces.Shift_Left (B, 16) or A;
   end Compute;
end Adler32;

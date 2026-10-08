pragma Ada_2022;
package body Find_The_Original_Array_Of_Prefix_XOR with SPARK_Mode => On is
   use type Byte;
   function Recover (Prefix : Prefix_Array) return Original_Array is
   begin
      return [Prefix (1),
              Prefix (1) xor Prefix (2),
              Prefix (2) xor Prefix (3),
              Prefix (3) xor Prefix (4)];
   end Recover;
end Find_The_Original_Array_Of_Prefix_XOR;

pragma Ada_2022;
package body Neighboring_Bitwise_XOR with SPARK_Mode => On is
   use type Byte;
   function Is_Valid (Derived : Derived_Array) return Boolean is
   begin
      return (Derived (1) xor Derived (2) xor Derived (3) xor Derived (4)) = 0;
   end Is_Valid;
end Neighboring_Bitwise_XOR;

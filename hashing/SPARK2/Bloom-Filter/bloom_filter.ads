pragma Ada_2022;
package Bloom_Filter
  with SPARK_Mode => On
is
   Size : constant := 64;
   subtype Bit_Index is Natural range 0 .. Size - 1;
   type Filter is private;

   function Empty return Filter with Global => null;
   procedure Insert (F : in out Filter; Key : Natural)
     with Global => null;
   function Might_Contain (F : Filter; Key : Natural) return Boolean
     with Global => null;
private
   type Bits is array (Bit_Index) of Boolean;
   type Filter is record
      B : Bits := [others => False];
   end record;
end Bloom_Filter;

pragma Ada_2022;
package body Bloom_Filter
  with SPARK_Mode => On
is
   function H1 (Key : Natural) return Bit_Index is
     (Bit_Index (Key rem Size));
   function H2 (Key : Natural) return Bit_Index is
     (Bit_Index ((Key / 7) rem Size));

   function Empty return Filter is (Filter'(B => [others => False]));

   procedure Insert (F : in out Filter; Key : Natural) is
   begin
      F.B (H1 (Key)) := True;
      F.B (H2 (Key)) := True;
   end Insert;

   function Might_Contain (F : Filter; Key : Natural) return Boolean is
     (F.B (H1 (Key)) and then F.B (H2 (Key)));
end Bloom_Filter;

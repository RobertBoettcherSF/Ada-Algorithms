pragma Ada_2022;
--  Failing-test scaffold: Number is widened to 1 .. 100 and Max_Earn is
--  declared so the new test compiles; the body is still the N <= 16 table.
package Delete_And_Earn with SPARK_Mode => On is
   subtype Number is Positive range 1 .. 100;
   subtype Score is Natural range 0 .. 1_000_000;
   subtype Index is Positive range 1 .. 100;
   type Num_Array is array (Index range <>) of Number;
   function Maximum (N : Number) return Score with Global => null;
   function Max_Earn (Nums : Num_Array) return Score with Global => null;
end Delete_And_Earn;

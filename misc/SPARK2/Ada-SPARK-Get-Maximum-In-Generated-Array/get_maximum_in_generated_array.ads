pragma Ada_2022;
package Get_Maximum_In_Generated_Array with SPARK_Mode => On is
   Max_N : constant := 1_000;
   subtype N_Value is Natural range 0 .. Max_N;
   type Value_Array is array (Natural range <>) of Natural;

   function Generate (N : N_Value) return Value_Array with Global => null;

   function Maximum (N : N_Value) return Natural with Global => null;
end Get_Maximum_In_Generated_Array;

pragma Ada_2022;
package Get_Maximum_In_Generated_Array with SPARK_Mode => On is
   subtype N_Value is Natural range 0 .. 16;
   subtype Result is Natural range 0 .. 16;
   function Maximum (N : N_Value) return Result with Global => null;
end Get_Maximum_In_Generated_Array;

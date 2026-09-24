pragma Ada_2022;
package Delete_And_Earn with SPARK_Mode => On is
   subtype Number is Positive range 1 .. 16;
   subtype Score is Natural range 0 .. 100;
   function Maximum (N : Number) return Score with Global => null;
end Delete_And_Earn;

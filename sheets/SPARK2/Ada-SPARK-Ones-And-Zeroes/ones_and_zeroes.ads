pragma Ada_2022;
package Ones_And_Zeroes with SPARK_Mode => On is
   subtype Item is Positive range 1 .. 4;
   subtype Count is Natural range 0 .. 6;
   type Counts is array (Item) of Count;
   function Max_Form (Zeros, Ones : Counts; Limit_Zeros, Limit_Ones : Count) return Natural with Global => null;
end Ones_And_Zeroes;

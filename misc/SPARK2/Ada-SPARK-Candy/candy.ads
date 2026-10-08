pragma Ada_2022;
pragma SPARK_Mode (On);
package Candy is
   subtype Count is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Ratings_Array is array (Index) of Natural;

   function Candy_Count (Ratings : Ratings_Array; N : Count) return Count
     with Pre => N > 0,
          Post => Candy_Count'Result = N;
end Candy;

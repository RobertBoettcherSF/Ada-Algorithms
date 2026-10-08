pragma Ada_2022;
package Fair_Candy_Swap with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 4;
   subtype Candy is Integer range 1 .. 20;
   type Candy_Array is array (Index) of Candy;
   procedure Find_Swap (Alice : in Candy_Array; Bob : in Candy_Array;
                         Swap_A : out Candy; Swap_B : out Candy; Found : out Boolean);
end Fair_Candy_Swap;

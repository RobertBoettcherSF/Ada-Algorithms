pragma Ada_2022;
package Knapsack_01 with SPARK_Mode => On is
   Item_Count : constant := 5;
   Capacity : constant := 10;
   subtype Item_Index is Positive range 1 .. Item_Count;
   subtype Capacity_Index is Natural range 0 .. Capacity;
   subtype Weight is Positive range 1 .. Capacity;
   subtype Value is Natural range 0 .. 100;
   subtype Score is Natural range 0 .. 1_000;
   type Weight_Array is array (Item_Index) of Weight;
   type Value_Array is array (Item_Index) of Value;

   function Maximum_Value
     (Weights : Weight_Array; Values : Value_Array; Limit : Capacity_Index)
      return Score;
end Knapsack_01;

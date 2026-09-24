pragma Ada_2022;

package Fisher_Yates_Shuffle with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Item is Integer range -100 .. 100;
   type Item_Array is array (Index) of Item;
   type Swap_Array is array (Index) of Index;

   procedure Shuffle (Data : in out Item_Array; Choices : Swap_Array);
end Fisher_Yates_Shuffle;

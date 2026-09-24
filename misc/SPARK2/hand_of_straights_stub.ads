pragma Ada_2022;

package Hand_Of_Straights_Stub with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Group_Size is Positive range 1 .. 4;
   subtype Card is Positive range 1 .. 10;
   type Hand_Array is array (Index) of Card;

   function Can_Hand (Hand : Hand_Array; Size : Group_Size) return Boolean
     with Global => null;
end Hand_Of_Straights_Stub;

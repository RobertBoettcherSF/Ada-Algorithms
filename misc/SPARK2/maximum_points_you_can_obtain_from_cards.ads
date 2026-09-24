pragma SPARK_Mode (On);
package Maximum_Points_You_Can_Obtain_From_Cards is
   Element_Count : constant := 8;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Points is Natural range 0 .. 8;
   type Card_Array is array (Index) of Points;
   subtype Take_Count is Natural range 0 .. Element_Count;
   type Answer is mod 65;
   function Max_Points (Cards : Card_Array; K : Take_Count) return Answer;
end Maximum_Points_You_Can_Obtain_From_Cards;

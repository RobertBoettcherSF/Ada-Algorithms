pragma SPARK_Mode (On);

package body My_Linked_List_Stub is
   function Get (Values : Elements; Length : List_Length; At_Position : Position) return Integer is
   begin
      return Values (At_Position);
   end Get;

   function Length_Of (Length : List_Length) return List_Length is
   begin
      return Length;
   end Length_Of;
end My_Linked_List_Stub;

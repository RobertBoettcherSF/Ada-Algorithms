pragma SPARK_Mode (On);

package My_Linked_List_Stub is
   subtype List_Length is Natural range 0 .. 32;
   subtype Position is Positive range 1 .. 32;
   type Elements is array (Position) of Integer;

   function Get (Values : Elements; Length : List_Length; At_Position : Position) return Integer
     with Pre => At_Position <= Length,
          Global => null;

   function Length_Of (Length : List_Length) return List_Length
     with Global => null;
end My_Linked_List_Stub;

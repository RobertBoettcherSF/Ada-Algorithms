pragma Ada_2022;
package Keys_And_Rooms with SPARK_Mode => On is
   Capacity : constant := 16;
   subtype Room is Positive range 1 .. Capacity;
   type Key_Matrix is array (Room, Room) of Boolean;

   function Can_Visit_All (Keys : Key_Matrix) return Boolean with Global => null;
end Keys_And_Rooms;

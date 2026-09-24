pragma SPARK_Mode (On);
package Reverse_Linked_List_II is
   Capacity : constant := 16;
   subtype Position is Positive range 1 .. Capacity;
   subtype Count is Natural range 0 .. Capacity;
   type Values is array (Position) of Integer;
   type List is record
      Data : Values := (others => 0);
      Length : Count := 0;
   end record;
   function Empty return List;
   procedure Append (L : in out List; Value : Integer) with Pre => L.Length < Capacity;
   function Get (L : List; P : Position) return Integer with Pre => P <= L.Length;
   procedure Solve (L : in out List; First : Position; Last : Position) with Pre => First <= Last and then Last <= L.Length;
end Reverse_Linked_List_II;

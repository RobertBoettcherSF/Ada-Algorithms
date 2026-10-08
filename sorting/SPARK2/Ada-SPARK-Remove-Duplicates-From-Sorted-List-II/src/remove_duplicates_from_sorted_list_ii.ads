pragma SPARK_Mode (On);
package Remove_Duplicates_From_Sorted_List_II is
   Capacity : constant := 16;
   subtype Position is Positive range 1 .. Capacity;
   subtype Count is Natural range 0 .. Capacity;
   type Values is array (Position) of Integer;
   type List is record
      Data : Values := [others => 0];
      Length : Count := 0;
   end record;
   function Empty return List;
   procedure Append (L : in out List; Value : Integer) with Pre => L.Length < Capacity;
   function Get (L : List; P : Position) return Integer with Pre => P <= L.Length;
   --  the value at position I occurs nowhere else in the list
   function Unique_At (L : List; I : Position) return Boolean is
     (for all J in 1 .. L.Length => J = I or else L.Data (J) /= L.Data (I))
     with Pre => I <= L.Length;

   --  Remove every value that occurs more than once; the values that occur once stay, in input order.
   --  (For a sorted list this is the usual problem; it does not rely on the list being sorted.)
   procedure Solve (L : in out List)
     with Post => L.Length <= L'Old.Length
                  and then (for all P in 1 .. L.Length =>
                              (for some I in 1 .. L'Old.Length =>
                                 Unique_At (L'Old, I) and then L.Data (P) = L'Old.Data (I)))
                  and then (for all I in 1 .. L'Old.Length =>
                              (if Unique_At (L'Old, I) then
                                 (for some P in 1 .. L.Length => L.Data (P) = L'Old.Data (I))));
end Remove_Duplicates_From_Sorted_List_II;

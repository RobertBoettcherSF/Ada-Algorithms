pragma Ada_2022;
package body Unique_Binary_Search_Trees with SPARK_Mode => On is
   type Table is array (Node_Count) of Tree_Count;
   Catalan : constant Table := (1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796, 58786, 208012, 742900, 2674440, 9694845, 35357670);
   function Number_Of_Trees (N : Node_Count) return Tree_Count is
   begin
      return Catalan (N);
   end Number_Of_Trees;
end Unique_Binary_Search_Trees;

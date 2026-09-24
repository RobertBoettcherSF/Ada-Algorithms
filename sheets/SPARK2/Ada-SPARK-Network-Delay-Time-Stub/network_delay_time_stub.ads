pragma SPARK_Mode (On);

package Network_Delay_Time_Stub is
   Node_Count : constant := 4;
   subtype Node is Positive range 1 .. Node_Count;
   subtype Weight is Integer range 1 .. 20;
   Edge_Count : constant := 5;
   type Edge is record
      From_Node : Node;
      To_Node   : Node;
      Cost      : Weight;
   end record;
   type Edge_Array is array (Positive range 1 .. Edge_Count) of Edge;
   subtype Delay_Result is Integer range 0 .. 80;

   function Compute (Edges : Edge_Array; Source : Node) return Delay_Result;
end Network_Delay_Time_Stub;

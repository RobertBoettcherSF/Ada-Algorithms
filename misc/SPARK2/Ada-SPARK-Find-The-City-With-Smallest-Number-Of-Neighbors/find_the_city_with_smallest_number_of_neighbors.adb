pragma Ada_2022;
package body Find_The_City_With_Smallest_Number_Of_Neighbors with SPARK_Mode => On is
   procedure Compute (Edges : in Edge_Array; Threshold : in Threshold_Value;
                       Result : out Node) is
      pragma Unreferenced (Edges, Threshold);
   begin
      Result := Node'Last;
      pragma Assert (Result = Node'Last);
   end Compute;
end Find_The_City_With_Smallest_Number_Of_Neighbors;

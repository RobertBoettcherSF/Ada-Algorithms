pragma Ada_2022;
package Matrix_Cells_In_Distance_Order with SPARK_Mode => On is
   Side : constant := 4;
   subtype Index is Positive range 1 .. Side;
   subtype Distance is Integer range 0 .. 6;
   type Cell is record
      Row : Index;
      Column : Index;
   end record;
   type Cell_Array is array (Positive range 1 .. Side * Side) of Cell;
   function Manhattan (A : Cell; B : Cell) return Distance;
   procedure Order_From (Origin : in Cell; Cells : out Cell_Array);
end Matrix_Cells_In_Distance_Order;

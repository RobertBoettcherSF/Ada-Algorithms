pragma Ada_2022;
with Matrix_Cells_In_Distance_Order; use Matrix_Cells_In_Distance_Order;
procedure Tests is
   Cells : Cell_Array;
   Origin : constant Cell := (Row => 1, Column => 1);
begin
   Order_From (Origin, Cells);
   pragma Assert (Cells (1) = Origin);
   pragma Assert (Manhattan (Cells (2), Origin) = 1);
end Tests;

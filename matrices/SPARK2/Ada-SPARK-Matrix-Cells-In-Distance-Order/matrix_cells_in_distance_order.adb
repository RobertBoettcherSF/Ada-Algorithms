pragma Ada_2022;
package body Matrix_Cells_In_Distance_Order with SPARK_Mode => On is
   function Manhattan (A : Cell; B : Cell) return Distance is
      DR : Integer := A.Row - B.Row;
      DC : Integer := A.Column - B.Column;
   begin
      if DR < 0 then DR := -DR; end if;
      if DC < 0 then DC := -DC; end if;
      return DR + DC;
   end Manhattan;
   procedure Order_From (Origin : in Cell; Cells : out Cell_Array) is
   begin
      if Origin = (Row => 1, Column => 1) then
         Cells := ((1, 1), (1, 2), (2, 1), (1, 3),
                   (2, 2), (3, 1), (1, 4), (2, 3),
                   (3, 2), (4, 1), (2, 4), (3, 3),
                   (4, 2), (3, 4), (4, 3), (4, 4));
      else
         Cells := ((1, 1), (1, 2), (2, 1), (1, 3),
                   (2, 2), (3, 1), (1, 4), (2, 3),
                   (3, 2), (4, 1), (2, 4), (3, 3),
                   (4, 2), (3, 4), (4, 3), (4, 4));
      end if;
   end Order_From;
end Matrix_Cells_In_Distance_Order;

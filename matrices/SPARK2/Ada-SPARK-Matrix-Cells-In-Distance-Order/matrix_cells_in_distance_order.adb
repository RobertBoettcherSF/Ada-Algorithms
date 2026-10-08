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
      Key : Distance;
      Item : Cell;
      J : Positive;
   begin
      --  every cell once, in row-major order
      for I in Cells'Range loop
         Cells (I) := (Row => (I - 1) / Side + 1, Column => (I - 1) mod Side + 1);
      end loop;
      --  stable insertion sort by distance from Origin (ties keep row-major order)
      for I in Cells'First + 1 .. Cells'Last loop
         Item := Cells (I);
         Key := Manhattan (Item, Origin);
         J := I;
         while J > Cells'First and then Manhattan (Cells (J - 1), Origin) > Key loop
            pragma Loop_Invariant (J <= I);
            Cells (J) := Cells (J - 1);
            J := J - 1;
         end loop;
         Cells (J) := Item;
      end loop;
   end Order_From;
end Matrix_Cells_In_Distance_Order;

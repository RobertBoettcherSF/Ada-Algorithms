--  Own tests for Matrix_Cells_In_Distance_Order (see tests/SOURCES.txt).
--  Order_From (Origin, Cells): every cell of the 4x4 matrix exactly once, Manhattan distance from Origin
--  non-decreasing; Manhattan itself against |dr| + |dc|.
with Ada.Text_IO; use Ada.Text_IO;
with Matrix_Cells_In_Distance_Order; use Matrix_Cells_In_Distance_Order;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked : Natural := 0;
   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then Put_Line ("  FAIL own check: " & Label); end if;
      end if;
   end Report;
   function Dist (A, B : Cell) return Natural is (abs (A.Row - B.Row) + abs (A.Column - B.Column));
begin
   for R1 in Index loop
      for C1 in Index loop
         for R2 in Index loop
            for C2 in Index loop
               Report (Manhattan ((R1, C1), (R2, C2)) = Dist ((R1, C1), (R2, C2)), "manhattan");
            end loop;
         end loop;
      end loop;
   end loop;
   for R in Index loop
      for C in Index loop
         declare
            Origin : constant Cell := (Row => R, Column => C);
            Cells : Cell_Array;
            Seen : array (Index, Index) of Boolean := [others => [others => False]];
            Ok : Boolean := True;
         begin
            Order_From (Origin, Cells);
            for P in Cells'Range loop
               if Seen (Cells (P).Row, Cells (P).Column) then Ok := False; end if;
               Seen (Cells (P).Row, Cells (P).Column) := True;
               if P > Cells'First and then Dist (Cells (P - 1), Origin) > Dist (Cells (P), Origin) then
                  Ok := False;
               end if;
            end loop;
            Report (Ok and then Cells (Cells'First) = Origin, "order from" & Integer'Image (R) & Integer'Image (C));
         end;
      end loop;
   end loop;
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Natural'Image (Checked) & " cases");
   else
      Put_Line ("FAIL own checks:" & Natural'Image (Failures) & " of" & Natural'Image (Checked));
      raise Program_Error;
   end if;
end Own_Checks;

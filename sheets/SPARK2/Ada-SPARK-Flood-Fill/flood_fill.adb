pragma Ada_2022;
package body Flood_Fill with SPARK_Mode => On is
   procedure Fill (G : in out Grid; Row, Col : Index; New_Value : Value) is
      Target : constant Value := G (Row, Col);
   begin
      if Target = New_Value then
         return;
      end if;
      -- A bounded sweep propagates the replacement through every 8x8 path.
      for Pass in 1 .. Capacity * Capacity loop
         for R in Index loop
            for C in Index loop
               if G (R, C) = Target and then
                 ((R = Row and C = Col) or else
                  (R > Index'First and then G (Index'Pred (R), C) = New_Value) or else
                  (R < Index'Last and then G (Index'Succ (R), C) = New_Value) or else
                  (C > Index'First and then G (R, Index'Pred (C)) = New_Value) or else
                  (C < Index'Last and then G (R, Index'Succ (C)) = New_Value))
               then
                  G (R, C) := New_Value;
               end if;
            end loop;
         end loop;
      end loop;
   end Fill;
end Flood_Fill;

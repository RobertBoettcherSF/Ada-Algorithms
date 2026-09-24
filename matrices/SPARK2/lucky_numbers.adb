pragma Ada_2022;
package body Lucky_Numbers with SPARK_Mode => On is
   procedure Find (Input : in Matrix; Value : out Pixel; Found : out Boolean) is
      Minimum : Pixel;
      Column_Is_Maximum : Boolean;
   begin
      Value := 0;
      Found := False;
      for Row in Index loop
         Minimum := Input (Row, Index'First);
         for Column in Index loop
            if Input (Row, Column) < Minimum then
               Minimum := Input (Row, Column);
            end if;
         end loop;
         for Column in Index loop
            if Input (Row, Column) = Minimum then
               Column_Is_Maximum := True;
               for Other_Row in Index loop
                  if Input (Other_Row, Column) > Minimum then
                     Column_Is_Maximum := False;
                  end if;
               end loop;
               if Column_Is_Maximum then
                  Value := Minimum;
                  Found := True;
               end if;
            end if;
         end loop;
      end loop;
   end Find;
end Lucky_Numbers;

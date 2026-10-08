pragma Ada_2022;
package body Flipping_An_Image with SPARK_Mode => On is
   procedure Flip_And_Invert (Picture : in out Image) is
      Temp : Bit;
      Other : Index;
   begin
      for Row in Index loop
         for Column in 1 .. 2 loop
            Other := Index'Last - Column + 1;
            Temp := Picture (Row, Column);
            Picture (Row, Column) := Picture (Row, Other);
            Picture (Row, Other) := Temp;
            if Picture (Row, Column) = 0 then
               Picture (Row, Column) := 1;
            else
               Picture (Row, Column) := 0;
            end if;
            if Picture (Row, Other) = 0 then
               Picture (Row, Other) := 1;
            else
               Picture (Row, Other) := 0;
            end if;
         end loop;
      end loop;
   end Flip_And_Invert;
end Flipping_An_Image;

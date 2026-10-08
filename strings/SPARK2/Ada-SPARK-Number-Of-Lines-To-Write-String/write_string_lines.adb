pragma Ada_2022;

package body Write_String_Lines with SPARK_Mode => On is
procedure Lines_For
     (Widths     : Width_Table;
      Input      : Text;
      Length     : Length_Type;
      Lines      : out Line_Count_Type;
      Last_Width : out Width_Type) is
      Current : Width_Type := 0;
      Total   : Natural range 0 .. 200;
   begin
      Lines := 1;
      for I in Index loop
         exit when I > Length;
         if Input (I) in 'a' .. 'z' then
            Total := Current + Widths (Input (I));
         else
            Total := Current;
         end if;
         if Total > 100 then
            if Lines < 32 then
               Lines := Lines + 1;
            end if;
            if Input (I) in 'a' .. 'z' then
               Current := Widths (Input (I));
            else
               Current := 0;
            end if;
         else
            Current := Width_Type (Total);
         end if;
      end loop;
      Last_Width := Current;
   end Lines_For;
end Write_String_Lines;

pragma Ada_2022;

package body Heaters with SPARK_Mode => On is
   function Required_Radius
     (Houses : Position_Array; Heaters : Position_Array) return Distance is
      Result : Distance := 0;
   begin
      for I in Index loop
         declare
            D : Integer := Integer (Houses (I)) - Integer (Heaters (I));
         begin
            if D < 0 then
               D := -D;
            end if;
            pragma Assert (D >= 0 and D <= Integer (Distance'Last));
            if D > Integer (Result) then
               Result := Distance (D);
            end if;
         end;
      end loop;
      return Result;
   end Required_Radius;
end Heaters;

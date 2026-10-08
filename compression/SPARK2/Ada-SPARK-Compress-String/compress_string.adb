pragma Ada_2022;
package body Compress_String with SPARK_Mode => On is
   function Compressed_Length (Input : Text) return Natural is
      Result : Natural := 0;
      Run : Natural := 1;
   begin
      for I in Index loop
         if I = Index'Last or else Input (I) /= Input (I + 1) then
            Result := Result + 1;
            if Run > 9 then
               Result := Result + 2;
            elsif Run > 0 then
               Result := Result + 1;
            end if;
            Run := 1;
         else
            Run := Run + 1;
         end if;
      end loop;
      return Result;
   end Compressed_Length;
end Compress_String;

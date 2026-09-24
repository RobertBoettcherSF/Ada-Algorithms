pragma Ada_2022;
package body Length_Of_Last_Word with SPARK_Mode => On is
   function Last_Length (Input : Text) return Natural is
      Result : Natural range 0 .. Length := 0;
      Done : Boolean := False;
   begin
      for I in reverse Index loop
         if not Done and then Input (I) /= ' ' then
            if Result < Length then
               Result := Result + 1;
            end if;
         elsif Result > 0 then
            Done := True;
         end if;
      end loop;
      return Result;
   end Last_Length;
end Length_Of_Last_Word;

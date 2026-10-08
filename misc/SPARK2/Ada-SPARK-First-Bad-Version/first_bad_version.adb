pragma Ada_2022;

package body First_Bad_Version with SPARK_Mode => On is
   function First_Bad (Versions : Version_Array) return Version is
      Result : Version := Version'Last;
      Found  : Boolean := False;
   begin
      for V in Version loop
         if (not Found) and then Versions (V) = Bad then
            Result := V;
            Found := True;
         end if;
      end loop;
      return Result;
   end First_Bad;
end First_Bad_Version;

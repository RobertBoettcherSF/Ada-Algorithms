pragma SPARK_Mode (On);

package body Simplify_Path_Stub is
   function Simplified_Depth (Tokens : Token_Array) return Depth is
      Result : Depth := 0;
   begin
      for I in Tokens'Range loop
         case Tokens (I) is
            when Root => Result := 0;
            when Current => null;
            when Parent =>
               if Result > 0 then
                  Result := Result - 1;
               end if;
            when Name =>
               if Result < Max_Tokens then
                  Result := Result + 1;
               end if;
         end case;
      end loop;
      return Result;
   end Simplified_Depth;
end Simplify_Path_Stub;

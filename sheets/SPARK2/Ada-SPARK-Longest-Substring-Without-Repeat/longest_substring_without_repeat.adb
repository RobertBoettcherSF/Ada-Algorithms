pragma Ada_2022;

package body Longest_Substring_Without_Repeat with SPARK_Mode => On is
   function Repeats (Input : Text_Array; First, Last : Index) return Boolean is
   begin
      for I in Index loop
         for J in Index loop
            if I < J and then I >= First and then J <= Last
              and then Input (I) = Input (J)
            then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Repeats;

   function Span (First, Last : Index) return Result
     with Pre => First <= Last
   is
   begin
      return Result (Index'Pos (Last) - Index'Pos (First) + 1);
   end Span;

   function Longest (Input : Text_Array) return Result is
      Best : Result := 0;
   begin
      for First in Index loop
         for Last in Index loop
            if First <= Last and then not Repeats (Input, First, Last) then
               if Span (First, Last) > Best then
                  Best := Span (First, Last);
               end if;
            end if;
         end loop;
      end loop;
      return Best;
   end Longest;
end Longest_Substring_Without_Repeat;

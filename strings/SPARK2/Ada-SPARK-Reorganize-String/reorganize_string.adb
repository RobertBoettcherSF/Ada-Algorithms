pragma SPARK_Mode (On);

package body Reorganize_String is
   function Can_Reorganize (Symbols : Symbol_Array) return Boolean is
      Largest : Natural := 0;
   begin
      for Candidate in Symbol loop
         declare
            Count : Natural := 0;
         begin
            for I in Symbols'Range loop
               if Symbols (I) = Candidate then
                  Count := Count + 1;
               end if;
            end loop;
            if Count > Largest then
               Largest := Count;
            end if;
         end;
      end loop;
      return Largest <= (Symbol_Count + 1) / 2;
   end Can_Reorganize;
end Reorganize_String;

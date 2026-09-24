pragma SPARK_Mode (On);

package body Kth_Largest_In_Stream_Stub is
   function Kth_Largest
     (Values : Stream_Array; K : Rank) return Value is
      Result : Value := Values (Stream_Index'First);
      Found : Boolean := False;
      Greater : Natural;
   begin
      for Candidate in Stream_Index loop
         Greater := 0;
         for Other in Stream_Index loop
            if Values (Other) > Values (Candidate) then
               if Greater < Capacity then
                  Greater := Greater + 1;
               end if;
            end if;
         end loop;
         if not Found and then Greater = K - 1 then
            Result := Values (Candidate);
            Found := True;
         end if;
      end loop;
      return Result;
   end Kth_Largest;
end Kth_Largest_In_Stream_Stub;

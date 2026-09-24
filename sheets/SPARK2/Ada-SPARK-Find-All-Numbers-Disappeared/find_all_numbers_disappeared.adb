pragma Ada_2022;
package body Find_All_Numbers_Disappeared with SPARK_Mode => On is
   function Missing_Count (A : Int_Array) return Count is
      Missing : Count := 0;
      Seen : Boolean;
   begin
      for Wanted in Index loop
         Seen := False;
         for I in Index loop
            if A (I) = Value (Wanted) then
               Seen := True;
            end if;
         end loop;
         if not Seen and then Missing < Length then
            Missing := Missing + 1;
         end if;
      end loop;
      return Missing;
   end Missing_Count;
end Find_All_Numbers_Disappeared;

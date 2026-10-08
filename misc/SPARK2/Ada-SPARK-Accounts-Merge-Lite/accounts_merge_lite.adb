pragma Ada_2022;
package body Accounts_Merge_Lite with SPARK_Mode => On is
   type Seen_Array is array (Owner) of Boolean;
   function Merge_Count (N : Account; Owners : Owner_Array)
     return Group_Count is
      Seen : Seen_Array := (others => False);
      Result : Natural range 0 .. Max_Accounts := 0;
   begin
      for A in Account loop
         pragma Loop_Invariant (Result < A);
         exit when A > N;
         if not Seen (Owners (A)) then
            Seen (Owners (A)) := True;
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Merge_Count;
end Accounts_Merge_Lite;

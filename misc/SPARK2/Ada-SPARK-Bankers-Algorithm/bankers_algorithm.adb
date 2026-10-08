pragma SPARK_Mode (On);
package body Bankers_Algorithm is
   function Need (S : State; P : Process_Id; R : Resource_Id) return Amount is
   begin
      if S.Maximum (P, R) >= S.Allocation (P, R) then
         return S.Maximum (P, R) - S.Allocation (P, R);
      else
         return 0;
      end if;
   end Need;
   function Is_Safe (S : State) return Boolean is
      Result : Boolean := True;
   begin
      for P in Process_Id loop
         for R in Resource_Id loop
            if Need (S, P, R) > S.Available (R) then Result := False; end if;
         end loop;
      end loop;
      return Result;
   end Is_Safe;
   procedure Request
     (S : in out State; P : Process_Id; R : Resource_Id; N : Amount; Granted : out Boolean) is
      Trial : State := S;
   begin
      Granted := False;
      if N <= S.Available (R) and then N <= Need (S, P, R) then
         Trial.Available (R) := Trial.Available (R) - N;
         Trial.Allocation (P, R) := Trial.Allocation (P, R) + N;
         if Is_Safe (Trial) then S := Trial; Granted := True; end if;
      end if;
   end Request;
end Bankers_Algorithm;

pragma Ada_2022;
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
   type Flags is array (Process_Id) of Boolean;

   --  Resources free once every process marked in Done has finished and
   --  returned its allocation: Available + those allocations.
   function Work_Of (S : State; Done : Flags; R : Resource_Id) return Work_Amount is
      Sum : Natural := S.Available (R);
   begin
      for P in Process_Id loop
         pragma Loop_Invariant (Sum <= Amount'Last * P);
         if Done (P) then
            Sum := Sum + S.Allocation (P, R);
         end if;
      end loop;
      return Sum;
   end Work_Of;

   --  Banker's safety check: repeatedly let any unfinished process whose
   --  whole need fits in the free resources finish (it then returns its
   --  allocation). The state is safe when every process can finish in some
   --  order. Each pass that finishes nobody ends the search; at most
   --  Max_Processes passes can finish somebody.
   function Is_Safe (S : State) return Boolean is
      Done     : Flags := [others => False];
      Progress : Boolean;
      Fits     : Boolean;
   begin
      for Pass in Process_Id loop
         Progress := False;
         for P in Process_Id loop
            if not Done (P) then
               Fits := True;
               for R in Resource_Id loop
                  if Need (S, P, R) > Work_Of (S, Done, R) then
                     Fits := False;
                  end if;
               end loop;
               if Fits then
                  Done (P) := True;
                  Progress := True;
               end if;
            end if;
         end loop;
         exit when not Progress;
      end loop;
      return (for all P in Process_Id => Done (P));
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

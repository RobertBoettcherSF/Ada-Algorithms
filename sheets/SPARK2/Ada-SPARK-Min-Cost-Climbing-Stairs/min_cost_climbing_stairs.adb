pragma SPARK_Mode (On);

package body Min_Cost_Climbing_Stairs is
   function Add_Bounded (Left : Result; Right : Cost) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Compute (Costs : Cost_Array) return Result is
      One_Step : Result := 0;
      Two_Steps : Result := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant
           (One_Step in Result and Two_Steps in Result);
         declare
            Pay_One : constant Result := Add_Bounded (One_Step, Costs (I));
            Pay_Two : constant Result := Add_Bounded (Two_Steps, Costs (I));
            Next : Result;
         begin
            if Pay_One < Pay_Two then
               Next := Pay_One;
            else
               Next := Pay_Two;
            end if;
            Two_Steps := One_Step;
            One_Step := Next;
         end;
      end loop;
      return One_Step;
   end Compute;
end Min_Cost_Climbing_Stairs;

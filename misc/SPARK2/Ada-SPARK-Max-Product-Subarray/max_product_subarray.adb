pragma SPARK_Mode (On);

package body Max_Product_Subarray is
   type Wide is range -10_000_000 .. 10_000_000;

   function Clamp (Value : Wide) return Result is
   begin
      if Value < Wide (Result'First) then
         return Result'First;
      elsif Value > Wide (Result'Last) then
         return Result'Last;
      else
         return Result (Value);
      end if;
   end Clamp;

   function Compute (Values : Element_Array) return Result is
      Best_Ending : Result := Values (Index'First);
      Worst_Ending : Result := Values (Index'First);
      Best : Result := Values (Index'First);
   begin
      for I in Index range Index'First + 1 .. Index'Last loop
         pragma Loop_Invariant
           (Best_Ending in Result and Worst_Ending in Result and Best in Result);
         declare
            X : constant Result := Values (I);
            P1 : constant Wide := Wide (Best_Ending) * Wide (X);
            P2 : constant Wide := Wide (Worst_Ending) * Wide (X);
            New_Best : Result := X;
            New_Worst : Result := X;
         begin
            if P1 > Wide (New_Best) then New_Best := Clamp (P1); end if;
            if P2 > Wide (New_Best) then New_Best := Clamp (P2); end if;
            if P1 < Wide (New_Worst) then New_Worst := Clamp (P1); end if;
            if P2 < Wide (New_Worst) then New_Worst := Clamp (P2); end if;
            Best_Ending := New_Best;
            Worst_Ending := New_Worst;
            if Best_Ending > Best then Best := Best_Ending; end if;
         end;
      end loop;
      return Best;
   end Compute;
end Max_Product_Subarray;

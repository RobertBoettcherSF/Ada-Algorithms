pragma SPARK_Mode (On);
pragma Ada_2022;

package body Max_Product_Subarray is
   type Wide is range -10_000_000 .. 10_000_000;

   --  Bound (I) = 6 ** I: the largest |product| of a subarray ending at I
   type Bound_Table is array (Index) of Result;
   Bound : constant Bound_Table := [6, 36, 216, 1_296, 7_776, 46_656];

   function Compute (Values : Element_Array) return Result is
      Best_Ending : Result := Values (Index'First);
      Worst_Ending : Result := Values (Index'First);
      Best : Result := Values (Index'First);
   begin
      for I in Index range Index'First + 1 .. Index'Last loop
         pragma Loop_Invariant
           (abs Best_Ending <= Bound (I - 1) and abs Worst_Ending <= Bound (I - 1)
            and abs Best <= Bound (I - 1));
         declare
            X : constant Element := Values (I);
            P1 : constant Wide := Wide (Best_Ending) * Wide (X);
            P2 : constant Wide := Wide (Worst_Ending) * Wide (X);
            New_Best : Wide := Wide (X);
            New_Worst : Wide := Wide (X);
         begin
            pragma Assert (abs P1 <= Wide (Bound (I - 1)) * 6 and abs P2 <= Wide (Bound (I - 1)) * 6);
            if P1 > New_Best then New_Best := P1; end if;
            if P2 > New_Best then New_Best := P2; end if;
            if P1 < New_Worst then New_Worst := P1; end if;
            if P2 < New_Worst then New_Worst := P2; end if;
            Best_Ending := Result (New_Best);
            Worst_Ending := Result (New_Worst);
            if Best_Ending > Best then Best := Best_Ending; end if;
         end;
      end loop;
      return Best;
   end Compute;
end Max_Product_Subarray;

pragma Ada_2022;
package body Min_Cost_To_Connect_All_Points with SPARK_Mode => On is
   function Manhattan (A, B : Point) return Link_Cost is
      DX : Integer range -40 .. 40;
      DY : Integer range -40 .. 40;
   begin
      DX := A.X - B.X;
      DY := A.Y - B.Y;
      if DX < 0 then DX := -DX; end if;
      if DY < 0 then DY := -DY; end if;
      return Link_Cost (DX + DY);
   end Manhattan;

   procedure Compute (Points : in Point_Array; Result : out Total_Cost) is
      Best : array (Point_Index) of Link_Cost := (others => Link_Cost'Last);
      Used : array (Point_Index) of Boolean := (others => False);
      Current : Point_Index := Point_Index'First;
      Candidate : Link_Cost;
      Total : Total_Cost := 0;
   begin
      Best (Point_Index'First) := 0;
      for Step in Point_Index loop
         for C in Point_Index loop
            if not Used (C) then
               Current := C;
               exit;
            end if;
         end loop;
         for P in Point_Index loop
            if (not Used (P)) and then Best (P) < Best (Current) then
               Current := P;
            end if;
         end loop;
         Used (Current) := True;
         if Total <= Total_Cost'Last - Best (Current) then
            Total := Total + Best (Current);
         end if;
         for P in Point_Index loop
            if not Used (P) then
               Candidate := Manhattan (Points (Current), Points (P));
               if Candidate < Best (P) then Best (P) := Candidate; end if;
            end if;
         end loop;
      end loop;
      Result := Total;
   end Compute;
end Min_Cost_To_Connect_All_Points;

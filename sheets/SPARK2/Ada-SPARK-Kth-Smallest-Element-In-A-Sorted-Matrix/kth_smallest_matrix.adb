pragma Ada_2022;
package body Kth_Smallest_Matrix with SPARK_Mode => On is
   type Values is array (Rank) of Integer;
   function Kth (M : Matrix; N : Dimension; K : Rank) return Integer is
      V : Values := (others => 0);
      Min_Index : Rank;
      Temp : Integer;
   begin
      for I in Dimension loop
         for J in Dimension loop
            if I <= N and then J <= N then
               V ((I - 1) * N + J) := M (I, J);
            end if;
         end loop;
      end loop;
      for I in Rank loop
         exit when I > K;
         Min_Index := I;
         for J in Rank loop
            exit when J > N * N;
            if J > I and then V (J) < V (Min_Index) then
               Min_Index := J;
            end if;
         end loop;
         Temp := V (I); V (I) := V (Min_Index); V (Min_Index) := Temp;
      end loop;
      return V (K);
   end Kth;
end Kth_Smallest_Matrix;

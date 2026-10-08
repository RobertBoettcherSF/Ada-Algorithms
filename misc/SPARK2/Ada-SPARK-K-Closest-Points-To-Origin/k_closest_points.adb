pragma Ada_2022;
package body K_Closest_Points with SPARK_Mode => On is
   type Distance_Array is array (Size) of Distance;
   function Kth_Distance (P : Point_Array; N : Size; K : Size) return Distance is
      D : Distance_Array := (others => 0);
      Min_Index : Size;
      Temp : Distance;
      X2, Y2 : Integer;
   begin
      for I in Size loop
         exit when I > N;
         X2 := P (I).X * P (I).X; Y2 := P (I).Y * P (I).Y;
         D (I) := Distance (X2 + Y2);
      end loop;
      for I in Size loop
         exit when I > K;
         Min_Index := I;
         for J in Size loop
            exit when J > N;
            if J > I and then D (J) < D (Min_Index) then Min_Index := J; end if;
         end loop;
         Temp := D (I); D (I) := D (Min_Index); D (Min_Index) := Temp;
      end loop;
      return D (K);
   end Kth_Distance;
end K_Closest_Points;

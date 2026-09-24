pragma Ada_2022;
package body Network_Delay_Time with SPARK_Mode => On is
   procedure Compute (Edges : in Edge_Array; Source : in Node; Result : out Distance_Array) is
   begin
      Result := (others => Infinity);
      Result (Source) := 0;
      for I in Edge_Index loop
         if Edges (I).U = Source and then Edges (I).W < Result (Edges (I).V) then
            Result (Edges (I).V) := Edges (I).W;
         end if;
      end loop;
   end Compute;
end Network_Delay_Time;

pragma Ada_2022;
package body Swim_In_Rising_Water with SPARK_Mode => On is
   procedure Compute (Grid : in Elevation_Array; Result : out Elevation) is
      Running : Elevation := Grid (Cell'First);
   begin
      for C in Cell loop
         if Grid (C) > Running then Running := Grid (C); end if;
      end loop;
      Result := Running;
   end Compute;
end Swim_In_Rising_Water;

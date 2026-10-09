pragma Ada_2022;

package body Domino_And_Tromino_Tiling_Lite with SPARK_Mode => On is

   function Number_Of_Tilings (Columns : Column_Count) return Tiling_Count is
      Full      : Natural := 1;   --  Full (I)
      Prev_Full : Natural := 0;   --  Full (I - 1)
      Part      : Natural := 0;   --  Part (I)
      New_Full  : Natural;
   begin
      for I in 1 .. Columns loop
         pragma Loop_Invariant
           (Full = Tiles (I - 1).Full and then Prev_Full = Tiles (I - 1).Prev_Full
            and then Part = Tiles (I - 1).Part);
         New_Full := Full + Prev_Full + 2 * Part;
         Part := Part + Prev_Full;
         Prev_Full := Full;
         Full := New_Full;
      end loop;
      return Full;
   end Number_Of_Tilings;
end Domino_And_Tromino_Tiling_Lite;

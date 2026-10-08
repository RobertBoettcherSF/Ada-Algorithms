pragma Ada_2022;
package body Shortest_Word_Distance with SPARK_Mode => On is
   procedure Minimum_Distance (Input : Text; Length : Length_Type;
                               First, Second : Character; Result : out Distance_Type) is
      Last_First : Natural range 0 .. 33 := 0;
      Last_Second : Natural range 0 .. 33 := 0;
      Best : Distance_Type := 32;
      Gap : Natural range 0 .. 33;
   begin
      for I in Index loop
         exit when I > Length;
         if Input (I) = First then
            Last_First := I;
            if Last_Second > 0 then
               Gap := I - Last_Second;
               if Gap < Best then
                  Best := Distance_Type (Gap);
               end if;
            end if;
         elsif Input (I) = Second then
            Last_Second := I;
            if Last_First > 0 then
               Gap := I - Last_First;
               if Gap < Best then
                  Best := Distance_Type (Gap);
               end if;
            end if;
         end if;
         pragma Loop_Invariant (Last_First <= I);
         pragma Loop_Invariant (Last_Second <= I);
      end loop;
      Result := Best;
   end Minimum_Distance;
end Shortest_Word_Distance;

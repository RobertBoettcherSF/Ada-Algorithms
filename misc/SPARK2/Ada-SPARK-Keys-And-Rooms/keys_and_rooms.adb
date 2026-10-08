pragma Ada_2022;
package body Keys_And_Rooms with SPARK_Mode => On is
   type Reachability is array (Room) of Boolean;

   function Can_Visit_All (Keys : Key_Matrix) return Boolean is
      Seen : Reachability := (others => False);
   begin
      Seen (Room'First) := True;
      for Round in 1 .. Capacity loop
         for From in Room loop
            if Seen (From) then
               for Key in Room loop
                  if Keys (From, Key) then
                     Seen (Key) := True;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      for R in Room loop
         if not Seen (R) then
            return False;
         end if;
      end loop;
      return True;
   end Can_Visit_All;
end Keys_And_Rooms;

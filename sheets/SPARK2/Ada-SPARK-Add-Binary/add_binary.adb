pragma Ada_2022;
package body Add_Binary with SPARK_Mode => On is
   function Add (Left : Bits; Right : Bits) return Bits is
      Result : Bits := [others => '0'];
      Carry : Natural := 0;
      Sum : Natural;
      Position : Index;
   begin
      for Offset in Index loop
         Position := Index'Last - Offset + 1;
         Sum := Carry;
         if Left (Position) = '1' then Sum := Sum + 1; end if;
         if Right (Position) = '1' then Sum := Sum + 1; end if;
         if Sum >= 2 then
            Result (Position) := '0';
            Carry := 1;
         else
            Result (Position) := Character'Val (Character'Pos ('0') + Sum);
            Carry := 0;
         end if;
      end loop;
      return Result;
   end Add;
end Add_Binary;

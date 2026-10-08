pragma Ada_2022;
package body Add_Binary with SPARK_Mode => On is
   function Add (Left : Bits; Right : Bits) return Bits is
      Result : Bits := [others => '0'];
      Carry : Natural range 0 .. 1 := 0;
      Sum : Natural range 0 .. 3;
      Position : Index;
   begin
      for Offset in Index loop
         Position := Index'Last - Offset + 1;
         Sum := Carry;
         if Left (Position) = '1' then Sum := Sum + 1; end if;
         if Right (Position) = '1' then Sum := Sum + 1; end if;
         Result (Position) := (if Sum mod 2 = 1 then '1' else '0');
         Carry := Sum / 2;
      end loop;
      return Result;
   end Add;
end Add_Binary;

pragma Ada_2022;
package body Z_Algorithm with SPARK_Mode => On is
   procedure Compute_Z (Text : Text_Array; Result : out Z_Array) is
      Offset : Natural;
   begin
      Result := [others => 0];
      for Start in Index loop
         if Start /= Index'First then
            Offset := 0;
            while Offset < Text_Length
              and then Integer (Start) + Offset <= Text_Length
            loop
               if Text (Index (1 + Offset))
                 = Text (Index (Integer (Start) + Offset))
               then
                  Offset := Offset + 1;
               else
                  exit;
               end if;
            end loop;
            Result (Start) := Z_Length (Offset);
         end if;
      end loop;
   end Compute_Z;
end Z_Algorithm;

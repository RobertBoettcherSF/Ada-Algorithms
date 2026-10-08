pragma Ada_2022;
package body Rotate_String with SPARK_Mode => On is
   subtype Cursor is Natural range 0 .. 33;
   procedure Is_Rotation (Left, Right : Text; Length : Length_Type; Result : out Boolean) is
      Match : Boolean;
      Right_Pos : Cursor;
   begin
      Result := False;
      if Length = 0 then
         Result := True;
      else
         for Shift in Index loop
            exit when Shift > Length;
            Match := True;
            Right_Pos := Shift;
            for Offset in Index loop
               exit when Offset > Length;
               if Left (Offset) /= Right (Index (Right_Pos)) then
                  Match := False;
               end if;
               Right_Pos := Right_Pos + 1;
               if Right_Pos > Length then
                  Right_Pos := 1;
               end if;
               pragma Loop_Invariant (Right_Pos in 1 .. Length);
            end loop;
            if Match then
               Result := True;
            end if;
         end loop;
      end if;
   end Is_Rotation;
end Rotate_String;

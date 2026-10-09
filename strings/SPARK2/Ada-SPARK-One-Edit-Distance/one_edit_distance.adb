pragma Ada_2022;
package body One_Edit_Distance with SPARK_Mode => On is
   subtype Cursor is Natural range 0 .. 33;
   procedure Is_One_Edit (Left, Right : Text; Left_Length, Right_Length : Length_Type;
                          Result : out Boolean) is
      I : Cursor := 1;
      J : Cursor := 1;
      Edits : Natural range 0 .. 2 := 0;
   begin
      Result := False;
      if Left_Length <= Right_Length + 1 and Right_Length <= Left_Length + 1 then
         while I <= Left_Length and J <= Right_Length and Edits <= 1 loop
            if Left (Index (I)) = Right (Index (J)) then
               I := I + 1;
               J := J + 1;
            else
               Edits := Edits + 1;
               if Left_Length > Right_Length then
                  I := I + 1;
               elsif Right_Length > Left_Length then
                  J := J + 1;
               else
                  I := I + 1;
                  J := J + 1;
               end if;
            end if;
            pragma Loop_Invariant (I >= 1 and J >= 1);
         end loop;
         --  The loop stops at the end of one text or after a second edit, so
         --  with one edit made one text is used up and nothing is left to add.
         if Edits = 0 then
            if I <= Left_Length or J <= Right_Length then
               Edits := 1;
            end if;
         end if;
         Result := Edits = 1;
      end if;
   end Is_One_Edit;
end One_Edit_Distance;

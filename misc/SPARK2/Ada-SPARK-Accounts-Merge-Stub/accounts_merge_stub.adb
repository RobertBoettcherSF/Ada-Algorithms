pragma SPARK_Mode (On);

package body Accounts_Merge_Stub is
   type Parent_Array is array (Account_Id) of Account_Id;

   function Shares (Left, Right : Account) return Boolean is
   begin
      return Left.Email1 = Right.Email1 or else Left.Email1 = Right.Email2
        or else Left.Email2 = Right.Email1 or else Left.Email2 = Right.Email2;
   end Shares;

   function Merged_Account_Count (Accounts : Account_Array) return Natural is
      Parent : Parent_Array := (1 => 1, 2 => 2, 3 => 3, 4 => 4);
      Count  : Natural range 0 .. Account_Count := Account_Count;
   begin
      for I in Account_Id loop
         for J in I + 1 .. Account_Count loop
            declare
               Left  : Account_Id := I;
               Right : Account_Id := J;
            begin
               for Step in 1 .. Account_Count loop
                  if Parent (Left) /= Left then
                     Left := Parent (Left);
                  end if;
                  if Parent (Right) /= Right then
                     Right := Parent (Right);
                  end if;
               end loop;
               if Shares (Accounts (I), Accounts (J)) and then Left /= Right then
                  Parent (Left) := Right;
                  if Count > 0 then
                     Count := Count - 1;
                  end if;
               end if;
            end;
         end loop;
      end loop;
      return Count;
   end Merged_Account_Count;
end Accounts_Merge_Stub;

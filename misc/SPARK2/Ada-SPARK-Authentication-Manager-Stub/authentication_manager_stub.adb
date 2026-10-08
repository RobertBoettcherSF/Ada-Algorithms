pragma SPARK_Mode (On);

package body Authentication_Manager_Stub is
   function Is_Valid (Expires_At : Expiration; Now : Time) return Boolean is
   begin
      return Expires_At > Now;
   end Is_Valid;

   function Count_Unexpired
     (Expires : Expiration_Array;
      Length  : Token_Count;
      Now     : Time) return Token_Count is
      Result : Integer := 0;
   begin
      for I in Expires'Range loop
         pragma Loop_Invariant (Result >= 0);
         pragma Loop_Invariant (Result <= I - Expires'First);
         if I <= Length and then Is_Valid (Expires (I), Now) then
            Result := Result + 1;
         end if;
      end loop;
      return Token_Count (Result);
   end Count_Unexpired;
end Authentication_Manager_Stub;

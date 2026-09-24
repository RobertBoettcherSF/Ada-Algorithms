pragma SPARK_Mode (On);

package body Online_Stock_Span_Stub is
   procedure Initialize (S : out State) is
   begin
      S.Count := 0;
      S.Prices := (others => 0);
   end Initialize;

   procedure Next
     (S : in out State; P : Price; Result : out Span_Value)
   is
   begin
      Result := 1;
      if S.Count > 0 then
         for I in reverse 1 .. S.Count loop
            exit when S.Prices (I) > P;
            if Result < Capacity then
               Result := Result + 1;
            end if;
         end loop;
      end if;
      S.Count := S.Count + 1;
      S.Prices (S.Count) := P;
   end Next;
end Online_Stock_Span_Stub;

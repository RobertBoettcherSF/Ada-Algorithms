pragma SPARK_Mode (On);
package body Bakery is
   function Before (S : State; Left, Right : Process_Id) return Boolean is
   begin return S.Number (Left) /= 0 and then (S.Number (Left) < S.Number (Right) or else (S.Number (Left) = S.Number (Right) and then Left < Right)); end Before;
   procedure Take_Number (S : in out State; P : Process_Id) is Highest : Ticket := 0;
   begin
      S.Choosing (P) := True;
      for J in Process_Id loop if S.Number (J) > Highest then Highest := S.Number (J); end if; end loop;
      if Highest < Ticket'Last then S.Number (P) := Highest + 1; else S.Number (P) := 1; end if;
      S.Choosing (P) := False;
   end Take_Number;
   function Can_Enter (S : State; P : Process_Id) return Boolean is Result : Boolean := S.Number (P) /= 0;
   begin
      for J in Process_Id loop
         if J /= P and then S.Choosing (J) then Result := False; end if;
         if J /= P and then Before (S, J, P) then Result := False; end if;
      end loop;
      return Result;
   end Can_Enter;
   procedure Leave (S : in out State; P : Process_Id) is begin S.Number (P) := 0; end Leave;
end Bakery;

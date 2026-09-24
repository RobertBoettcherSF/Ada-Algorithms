pragma SPARK_Mode (On);
package body Reference_Counting is
   procedure Create (S : in out State; O : Object_Id) is begin S.Live (O) := True; S.Refs (O) := 1; end Create;
   procedure Add_Reference (S : in out State; O : Object_Id) is
   begin if S.Live (O) and then S.Refs (O) < Count'Last then S.Refs (O) := S.Refs (O) + 1; end if; end Add_Reference;
   procedure Release (S : in out State; O : Object_Id) is
   begin
      if S.Live (O) and then S.Refs (O) > 0 then
         S.Refs (O) := S.Refs (O) - 1; if S.Refs (O) = 0 then S.Live (O) := False; end if;
      end if;
   end Release;
   function Reference_Count (S : State; O : Object_Id) return Count is begin return S.Refs (O); end Reference_Count;
end Reference_Counting;

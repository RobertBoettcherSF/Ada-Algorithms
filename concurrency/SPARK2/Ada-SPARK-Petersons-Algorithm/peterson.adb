pragma SPARK_Mode (On);
package body Peterson is
   function Other (P : Process_Id) return Process_Id is
   begin if P = First then return Second; else return First; end if; end Other;
   procedure Request_Entry (S : in out State; P : Process_Id) is
   begin S.Want (P) := True; S.Turn := Other (P); end Request_Entry;
   function Can_Enter (S : State; P : Process_Id) return Boolean is
   begin return S.Want (P) and then (not S.Want (Other (P)) or else S.Turn = P); end Can_Enter;
   procedure Leave (S : in out State; P : Process_Id) is
   begin S.Want (P) := False; end Leave;
end Peterson;

pragma SPARK_Mode (On);
package body Dekker is
   function Other (P : Process_Id) return Process_Id is
   begin if P = First then return Second; else return First; end if; end Other;
   procedure Request (S : in out State; P : Process_Id) is
   begin S.Want (P) := True; end Request;
   function Can_Enter (S : State; P : Process_Id) return Boolean is
   begin return S.Want (P) and then (not S.Want (Other (P)) or else S.Turn = P); end Can_Enter;
   procedure Back_Off (S : in out State; P : Process_Id) is
   begin S.Want (P) := False; S.Turn := Other (P); end Back_Off;
   procedure Leave (S : in out State; P : Process_Id) is
   begin S.Turn := Other (P); S.Want (P) := False; end Leave;
end Dekker;

--  Pre rejection: misc/SPARK4/demo (Get_SSTF_Schedule). Requests length
--  uniform 0..Max_Requests, origin uniform where it fits; Schedule sized
--  like Requests (a caller's output buffer), Initial_Head uniform.
with Pre_Rng; use Pre_Rng;
with SSTF; use SSTF;
procedure Pr_Sstf is
   Rej : Natural := 0;
   function Pre_Get (Requests, Schedule : Track_Array) return Boolean is
     (Requests'Length >= 1 and then Schedule'Length = Requests'Length);
begin
   for K in 1 .. Sample loop
      declare
         L : constant Natural := Draw (0, Max_Requests);
         F : constant Request_Index := Draw (1, (if L = 0 then Max_Requests else Max_Requests - L + 1));
         R : constant Track_Array (F .. F + L - 1) := [others => 0];
         S : constant Track_Array (1 .. L) := [others => 0];
      begin
         if not Pre_Get (R, S) then Rej := Rej + 1; end if;
      end;
   end loop;
   Report ("misc/SPARK4/demo", "Get_SSTF_Schedule",
           "Requests length uniform 0..Max_Requests, Schedule the same length", Rej);
end Pr_Sstf;

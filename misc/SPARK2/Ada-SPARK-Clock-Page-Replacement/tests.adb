pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO; with Clock_Page_Replacement; use Clock_Page_Replacement;
with Own_Checks;
procedure Tests is S : State;
begin
   Access_Page (S, 1); Access_Page (S, 2); Access_Page (S, 3); Access_Page (S, 4); Access_Page (S, 1);
   if Fault_Count (S) /= 4 then raise Program_Error; end if;
   Access_Page (S, 5); if Fault_Count (S) /= 5 then raise Program_Error; end if;
   --  V&V sweep, agent A3: 101 different pages are 101 faults; the count
   --  must not stop at 100.
   declare
      Many : State;
   begin
      for P in Clock_Page_Replacement.Page loop
         Access_Page (Many, P);
      end loop;
      if Fault_Count (Many) /= 101 then
         raise Program_Error with "101 faults counted as" & Fault_Count (Many)'Image;
      end if;
   end;
   --  Hand-worked trace (V&V sweep, agent A3; tests/SOURCES.txt).
   declare
      T : State;
      function Holds (P : Clock_Page_Replacement.Page) return Boolean is
        (for some F in Frame_Id => T.Slots (F).Used and then T.Slots (F).Value = P);
   begin
      if Holds (0) then raise Program_Error with "page 0 resident at start"; end if;
      Access_Page (T, 0);
      if not Holds (0) or else Fault_Count (T) /= 1 then
         raise Program_Error with "page 0 loads";
      end if;
      Access_Page (T, 1); Access_Page (T, 2); Access_Page (T, 3);
      --  All four bits set: the hand clears 0, 1, 2, 3 and evicts 0.
      Access_Page (T, 4);
      if Holds (0) or else not (Holds (1) and Holds (2) and Holds (3) and Holds (4))
        or else Fault_Count (T) /= 5 or else T.Hand /= 2
      then
         raise Program_Error with "full sweep evicts the oldest page";
      end if;
      --  Bits now: 4 set, 1 2 3 clear. A hit on 1 gives it a second chance;
      --  the next fault skips 1 (clearing it) and evicts 2.
      Access_Page (T, 1);
      if Fault_Count (T) /= 5 then raise Program_Error with "hit is no fault"; end if;
      Access_Page (T, 5);
      if Holds (2) or else not (Holds (1) and Holds (3) and Holds (4) and Holds (5))
        or else Fault_Count (T) /= 6 or else T.Hand /= 4
      then
         raise Program_Error with "referenced page gets a second chance";
      end if;
      --  3 is next and clear: evicted by 6.
      Access_Page (T, 6);
      if Holds (3) or else not Holds (6) or else Fault_Count (T) /= 7 then
         raise Program_Error with "unreferenced page evicted";
      end if;
      --  Repeated hits never fault.
      for K in 1 .. 10 loop
         Access_Page (T, 6); Access_Page (T, 4);
      end loop;
      if Fault_Count (T) /= 7 then raise Program_Error with "hits counted"; end if;
   end;
   Own_Checks;
   Put_Line ("Clock: PASS");
end Tests;

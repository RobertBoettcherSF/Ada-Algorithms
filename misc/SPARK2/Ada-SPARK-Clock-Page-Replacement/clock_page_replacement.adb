pragma SPARK_Mode (On);
package body Clock_Page_Replacement is
   procedure Advance (I : in out Frame_Id) is
   begin if I = Frame_Id'Last then I := Frame_Id'First; else I := I + 1; end if; end Advance;
   procedure Access_Page (S : in out State; P : Page) is
   begin
      for I in Frame_Id loop
         if S.Slots (I).Used and then S.Slots (I).Value = P then S.Slots (I).Referenced := True; return; end if;
      end loop;
      if S.Faults < Fault_Count_Type'Last then S.Faults := S.Faults + 1; end if;
      for I in Frame_Id loop
         if not S.Slots (I).Used then S.Slots (I) := (Value => P, Referenced => True, Used => True); return; end if;
      end loop;
      loop
         if S.Slots (S.Hand).Referenced then S.Slots (S.Hand).Referenced := False; Advance (S.Hand);
         else S.Slots (S.Hand) := (Value => P, Referenced => True, Used => True); Advance (S.Hand); exit; end if;
      end loop;
   end Access_Page;
   function Fault_Count (S : State) return Natural is begin return S.Faults; end Fault_Count;
end Clock_Page_Replacement;

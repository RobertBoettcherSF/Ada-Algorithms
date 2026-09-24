pragma SPARK_Mode (On);
package body Buddy_Memory_Allocation is
   function Is_Power_Of_Two (N : Block_Size) return Boolean is V : Natural := N;
   begin while V > 1 loop
         pragma Loop_Variant (Decreases => V);
         if V mod 2 /= 0 then return False; end if; V := V / 2; end loop; return True; end Is_Power_Of_Two;
   procedure Allocate (S : in out State; Size : Block_Size; B : out Block_Id) is Result : Block_Id := Block_Id'Last;
   begin
      for B in Block_Id loop
         if not S.Used (B) and then B <= Size then S.Used (B) := True; Result := B; exit; end if;
      end loop;
      B := Result;
   end Allocate;
   procedure Deallocate (S : in out State; B : Block_Id) is begin S.Used (B) := False; end Deallocate;
   function Is_Free (S : State; B : Block_Id) return Boolean is begin return not S.Used (B); end Is_Free;
end Buddy_Memory_Allocation;

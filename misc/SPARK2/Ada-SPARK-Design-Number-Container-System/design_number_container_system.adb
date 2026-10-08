pragma Ada_2022;
package body Design_Number_Container_System with SPARK_Mode => On is
   procedure Initialize (C : out Container) is begin C.Count := 0; for I in Index_Type loop C.Data (I) := 0; end loop; end Initialize;
   procedure Add (C : in out Container; Value : Integer) is begin if C.Count < Capacity then C.Count := C.Count + 1; C.Data (C.Count) := Value; end if; end Add;
   procedure Remove_Last (C : in out Container; Value : out Integer) is begin Value := 0; if C.Count > 0 then Value := C.Data (C.Count); C.Data (C.Count) := 0; C.Count := C.Count - 1; end if; end Remove_Last;
   function Contains (C : Container; Value : Integer) return Boolean is
   begin for I in 1 .. C.Count loop if C.Data (I) = Value then return True; end if; end loop; return False; end Contains;
   function Length (C : Container) return Count_Type is (C.Count);
end Design_Number_Container_System;

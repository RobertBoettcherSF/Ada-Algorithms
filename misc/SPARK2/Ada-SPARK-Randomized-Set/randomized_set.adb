pragma Ada_2022;
package body Randomized_Set with SPARK_Mode => On is
   procedure Initialize (S : out Set) is begin S.Count := 0; for I in Index_Type loop S.Data (I) := 0; end loop; end Initialize;
   procedure Insert (S : in out Set; Value : Integer) is begin if S.Count < Capacity and then not Contains (S, Value) then S.Count := S.Count + 1; S.Data (S.Count) := Value; end if; end Insert;
   procedure Remove_Last (S : in out Set; Value : out Integer) is begin Value := 0; if S.Count > 0 then Value := S.Data (S.Count); S.Data (S.Count) := 0; S.Count := S.Count - 1; end if; end Remove_Last;
   function Contains (S : Set; Value : Integer) return Boolean is begin for I in 1 .. S.Count loop if S.Data (I) = Value then return True; end if; end loop; return False; end Contains;
   function Length (S : Set) return Count_Type is (S.Count);
end Randomized_Set;

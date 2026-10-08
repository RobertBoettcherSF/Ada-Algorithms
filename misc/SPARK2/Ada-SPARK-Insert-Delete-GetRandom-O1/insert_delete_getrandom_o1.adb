pragma Ada_2022;
package body Insert_Delete_GetRandom_O1 with SPARK_Mode => On is
   procedure Initialize (S : out Set) is begin S.Count := 0; for I in Index_Type loop S.Data (I) := 0; end loop; end Initialize;
   procedure Insert (S : in out Set; Value : Integer) is begin if S.Count < Capacity then S.Count := S.Count + 1; S.Data (S.Count) := Value; end if; end Insert;
   procedure Delete_Last (S : in out Set; Value : out Integer) is begin Value := 0; if S.Count > 0 then Value := S.Data (S.Count); S.Data (S.Count) := 0; S.Count := S.Count - 1; end if; end Delete_Last;
   function Get_At (S : Set; Position : Positive) return Integer is (S.Data (Position)); function Length (S : Set) return Count_Type is (S.Count);
end Insert_Delete_GetRandom_O1;

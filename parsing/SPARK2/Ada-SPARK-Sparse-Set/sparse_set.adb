pragma Ada_2022;
package body Sparse_Set with SPARK_Mode => On is
   procedure Initialize (S : out Set) is
   begin for I in Position loop S.Dense (I) := 0; end loop; for V in Value loop S.Sparse (V) := 0; end loop; S.Count := 0; end Initialize;
   function Contains (S : Set; V : Value) return Boolean is begin return S.Count > 0 and then S.Sparse (V) < S.Count and then S.Dense (S.Sparse (V)) = V; end Contains;
   function Length (S : Set) return Natural is begin return S.Count; end Length;
   procedure Include (S : in out Set; V : Value) is begin if not Contains (S, V) and then S.Count < Capacity then S.Dense (S.Count) := V; S.Sparse (V) := S.Count; S.Count := S.Count + 1; end if; end Include;
   procedure Exclude (S : in out Set; V : Value) is P : Position; Last : Position; Moved : Value;
   begin if S.Count > 0 and then Contains (S, V) then P := S.Sparse (V); Last := S.Count - 1; Moved := S.Dense (Last); S.Dense (P) := Moved; S.Sparse (Moved) := P; S.Count := S.Count - 1; end if; end Exclude;
end Sparse_Set;

pragma Ada_2022;
package body Disjoint_Set_Forest with SPARK_Mode => On is
   procedure Initialize (F : out Forest) is begin for N in Node loop F.Parent (N) := N; F.Rank_Of (N) := 0; end loop; end Initialize;
   function Find (F : Forest; N : Node) return Node is Current : Node := N;
   begin for Step in Node loop if F.Parent (Current) = Current then return Current; end if; Current := F.Parent (Current); end loop; return Current; end Find;
   procedure Union (F : in out Forest; A, B : Node) is RA : constant Node := Find (F, A); RB : constant Node := Find (F, B);
   begin if RA /= RB then if F.Rank_Of (RA) < F.Rank_Of (RB) then F.Parent (RA) := RB; elsif F.Rank_Of (RB) < F.Rank_Of (RA) then F.Parent (RB) := RA; else F.Parent (RB) := RA; if F.Rank_Of (RA) < Nodes then F.Rank_Of (RA) := F.Rank_Of (RA) + 1; end if; end if; end if; end Union;
   function Same (F : Forest; A, B : Node) return Boolean is begin return Find (F, A) = Find (F, B); end Same;
end Disjoint_Set_Forest;

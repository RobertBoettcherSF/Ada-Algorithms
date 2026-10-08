pragma Ada_2022;
package body Union_Find with SPARK_Mode => On is
   procedure Initialize (S : out Set) is
   begin
      for N in Node loop S.Parent (N) := N; end loop;
   end Initialize;
   function Find (S : Set; N : Node) return Node is
      Current : Node := N;
   begin
      for Step in Node loop
         if S.Parent (Current) /= Current then
            Current := S.Parent (Current);
         end if;
      end loop;
      return Current;
   end Find;
   procedure Union (S : in out Set; A, B : Node) is
      RA : constant Node := Find (S, A);
      RB : constant Node := Find (S, B);
   begin
      if RA /= RB then S.Parent (RB) := RA; end if;
   end Union;
   function Same (S : Set; A, B : Node) return Boolean is
   begin
      return Find (S, A) = Find (S, B);
   end Same;
end Union_Find;

pragma SPARK_Mode (On);

package body Bump_Arena is

   function Create return Arena is
   begin
      return (Next => 0);
   end Create;

   procedure Reset (A : out Arena) is
   begin
      A := (Next => 0);
   end Reset;

   procedure Allocate_Node (A : in out Arena; Id : out Node_Id) is
   begin
      A.Next := A.Next + 1;
      Id := Node_Id (A.Next);
   end Allocate_Node;

   function Get_Mark (A : Arena) return Mark is
   begin
      return (Level => A.Next);
   end Get_Mark;

   procedure Release (A : in out Arena; M : Mark) is
   begin
      A.Next := M.Level;
   end Release;

end Bump_Arena;

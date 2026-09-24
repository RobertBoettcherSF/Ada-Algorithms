pragma SPARK_Mode (On);

--  Bounded bump / mark-release allocator using indices only.
--  No access types, no heap, no Root_Storage_Pool, no Unchecked_Deallocation.

package Bump_Arena is

   Capacity : constant Positive := 16;

   subtype Slot_Count is Natural range 0 .. Capacity;

   --  0 is the null / unused sentinel (never returned by Allocate_Node).
   subtype Node_Id is Natural range 0 .. Capacity;
   Null_Node : constant Node_Id := 0;
   subtype Valid_Id is Node_Id range 1 .. Capacity;

   type Arena is private;
   type Mark  is private;

   function Used (A : Arena) return Slot_Count
     with Global => null;

   function Remaining (A : Arena) return Slot_Count
     with Global => null,
          Post   => Remaining'Result = Capacity - Used (A);

   function Create return Arena
     with Global => null,
          Post   => Used (Create'Result) = 0;

   procedure Reset (A : out Arena)
     with Global => null,
          Post   => Used (A) = 0;

   procedure Allocate_Node (A : in out Arena; Id : out Node_Id)
     with Global => null,
          Pre    => Remaining (A) > 0,
          Post   => Id in Valid_Id
            and then Used (A) = Used (A'Old) + 1
            and then Id = Node_Id (Used (A));

   function Get_Mark (A : Arena) return Mark
     with Global => null;

   function Mark_Level (M : Mark) return Slot_Count
     with Global => null;

   --  LIFO release: drop everything allocated after M.
   procedure Release (A : in out Arena; M : Mark)
     with Global => null,
          Pre    => Mark_Level (M) <= Used (A),
          Post   => Used (A) = Mark_Level (M);

private

   type Arena is record
      Next : Slot_Count := 0;  --  count of live slots; next id = Next + 1
   end record;

   type Mark is record
      Level : Slot_Count := 0;
   end record;

   function Used (A : Arena) return Slot_Count is (A.Next);

   function Remaining (A : Arena) return Slot_Count is (Capacity - A.Next);

   function Mark_Level (M : Mark) return Slot_Count is (M.Level);

end Bump_Arena;

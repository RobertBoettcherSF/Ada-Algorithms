pragma SPARK_Mode (On);

--  Course schedule: can every course be taken when each prerequisite
--  pair (Course_Number, Required) says Required must come first? That is
--  possible exactly when the prerequisite graph has no cycle.
package Course_Schedule is
   Course_Count : constant := 4;
   subtype Course is Positive range 1 .. Course_Count;
   Prerequisite_Count : constant := 4;
   type Prerequisite is record
      Course_Number : Course;
      Required      : Course;
   end record;
   type Prerequisite_Array is array (Positive range 1 .. Prerequisite_Count) of Prerequisite;

   --  Default values: the empty set and rank 1 everywhere.
   type Course_Set is array (Course) of Boolean
   with Default_Component_Value => False;
   type Rank_Map is array (Course) of Course
   with Default_Component_Value => 1;

   --  Taking the courses in increasing Rank meets every prerequisite.
   function Is_Order (P : Prerequisite_Array; Rank : Rank_Map) return Boolean is
     (for all I in P'Range =>
        Rank (P (I).Required) < Rank (P (I).Course_Number));

   --  S is a nonempty set of courses each of which needs a course of S:
   --  no course of S can ever be the first of S to be taken.
   function Is_Stuck (P : Prerequisite_Array; S : Course_Set) return Boolean is
     ((for some C in Course => S (C))
      and then
        (for all C in Course =>
           (if S (C) then
              (for some I in P'Range =>
                 P (I).Course_Number = C and then S (P (I).Required)))));

   --  The two answers exclude each other, so Schedule's Ok is determined
   --  by the prerequisites alone.
   procedure Lemma_Exclusive
     (P : Prerequisite_Array; Rank : Rank_Map; S : Course_Set)
   with
     Ghost,
     Pre  => Is_Order (P, Rank),
     Post => not Is_Stuck (P, S);

   type Schedule_Result is record
      Ok    : Boolean;
      Rank  : Rank_Map;
      Stuck : Course_Set;
   end record;

   --  Kahn's algorithm: Ok with an order of the courses (Rank), or not Ok
   --  with a stuck set of courses (Stuck) as the witness.
   function Schedule (P : Prerequisite_Array) return Schedule_Result
   with
     Post => (if Schedule'Result.Ok then Is_Order (P, Schedule'Result.Rank)
              else Is_Stuck (P, Schedule'Result.Stuck));

   function Can_Finish (Prerequisites : Prerequisite_Array) return Boolean
   with
     Post => Can_Finish'Result = Schedule (Prerequisites).Ok;
end Course_Schedule;

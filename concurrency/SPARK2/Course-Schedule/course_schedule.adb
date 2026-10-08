pragma SPARK_Mode (On);

package body Course_Schedule is

   --  Number of members of S among courses 1 .. Upto.
   function Count (S : Course_Set; Upto : Natural) return Natural is
     (if Upto = 0 then 0
      else Count (S, Upto - 1) + (if S (Upto) then 1 else 0))
   with
     Ghost,
     Pre                => Upto <= Course_Count,
     Post               => Count'Result <= Upto,
     Subprogram_Variant => (Decreases => Upto);

   --  Adding one course to a set adds one to its count.
   procedure Lemma_Count_Add (A, B : Course_Set; X : Course)
   with
     Ghost,
     Pre  => not A (X) and then B (X)
       and then (for all C in Course => (if C /= X then B (C) = A (C))),
     Post => Count (B, Course_Count) = Count (A, Course_Count) + 1
   is
   begin
      for U in 1 .. Course_Count loop
         pragma Loop_Invariant
           (Count (B, U) = Count (A, U) + (if X <= U then 1 else 0));
      end loop;
   end Lemma_Count_Add;

   --  A set with every course has the full count.
   procedure Lemma_Count_Full (S : Course_Set)
   with
     Ghost,
     Pre  => (for all C in Course => S (C)),
     Post => Count (S, Course_Count) = Course_Count
   is
   begin
      for U in 1 .. Course_Count loop
         pragma Loop_Invariant (Count (S, U) = U);
      end loop;
   end Lemma_Count_Full;

   --  A set with less than the full count misses some course.
   procedure Lemma_Some_Left (S : Course_Set)
   with
     Ghost,
     Pre  => Count (S, Course_Count) < Course_Count,
     Post => (for some C in Course => not S (C))
   is
   begin
      if (for all C in Course => S (C)) then
         Lemma_Count_Full (S);
      end if;
   end Lemma_Some_Left;

   --  A set with the full count has every course.
   procedure Lemma_Count_All (S : Course_Set)
   with
     Ghost,
     Pre  => Count (S, Course_Count) = Course_Count,
     Post => (for all C in Course => S (C))
   is
   begin
      for U in 1 .. Course_Count loop
         pragma Loop_Invariant
           (if (for some D in 1 .. U => not S (D)) then Count (S, U) < U);
      end loop;
   end Lemma_Count_All;

   procedure Lemma_Exclusive
     (P : Prerequisite_Array; Rank : Rank_Map; S : Course_Set) is
   begin
      if Is_Stuck (P, S) then
         --  No member of S has rank R: its prerequisite in S would have a
         --  smaller rank, and every member of S has rank at least R.
         for R in Course loop
            pragma Loop_Invariant
              (for all C in Course => (if S (C) then Rank (C) >= R));
            pragma Assert
              (for all C in Course => (if S (C) then Rank (C) /= R));
         end loop;
         pragma Assert (for all C in Course => not S (C));
      end if;
   end Lemma_Exclusive;

   --  Every prerequisite of C is in Done.
   function Is_Ready
     (P : Prerequisite_Array; Done : Course_Set; C : Course) return Boolean
   is (for all I in P'Range =>
         (if P (I).Course_Number = C then Done (P (I).Required)));

   function Schedule (P : Prerequisite_Array) return Schedule_Result is
      Rank  : Rank_Map;     --  rank 1 everywhere
      Stuck : Course_Set;   --  empty
      Done  : Course_Set;   --  empty
      Pick  : Course;
      Found : Boolean;
   begin
      for Step in Course loop
         pragma Loop_Invariant (Count (Done, Course_Count) = Step - 1);
         pragma Loop_Invariant
           (for all C in Course => (if Done (C) then Rank (C) < Step));
         pragma Loop_Invariant
           (for all I in P'Range =>
              (if Done (P (I).Course_Number) then
                 Done (P (I).Required)
                 and then Rank (P (I).Required) < Rank (P (I).Course_Number)));

         --  Look for a course not taken yet whose prerequisites are taken.
         Found := False;
         Pick := 1;
         for C in Course loop
            if not Done (C) and then Is_Ready (P, Done, C) then
               Found := True;
               Pick := C;
               exit;
            end if;
            pragma Loop_Invariant (not Found);
            pragma Loop_Invariant
              (for all D in 1 .. C => Done (D) or else not Is_Ready (P, Done, D));
         end loop;

         if not Found then
            --  Some course is left (Step - 1 < Course_Count are taken), and
            --  every course left needs another course left.
            pragma Assert
              (for all C in Course => Done (C) or else not Is_Ready (P, Done, C));
            Lemma_Some_Left (Done);
            Stuck := not Done;
            pragma Assert (for all C in Course => Stuck (C) = not Done (C));
            return (Ok => False, Rank => Rank, Stuck => Stuck);
         end if;

         declare
            Before : constant Course_Set := Done with Ghost;
         begin
            Done (Pick) := True;
            Rank (Pick) := Step;
            Lemma_Count_Add (Before, Done, Pick);
         end;
      end loop;

      Lemma_Count_All (Done);
      return (Ok => True, Rank => Rank, Stuck => Stuck);
   end Schedule;

   function Can_Finish (Prerequisites : Prerequisite_Array) return Boolean is
     (Schedule (Prerequisites).Ok);
end Course_Schedule;

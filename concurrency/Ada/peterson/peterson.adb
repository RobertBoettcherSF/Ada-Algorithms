with Ada.Text_IO; use Ada.Text_IO;

procedure Peterson is

   --  ====================================================================
   --  Variant 1: Strict Alternation
   --  Requires strict turn-taking. If one process stops, the other starves.
   --  ====================================================================
   procedure Strict_Alternation is
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);

      task type Worker_Strict is
         entry Start (ID : Integer);
      end Worker_Strict;

      task body Worker_Strict is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;

         for I in 1 .. 3 loop
            --  Wait for our turn
            while Turn /= My_ID loop
               delay 0.0; -- Yield to prevent hard spinlock starvation
            end loop;

            --  Critical Section
            Put_Line ("Strict Alternation : Task " & My_ID'Image & " in Critical Section.");

            --  Pass the turn
            Turn := Other;
         end loop;
      end Worker_Strict;

      Tasks : array (0 .. 1) of Worker_Strict;
   begin
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
   end Strict_Alternation;

   --  ====================================================================
   --  Variant 2: Standard 2-Process Peterson's Algorithm
   --  Uses both a 'Flag' to indicate intent and a 'Turn' for tie-breaking.
   --  ====================================================================
   procedure Peterson_2_Process is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);

      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);

      task type Worker_2 is
         entry Start (ID : Integer);
      end Worker_2;

      task body Worker_2 is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;

         for I in 1 .. 3 loop
            --  State intent to enter critical section
            Flag (My_ID) := True;
            
            --  Grant priority to the other process if they also want in
            Turn := Other;

            --  Wait until the other process doesn't want in, or it's our turn
            while Flag (Other) and then Turn = Other loop
               delay 0.0;
            end loop;

            --  Critical Section
            Put_Line ("Peterson 2-Proc    : Task " & My_ID'Image & " in Critical Section.");

            --  Leave critical section
            Flag (My_ID) := False;
         end loop;
      end Worker_2;

      Tasks : array (0 .. 1) of Worker_2;
   begin
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
   end Peterson_2_Process;

   --  ====================================================================
   --  Variant 3: N-Process Peterson's Algorithm (Filter Lock)
   --  Generalizes the tie-breaking to N levels.
   --  ====================================================================
   procedure Peterson_N_Process is
      N : constant := 4; -- Demonstrating with 4 processes

      --  Level indicates the current "waiting room" stage a process is in.
      Level : array (0 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Level);

      --  Records the last process to enter a specific level.
      Last_To_Enter : array (1 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Last_To_Enter);

      task type Worker_N is
         entry Start (ID : Integer);
      end Worker_N;

      task body Worker_N is
         My_ID    : Integer;
         Conflict : Boolean;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;

         for I in 1 .. 3 loop
            --  Filter lock entry: Must pass through N-1 levels
            for L in 1 .. N - 1 loop
               Level (My_ID) := L;
               Last_To_Enter (L) := My_ID;

               loop
                  Conflict := False;
                  --  Check if any other process is at the same or a higher level
                  for K in 0 .. N - 1 loop
                     if K /= My_ID and then Level (K) >= L then
                        Conflict := True;
                        exit;
                     end if;
                  end loop;

                  --  We can proceed to the next level IF no one else is ahead of us,
                  --  OR we are no longer the last one to enter this level.
                  exit when not (Conflict and then Last_To_Enter (L) = My_ID);
                  delay 0.0;
               end loop;
            end loop;

            --  Critical Section
            Put_Line ("Peterson N-Proc    : Task " & My_ID'Image & " in Critical Section.");

            --  Leave critical section
            Level (My_ID) := 0;
         end loop;
      end Worker_N;

      Tasks : array (0 .. N - 1) of Worker_N;
   begin
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
   end Peterson_N_Process;

begin
   --  Ada task scoping rules ensure that the main task will implicitly 
   --  wait at the end of each procedure for all child tasks to finish 
   --  before returning. This sequences the three demonstrations perfectly.

   Put_Line ("--- Starting Strict Alternation Demo ---");
   Strict_Alternation;
   Put_Line ("");

   Put_Line ("--- Starting 2-Process Peterson Demo ---");
   Peterson_2_Process;
   Put_Line ("");

   Put_Line ("--- Starting N-Process Peterson (Filter Algorithm) Demo ---");
   Peterson_N_Process;
   Put_Line ("");

   Put_Line ("All demonstrations completed safely.");
end Peterson;

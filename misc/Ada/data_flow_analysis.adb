package body Data_Flow_Analysis is

   -- -------------------------------------------------------------------------
   -- Helper Functions
   -- -------------------------------------------------------------------------

   function Has_Predecessors (CFG : Control_Flow_Graph; N : Node_ID) return Boolean is
   begin
      for P in 1 .. CFG.Nodes loop
         if CFG.Edges (P, N) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Predecessors;

   function Has_Successors (CFG : Control_Flow_Graph; N : Node_ID) return Boolean is
   begin
      for S in 1 .. CFG.Nodes loop
         if CFG.Edges (N, S) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Successors;

   -- -------------------------------------------------------------------------
   -- Graph Construction & Validation API
   -- -------------------------------------------------------------------------

   procedure Add_Edge (CFG : in out Control_Flow_Graph; From, To : Node_ID) is
   begin
      CFG.Edges (From, To) := True;
   end Add_Edge;

   procedure Add_Gen (CFG : in out Control_Flow_Graph; Node : Node_ID; Fact : Fact_ID) is
   begin
      CFG.Gen (Node, Fact) := True;
   end Add_Gen;

   procedure Add_Kill (CFG : in out Control_Flow_Graph; Node : Node_ID; Fact : Fact_ID) is
   begin
      CFG.Kill (Node, Fact) := True;
   end Add_Kill;

   procedure Validate_Graph (CFG : Control_Flow_Graph) is
   begin
      for N in 1 .. CFG.Nodes loop
         for F in 1 .. CFG.Facts loop
            if CFG.Gen (N, F) and CFG.Kill (N, F) then
               raise Graph_Conflict_Error;
            end if;
         end loop;
      end loop;
   end Validate_Graph;

   -- -------------------------------------------------------------------------
   -- 1. Reaching Definitions (Forward, May)
   -- -------------------------------------------------------------------------
   procedure Solve_Reaching_Definitions
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
   is
      Changed   : Boolean := True;
      Temp_Bool : Boolean;
      Old_Val   : Boolean;
   begin
      -- Initialization: In = Empty, Out = Gen
      for N in 1 .. CFG.Nodes loop
         for F in 1 .. CFG.Facts loop
            In_Sets (N, F)  := False;
            Out_Sets (N, F) := CFG.Gen (N, F);
         end loop;
      end loop;

      -- Iterate until convergence
      while Changed loop
         Changed := False;
         for N in 1 .. CFG.Nodes loop
            -- Forward analysis: In(N) = Union of Out(P)
            for F in 1 .. CFG.Facts loop
               Temp_Bool := False;
               for P in 1 .. CFG.Nodes loop
                  if CFG.Edges (P, N) then
                     Temp_Bool := Temp_Bool or Out_Sets (P, F);
                  end if;
               end loop;
               In_Sets (N, F) := Temp_Bool;
            end loop;

            -- Out(N) = Gen(N) U (In(N) - Kill(N))
            for F in 1 .. CFG.Facts loop
               Old_Val := Out_Sets (N, F);
               Out_Sets (N, F) := CFG.Gen (N, F) or (In_Sets (N, F) and not CFG.Kill (N, F));
               if Old_Val /= Out_Sets (N, F) then
                  Changed := True;
               end if;
            end loop;
         end loop;
      end loop;
   end Solve_Reaching_Definitions;

   -- -------------------------------------------------------------------------
   -- 2. Live Variables (Backward, May)
   -- -------------------------------------------------------------------------
   procedure Solve_Live_Variables
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
   is
      Changed   : Boolean := True;
      Temp_Bool : Boolean;
      Old_Val   : Boolean;
   begin
      -- Initialization: Out = Empty, In = Gen
      for N in 1 .. CFG.Nodes loop
         for F in 1 .. CFG.Facts loop
            Out_Sets (N, F) := False;
            In_Sets (N, F)  := CFG.Gen (N, F);
         end loop;
      end loop;

      -- Iterate until convergence
      while Changed loop
         Changed := False;
         for N in reverse 1 .. CFG.Nodes loop
            -- Backward analysis: Out(N) = Union of In(S)
            for F in 1 .. CFG.Facts loop
               Temp_Bool := False;
               for S in 1 .. CFG.Nodes loop
                  if CFG.Edges (N, S) then
                     Temp_Bool := Temp_Bool or In_Sets (S, F);
                  end if;
               end loop;
               Out_Sets (N, F) := Temp_Bool;
            end loop;

            -- In(N) = Gen(N) U (Out(N) - Kill(N))
            for F in 1 .. CFG.Facts loop
               Old_Val := In_Sets (N, F);
               In_Sets (N, F) := CFG.Gen (N, F) or (Out_Sets (N, F) and not CFG.Kill (N, F));
               if Old_Val /= In_Sets (N, F) then
                  Changed := True;
               end if;
            end loop;
         end loop;
      end loop;
   end Solve_Live_Variables;

   -- -------------------------------------------------------------------------
   -- 3. Available Expressions (Forward, Must)
   -- -------------------------------------------------------------------------
   procedure Solve_Available_Expressions
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
   is
      Changed   : Boolean := True;
      Temp_Bool : Boolean;
      Old_Val   : Boolean;
   begin
      -- Initialization: Set all to True (Universal set)
      for N in 1 .. CFG.Nodes loop
         for F in 1 .. CFG.Facts loop
            In_Sets (N, F)  := True;
            Out_Sets (N, F) := True;
         end loop;

         -- Entry nodes initialize with empty In_Sets
         if not Has_Predecessors (CFG, N) then
            for F in 1 .. CFG.Facts loop
               In_Sets (N, F)  := False;
               Out_Sets (N, F) := CFG.Gen (N, F);
            end loop;
         end if;
      end loop;

      -- Iterate until convergence
      while Changed loop
         Changed := False;
         for N in 1 .. CFG.Nodes loop
            if Has_Predecessors (CFG, N) then
               -- Forward Must: In(N) = Intersection of Out(P)
               for F in 1 .. CFG.Facts loop
                  Temp_Bool := True;
                  for P in 1 .. CFG.Nodes loop
                     if CFG.Edges (P, N) then
                        Temp_Bool := Temp_Bool and Out_Sets (P, F);
                     end if;
                  end loop;
                  In_Sets (N, F) := Temp_Bool;
               end loop;
            end if;

            -- Out(N) = Gen(N) U (In(N) - Kill(N))
            for F in 1 .. CFG.Facts loop
               Old_Val := Out_Sets (N, F);
               Out_Sets (N, F) := CFG.Gen (N, F) or (In_Sets (N, F) and not CFG.Kill (N, F));
               if Old_Val /= Out_Sets (N, F) then
                  Changed := True;
               end if;
            end loop;
         end loop;
      end loop;
   end Solve_Available_Expressions;

   -- -------------------------------------------------------------------------
   -- 4. Very Busy Expressions (Backward, Must)
   -- -------------------------------------------------------------------------
   procedure Solve_Very_Busy_Expressions
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
   is
      Changed   : Boolean := True;
      Temp_Bool : Boolean;
      Old_Val   : Boolean;
   begin
      -- Initialization: Set all to True (Universal set)
      for N in 1 .. CFG.Nodes loop
         for F in 1 .. CFG.Facts loop
            In_Sets (N, F)  := True;
            Out_Sets (N, F) := True;
         end loop;

         -- Exit nodes initialize with empty Out_Sets
         if not Has_Successors (CFG, N) then
            for F in 1 .. CFG.Facts loop
               Out_Sets (N, F) := False;
               In_Sets (N, F)  := CFG.Gen (N, F);
            end loop;
         end if;
      end loop;

      -- Iterate until convergence
      while Changed loop
         Changed := False;
         for N in reverse 1 .. CFG.Nodes loop
            if Has_Successors (CFG, N) then
               -- Backward Must: Out(N) = Intersection of In(S)
               for F in 1 .. CFG.Facts loop
                  Temp_Bool := True;
                  for S in 1 .. CFG.Nodes loop
                     if CFG.Edges (N, S) then
                        Temp_Bool := Temp_Bool and In_Sets (S, F);
                     end if;
                  end loop;
                  Out_Sets (N, F) := Temp_Bool;
               end loop;
            end if;

            -- In(N) = Gen(N) U (Out(N) - Kill(N))
            for F in 1 .. CFG.Facts loop
               Old_Val := In_Sets (N, F);
               In_Sets (N, F) := CFG.Gen (N, F) or (Out_Sets (N, F) and not CFG.Kill (N, F));
               if Old_Val /= In_Sets (N, F) then
                  Changed := True;
               end if;
            end loop;
         end loop;
      end loop;
   end Solve_Very_Busy_Expressions;

end Data_Flow_Analysis;

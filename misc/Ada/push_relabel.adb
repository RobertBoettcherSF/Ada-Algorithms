-- push_relabel.adb
-- Package body with full implementations of all variants and shared helpers.

package body Push_Relabel is

   -- Internal state types
   type Flow_Matrix is array (Node_Id range <>, Node_Id range <>) of Integer;
   type Height_Array is array (Node_Id range <>) of Natural;
   type Excess_Array is array (Node_Id range <>) of Integer;

   -- HELPER: Validates graph constraints before running algorithm
   procedure Validate_Input (C : Adjacency_Matrix; Source, Sink : Node_Id) is
   begin
      if C'Length(1) = 0 or C'Length(2) = 0 then
         raise Empty_Graph_Error with "Graph contains no nodes.";
      end if;
      if C'Length(1) /= C'Length(2) then
         raise Invalid_Node_Error with "Adjacency matrix must be square.";
      end if;
      if Source not in C'Range(1) or Sink not in C'Range(1) then
         raise Source_Sink_Error with "Source or Sink out of matrix bounds.";
      end if;
      if Source = Sink then
         raise Source_Sink_Error with "Source and Sink cannot be the same node.";
      end if;
   end Validate_Input;

   -- HELPER: Initializes the preflow, heights, and excesses
   procedure Init_Preflow (
      C      : Adjacency_Matrix;
      Source : Node_Id;
      F      : out Flow_Matrix;
      H      : out Height_Array;
      E      : out Excess_Array
   ) is
      N : constant Natural := C'Length(1);
   begin
      F := (others => (others => 0));
      H := (others => 0);
      E := (others => 0);
      
      H(Source) := N; -- Source height is exactly |V|
      
      -- Saturate all outgoing edges from the source
      for V in C'Range(1) loop
         if (V /= Source) and then (C(Source, V) > 0) then
            declare
               Cap : constant Integer := Integer(C(Source, V));
            begin
               F(Source, V) := Cap;
               F(V, Source) := -Cap; -- Skew symmetry
               E(V) := Cap;
               E(Source) := E(Source) - Cap;
            end;
         end if;
      end loop;
   end Init_Preflow;

   -- HELPER: Pushes flow from U to V
   procedure Push (
      C : Adjacency_Matrix;
      F : in out Flow_Matrix;
      E : in out Excess_Array;
      U, V : Node_Id
   ) is
      Cf : constant Integer := Integer(C(U, V)) - F(U, V);
      Push_Amount : Integer;
   begin
      if E(U) < Cf then
         Push_Amount := E(U);
      else
         Push_Amount := Cf;
      end if;
      
      F(U, V) := F(U, V) + Push_Amount;
      F(V, U) := F(V, U) - Push_Amount; -- Maintain skew symmetry
      E(U) := E(U) - Push_Amount;
      E(V) := E(V) + Push_Amount;
   end Push;

   -- HELPER: Relabels node U to create a new valid gradient for pushing
   procedure Relabel (
      C : Adjacency_Matrix;
      F : Flow_Matrix;
      H : in out Height_Array;
      U : Node_Id
   ) is
      Min_H : Natural := Natural'Last;
      Cf    : Integer;
   begin
      for V in C'Range(1) loop
         Cf := Integer(C(U, V)) - F(U, V);
         if Cf > 0 then
            if H(V) < Min_H then
               Min_H := H(V);
            end if;
         end if;
      end loop;
      
      if Min_H /= Natural'Last then
         H(U) := Min_H + 1;
      end if;
   end Relabel;


   -----------------------------------------------------
   -- VARIANT 1: Generic Push-Relabel
   -----------------------------------------------------
   function Generic_Max_Flow (Graph : Adjacency_Matrix; Source, Sink : Node_Id) return Flow_Type is
      F : Flow_Matrix(Graph'Range(1), Graph'Range(1));
      H : Height_Array(Graph'Range(1));
      E : Excess_Array(Graph'Range(1));
      Active_Found : Boolean;
   begin
      Validate_Input(Graph, Source, Sink);
      Init_Preflow(Graph, Source, F, H, E);

      loop
         Active_Found := False;
         for U in Graph'Range(1) loop
            if (U /= Source) and then (U /= Sink) and then (E(U) > 0) then
               Active_Found := True;
               
               declare
                  Pushed : Boolean := False;
               begin
                  for V in Graph'Range(1) loop
                     if (Integer(Graph(U, V)) - F(U, V) > 0) and then (H(U) = H(V) + 1) then
                        Push(Graph, F, E, U, V);
                        Pushed := True;
                        exit; 
                     end if;
                  end loop;
                  
                  if not Pushed then
                     Relabel(Graph, F, H, U);
                  end if;
               end;
               exit; -- Break loop to search for next active node
            end if;
         end loop;
         exit when not Active_Found;
      end loop;
      
      return Flow_Type(E(Sink));
   end Generic_Max_Flow;


   -----------------------------------------------------
   -- VARIANT 2: FIFO Push-Relabel
   -----------------------------------------------------
   function FIFO_Max_Flow (Graph : Adjacency_Matrix; Source, Sink : Node_Id) return Flow_Type is
      F : Flow_Matrix(Graph'Range(1), Graph'Range(1));
      H : Height_Array(Graph'Range(1));
      E : Excess_Array(Graph'Range(1));
      
      -- Circular Queue implementation for active nodes
      Max_Q : constant Positive := Graph'Length(1) + 1;
      Q : array (1 .. Max_Q) of Node_Id;
      Head, Tail : Positive := 1;
      Count : Natural := 0;
      In_Queue : array (Graph'Range(1)) of Boolean := (others => False);

      procedure Enqueue (V : Node_Id) is
      begin
         if not In_Queue(V) then
            Q(Tail) := V;
            Tail := (Tail mod Max_Q) + 1;
            Count := Count + 1;
            In_Queue(V) := True;
         end if;
      end Enqueue;

      procedure Dequeue (V : out Node_Id) is
      begin
         V := Q(Head);
         Head := (Head mod Max_Q) + 1;
         Count := Count - 1;
         In_Queue(V) := False;
      end Dequeue;
      
      U : Node_Id;
   begin
      Validate_Input(Graph, Source, Sink);
      Init_Preflow(Graph, Source, F, H, E);

      -- Initial enqueue
      for V in Graph'Range(1) loop
         if (V /= Source) and then (V /= Sink) and then (E(V) > 0) then
            Enqueue(V);
         end if;
      end loop;

      while Count > 0 loop
         Dequeue(U);
         -- Discharge U completely
         while E(U) > 0 loop
            declare
               Pushed : Boolean := False;
            begin
               for V in Graph'Range(1) loop
                  if (Integer(Graph(U, V)) - F(U, V) > 0) and then (H(U) = H(V) + 1) then
                     Push(Graph, F, E, U, V);
                     Pushed := True;
                     if (V /= Source) and then (V /= Sink) and then (E(V) > 0) then
                        Enqueue(V);
                     end if;
                     exit; 
                  end if;
               end loop;
               
               if not Pushed then
                  Relabel(Graph, F, H, U);
               end if;
            end;
         end loop;
      end loop;

      return Flow_Type(E(Sink));
   end FIFO_Max_Flow;


   -----------------------------------------------------
   -- VARIANT 3: Highest-Label Push-Relabel
   -----------------------------------------------------
   function Highest_Label_Max_Flow (Graph : Adjacency_Matrix; Source, Sink : Node_Id) return Flow_Type is
      F : Flow_Matrix(Graph'Range(1), Graph'Range(1));
      H : Height_Array(Graph'Range(1));
      E : Excess_Array(Graph'Range(1));
      
      Highest_H : Integer;
      Best_U    : Node_Id;
   begin
      Validate_Input(Graph, Source, Sink);
      Init_Preflow(Graph, Source, F, H, E);

      loop
         Highest_H := -1;
         Best_U := Source; -- Safely initialize to suppress warnings
         
         -- Find active node with maximum height
         for U in Graph'Range(1) loop
            if (U /= Source) and then (U /= Sink) and then (E(U) > 0) then
               if Integer(H(U)) > Highest_H then
                  Highest_H := Integer(H(U));
                  Best_U := U;
               end if;
            end if;
         end loop;

         exit when Highest_H = -1;

         declare
            U : constant Node_Id := Best_U;
            Pushed : Boolean := False;
         begin
            for V in Graph'Range(1) loop
               if (Integer(Graph(U, V)) - F(U, V) > 0) and then (H(U) = H(V) + 1) then
                  Push(Graph, F, E, U, V);
                  Pushed := True;
                  exit;
               end if;
            end loop;
            
            if not Pushed then
               Relabel(Graph, F, H, U);
            end if;
         end;
      end loop;

      return Flow_Type(E(Sink));
   end Highest_Label_Max_Flow;

end Push_Relabel;
